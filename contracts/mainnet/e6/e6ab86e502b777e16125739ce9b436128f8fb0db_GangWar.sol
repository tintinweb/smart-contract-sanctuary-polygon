// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GangVault} from "./GangVault.sol";
import {GangToken} from "./tokens/GangToken.sol";
import {LibPackedMap} from "./lib/LibPackedMap.sol";
import {VRFConsumerV2} from "./lib/VRFConsumerV2.sol";
import {GMCChild as GMC, Offer} from "./tokens/GMCChild.sol";

import {ERC20UDS} from "UDS/tokens/ERC20UDS.sol";
import {ERC721UDS} from "UDS/tokens/ERC721UDS.sol";
import {OwnableUDS} from "UDS/auth/OwnableUDS.sol";
import {UUPSUpgrade} from "UDS/proxy/UUPSUpgrade.sol";

// ------------- constants

uint256 constant TIME_TRUCE = 4 hours;
uint256 constant TIME_LOCKUP = 12 hours;
uint256 constant TIME_GANG_WAR = 3 hours;
uint256 constant TIME_RECOVERY = 12 hours;
uint256 constant TIME_REINFORCEMENTS = 5 hours;

uint256 constant DEFENSE_FAVOR_LIM = 60; // 150
uint256 constant BARON_DEFENSE_FORCE = 10;
uint256 constant ATTACK_FAVOR = 65;
uint256 constant DEFENSE_FAVOR = 200;

uint256 constant LOCKUP_CHANCE = 15;
uint256 constant LOCKUP_FINE = 25_000e18;
uint256 constant RECOVERY_BARON_COST = 25_000e18;

uint256 constant INJURED_WON_FACTOR = 35;
uint256 constant INJURED_LOST_FACTOR = 65;

uint256 constant GANG_VAULT_FEE = 20;

uint256 constant BADGES_EARNED_VICTORY = 6e18;
uint256 constant BADGES_EARNED_DEFEAT = 2e18;

uint256 constant UPKEEP_INTERVAL = 1 minutes;

uint256 constant NUM_BARON_ITEMS = 5;
uint256 constant ITEM_SEWER = 0;
uint256 constant ITEM_BLITZ = 1;
uint256 constant ITEM_BARRICADES = 2;
uint256 constant ITEM_SMOKE = 3;
uint256 constant ITEM_911 = 4;

uint256 constant REQUEST_SLOT_ITEM_911 = 40;
uint256 constant REQUEST_SLOT_VRF = 255;

uint256 constant ITEM_BLITZ_TIME_REDUCTION = 80;
uint256 constant ITEM_SMOKE_ATTACK_INCREASE = 30;
uint256 constant ITEM_BARRICADES_DEFENSE_INCREASE = 30;
uint256 constant ITEM_TIME_DELAY_USE = 0 hours;
uint256 constant ITEM_TIME_DELAY_PURCHASE = 0 hours;
uint256 constant COPS_LOCKUP_MINIMUM_INTERVAL = 20 minutes;

// ------------- enum

enum Gang {
    YAKUZA,
    CARTEL,
    CYBERP,
    NONE
}

enum DISTRICT_STATE {
    IDLE,
    REINFORCEMENT,
    GANG_WAR,
    POST_GANG_WAR,
    TRUCE,
    LOCKUP
}

enum PLAYER_STATE {
    IDLE,
    ATTACK,
    ATTACK_LOCKED,
    DEFEND,
    DEFEND_LOCKED,
    INJURED,
    LOCKUP
}

// ------------- struct

struct Gangster {
    uint256 roundId;
    uint256 location;
    uint256 briberyTimeReduction;
    uint256 recoveryTimeReduction;
    bool attack;
    // variables from here on are not explicitly set
    // but only written to in the view functions for getters
    // don't read these directly in the contract!
    Gang gang;
    PLAYER_STATE state;
    int256 stateCountdown;
}

struct District {
    Gang occupants;
    Gang attackers;
    Gang token;
    uint256 roundId;
    uint256 attackDeclarationTime;
    uint256 baronAttackId;
    uint256 baronDefenseId;
    uint256 lastUpkeepTime; // UNUSED; time when upkeep is last triggered
    uint256 lastOutcomeTime; // time when vrf result is in
    uint256 lockupTime;
    uint256 yield;
    uint256 activeItems;
    uint256 blitzTimeReduction;
    // variables from here on are not explicitly set
    // but only written to in the view functions for getters
    // don't read these directly in the contract!
    DISTRICT_STATE state;
    int256 stateCountdown;
    uint256 attackForces;
    uint256 defenseForces;
}

struct GangWarDS {
    uint40 seasonStart;
    uint40 seasonEnd;
    /*      id      =>   */
    mapping(uint256 => District) districts;
    mapping(uint256 => Gangster) gangsters;
    /*      id      => price  */
    mapping(uint256 => uint256) baronItemCost;
    /*      address => fee  */
    mapping(address => uint256) briberyFee;
    /*      Gang =>        itemId   => balance  */
    mapping(Gang => mapping(uint256 => uint256)) baronItems;
    /*   districtId => districtIds  */
    mapping(uint256 => uint256) unused_requestIdToDistrictIds; // UNUSED; placeholder
    /*   districtId =>     roundId     => outcome  */
    mapping(uint256 => mapping(uint256 => uint256)) gangWarOutcomes;
    /*   districtId =>     roundId     => numForces */
    mapping(uint256 => mapping(uint256 => uint256)) districtAttackForces;
    mapping(uint256 => mapping(uint256 => uint256)) districtDefenseForces;
    mapping(uint256 => uint256) baronItemLastPurchased;
    mapping(uint256 => uint256) baronItemLastUsed;
    uint40 lastGlobalLockupTime;
    uint256 latestRequests;
}

// ------------- storage

string constant SEASON = "season.2";

bytes32 constant DIAMOND_STORAGE_GANG_WAR = keccak256("diamond.storage.gang.war.season.2");

function s() pure returns (GangWarDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_GANG_WAR;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

// ------------- errors

error InvalidToken();
error NotAuthorized();
error InvalidItemId();
error InvalidItemUsage();
error GangWarNotActive();
error TokenMustBeBaron();
error InvalidVRFRequest();
error ItemAlreadyActive();
error AlreadyInDistrict();
error BaronInactionable();
error TokenMustBeGangster();
error IdsMustBeOfSameGang();
error GangsterInactionable();
error DistrictInvalidState();
error GangsterInvalidState();
error BaronAlreadyDefending();
error DistrictNotOwnedByGang();
error MinimumTimeDelayNotPassed();
error InvalidConnectingDistrict();
error BaronMustDeclareInitialAttack();
error ConnectingDistrictUnderAttack();
error CannotAttackDistrictOwnedByGang();
error ConnectingDistrictNotOwnedByGang();

/// @title Gangsta Mice City's Gang Wars
/// @author phaze (https://github.com/0xPhaze)
contract GangWar is UUPSUpgrade, OwnableUDS, VRFConsumerV2 {
    GangWarDS private __storageLayout;

    event CopsLockup(uint256 indexed districtId, Gang occupants, Gang attackers);
    event GangWarWon(uint256 indexed districtId, Gang indexed losers, Gang indexed winners);
    event ExitGangWar(uint256 indexed districtId, Gang indexed gang, uint256 tokenId);
    event EnterGangWar(uint256 indexed districtId, Gang indexed gang, uint256 tokenId);
    event BadgesEarned(uint256 indexed districtId, uint256 indexed tokenId, Gang indexed gang, bool won, uint256 probability); // prettier-ignore
    event BaronItemUsed(uint256 indexed districtId, uint256 indexed baronId, Gang indexed gang, uint256 itemId);
    event GangsterInjured(uint256 indexed districtId, uint256 indexed tokenId);
    event BaronItemPurchased(uint256 indexed baronId, Gang indexed gang, uint256 itemId, uint256 price);
    event BaronAttackDeclared(uint256 indexed connectingId, uint256 indexed districtId, Gang indexed gang, uint256 tokenId); // prettier-ignore
    event BaronDefenseDeclared(uint256 indexed districtId, Gang indexed gang, uint256 tokenId);

    GMC public immutable gmc;
    GangToken public immutable badges;
    GangVault public immutable vault;

    uint256 immutable packedDistrictConnections;

    constructor(
        GMC gmc_,
        GangVault vault_,
        GangToken badges_,
        uint256 connections,
        address coordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit
    ) VRFConsumerV2(coordinator, keyHash, subscriptionId, requestConfirmations, callbackGasLimit) {
        gmc = gmc_;
        vault = vault_;
        badges = badges_;
        packedDistrictConnections = connections;
    }

    /* ------------- init ------------- */

    function init() external initializer {
        __Ownable_init();
    }

    function reset(Gang[21] calldata occupants, uint256[21] calldata yields) public onlyOwner {
        uint256[3] memory initialGangYields;

        District storage district;

        for (uint256 i; i < 21; ++i) {
            district = s().districts[i];

            // initialize rounds
            district.roundId = 1;

            // initialize occupants and yield token
            district.token = occupants[i];
            district.occupants = occupants[i];

            // initialize district yield amount
            district.yield = yields[i];

            initialGangYields[uint256(occupants[i])] += yields[i];
        }

        // initialize yields for gangs
        vault.setYield(0, [initialGangYields[0], uint256(0), uint256(0)]);
        vault.setYield(1, [uint256(0), initialGangYields[1], uint256(0)]);
        vault.setYield(2, [uint256(0), uint256(0), initialGangYields[2]]);
    }

    /* ------------- view ------------- */

    function seasonStart() external view returns (uint256) {
        return s().seasonStart;
    }

    function seasonEnd() external view returns (uint256) {
        return s().seasonEnd;
    }

    function gangAttackSuccess(uint256 districtId, uint256 roundId) public view returns (bool) {
        uint256 gRand = s().gangWarOutcomes[districtId][roundId];

        uint256 p = gangWarWinProbability(districtId, roundId);

        return gRand >> 128 < p;
    }

    function briberyFee(address token) external view returns (uint256) {
        return s().briberyFee[token];
    }

    function baronItemCost(uint256 id) external view returns (uint256) {
        return s().baronItemCost[id];
    }

    function getBaronItemBalances(uint256 gang) external view returns (uint256[] memory items) {
        items = new uint256[](NUM_BARON_ITEMS);
        for (uint256 i; i < NUM_BARON_ITEMS; ++i) items[i] = s().baronItems[Gang(gang)][i];
    }

    function getGangster(uint256 tokenId) external view returns (Gangster memory gangster) {
        gangster = s().gangsters[tokenId];

        gangster.gang = gangOf(tokenId);

        (gangster.state, gangster.stateCountdown) = _gangsterStateAndCountdown(tokenId);
    }

    function getDistrict(uint256 districtId) external view returns (District memory district) {
        District storage sDistrict = s().districts[districtId];

        district = sDistrict;

        (district.state, district.stateCountdown) = _districtStateAndCountdown(sDistrict);

        district.attackForces = s().districtAttackForces[districtId][district.roundId];
        district.defenseForces = s().districtDefenseForces[districtId][district.roundId];
    }

    /* ------------- external ------------- */

    function purchaseBaronItem(
        uint256 baronId,
        uint256 itemId,
        uint256 exchangeType
    ) external isActiveSeason {
        _verifyAuthorizedUser(msg.sender, baronId);

        uint256 micePrice = s().baronItemCost[itemId];
        uint256 lastPurchase = s().baronItemLastPurchased[baronId];

        if (micePrice == 0) revert InvalidItemId();
        if (!isBaron(baronId)) revert TokenMustBeBaron();
        if (block.timestamp < lastPurchase + ITEM_TIME_DELAY_PURCHASE) revert MinimumTimeDelayNotPassed();

        Gang gang = gangOf(baronId);

        _spendMice(uint256(gang), micePrice, exchangeType);

        emit BaronItemPurchased(baronId, gang, itemId, micePrice);

        s().baronItems[gang][itemId] += 1;
        s().baronItemLastPurchased[baronId] = block.timestamp;
    }

    function useBaronItem(
        uint256 baronId,
        uint256 itemId,
        uint256 districtId
    ) external isActiveSeason {
        _verifyAuthorizedUser(msg.sender, baronId);

        uint256 lastUse = s().baronItemLastUsed[baronId];

        if (!isBaron(baronId)) revert TokenMustBeBaron();
        if (itemId == ITEM_SEWER) revert InvalidItemId();
        if (block.timestamp < lastUse + ITEM_TIME_DELAY_USE) revert MinimumTimeDelayNotPassed();

        Gang gang = gangOf(baronId);

        District storage district = s().districts[districtId];
        (DISTRICT_STATE districtState, int256 stateCountdown) = _districtStateAndCountdown(district);

        if (itemId == ITEM_911) {
            uint256 requests = s().latestRequests;

            if ((requests >> REQUEST_SLOT_ITEM_911) & 1 != 0) revert MinimumTimeDelayNotPassed();
            if ((requests >> REQUEST_SLOT_VRF) & 1 == 0) requestVRF();

            s().latestRequests = requests | (1 << REQUEST_SLOT_ITEM_911) | (1 << REQUEST_SLOT_VRF);
        } else {
            if (districtState != DISTRICT_STATE.IDLE && districtState != DISTRICT_STATE.REINFORCEMENT) {
                revert DistrictInvalidState();
            }

            if (itemId == ITEM_BLITZ) {
                if (
                    // require attacking/defending
                    (district.attackers != gang && district.occupants != gang) ||
                    districtState != DISTRICT_STATE.REINFORCEMENT
                ) {
                    revert InvalidItemUsage();
                }

                s().districts[districtId].blitzTimeReduction =
                    (uint256(stateCountdown) * ITEM_BLITZ_TIME_REDUCTION) /
                    100;
            } else if (itemId == ITEM_BARRICADES) {
                if (
                    // require defending
                    district.occupants != gang ||
                    (districtState != DISTRICT_STATE.REINFORCEMENT && districtState != DISTRICT_STATE.GANG_WAR)
                ) {
                    revert InvalidItemUsage();
                }
            } else if (itemId == ITEM_SMOKE) {
                if (
                    // require attacking
                    district.attackers != gang ||
                    (districtState != DISTRICT_STATE.REINFORCEMENT && districtState != DISTRICT_STATE.GANG_WAR)
                ) {
                    revert InvalidItemUsage();
                }
            }

            // apply for all items except 911
            _applyBaronItemToDistrict(itemId, districtId);
        }

        s().baronItems[gang][itemId] -= 1;
        s().baronItemLastUsed[baronId] = block.timestamp;

        emit BaronItemUsed(districtId, baronId, gang, itemId);
    }

    function bribery(uint256[] calldata tokenIds, address token) external isActiveSeason {
        uint256 tokenFee = s().briberyFee[token];
        if (tokenFee == 0) revert InvalidToken();

        for (uint256 i; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];

            if (isBaron(tokenId)) revert TokenMustBeGangster();

            (PLAYER_STATE gangsterState, int256 stateCountdown) = _gangsterStateAndCountdown(tokenId);

            if (gangsterState != PLAYER_STATE.INJURED && gangsterState != PLAYER_STATE.LOCKUP)
                revert GangsterInvalidState();

            ERC20UDS(token).transferFrom(msg.sender, address(this), tokenFee);

            if (stateCountdown > 0) {
                uint256 timeReduction = uint256(stateCountdown) / 2;

                bool isBribery = gangsterState == PLAYER_STATE.LOCKUP;

                if (isBribery) s().gangsters[tokenId].briberyTimeReduction += timeReduction;
                else s().gangsters[tokenId].recoveryTimeReduction += timeReduction;
            }
        }
    }

    function recoverBaron(uint256 baronId, uint256 exchangeType) external isActiveSeason {
        _verifyAuthorizedUser(msg.sender, baronId);

        if (!isBaron(baronId)) revert TokenMustBeBaron();

        Gang gang = gangOf(baronId);

        _spendMice(uint256(gang), RECOVERY_BARON_COST, exchangeType);

        (PLAYER_STATE gangsterState, int256 stateCountdown) = _gangsterStateAndCountdown(baronId);

        if (gangsterState != PLAYER_STATE.INJURED && gangsterState != PLAYER_STATE.LOCKUP)
            revert GangsterInvalidState();

        uint256 timeReduction = uint256(stateCountdown) / 2;

        bool isBribery = gangsterState == PLAYER_STATE.LOCKUP;

        if (isBribery) s().gangsters[baronId].briberyTimeReduction += timeReduction;
        else s().gangsters[baronId].recoveryTimeReduction += timeReduction;
    }

    function baronDeclareAttack(
        uint256 connectingId,
        uint256 districtId,
        uint256 tokenId,
        bool sewers
    ) external isActiveSeason {
        _verifyAuthorizedUser(msg.sender, tokenId);

        Gang gang = gangOf(tokenId);
        District storage district = s().districts[districtId];

        (PLAYER_STATE baronState, ) = _gangsterStateAndCountdown(tokenId);
        (DISTRICT_STATE districtState, ) = _districtStateAndCountdown(district);

        if (!isBaron(tokenId)) revert TokenMustBeBaron();
        if (district.occupants == gang) revert CannotAttackDistrictOwnedByGang();
        if (baronState != PLAYER_STATE.IDLE) revert BaronInactionable();
        if (districtState != DISTRICT_STATE.IDLE) revert DistrictInvalidState();

        if (sewers) {
            s().baronItems[gang][ITEM_SEWER] -= 1;

            _applyBaronItemToDistrict(ITEM_SEWER, districtId);
        } else {
            if (!isConnecting(connectingId, districtId)) revert InvalidConnectingDistrict();
            if (s().districts[connectingId].occupants != gang) revert ConnectingDistrictNotOwnedByGang();
            if (s().districts[connectingId].baronAttackId != 0) revert ConnectingDistrictUnderAttack();
        }

        _collectBadges(tokenId);

        Gangster storage baron = s().gangsters[tokenId];

        baron.attack = true;
        baron.roundId = district.roundId;
        baron.location = districtId;

        district.attackers = gang;
        district.baronAttackId = tokenId;
        district.attackDeclarationTime = block.timestamp;

        emit BaronAttackDeclared(connectingId, districtId, gang, tokenId);
    }

    function baronDeclareDefense(uint256 districtId, uint256 tokenId) external isActiveSeason {
        Gang gang = gangOf(tokenId);
        District storage district = s().districts[districtId];

        (PLAYER_STATE gangsterState, ) = _gangsterStateAndCountdown(tokenId);
        (DISTRICT_STATE districtState, ) = _districtStateAndCountdown(district);

        if (!isBaron(tokenId)) revert TokenMustBeBaron();
        if (district.occupants != gang) revert DistrictNotOwnedByGang();
        if (district.baronDefenseId != 0) revert BaronAlreadyDefending();
        if (gangsterState != PLAYER_STATE.IDLE) revert BaronInactionable();
        if (districtState != DISTRICT_STATE.REINFORCEMENT) revert DistrictInvalidState();

        _verifyAuthorizedUser(msg.sender, tokenId);
        _collectBadges(tokenId);

        Gangster storage baron = s().gangsters[tokenId];

        baron.attack = false;
        baron.roundId = district.roundId;
        baron.location = districtId;

        district.baronDefenseId = tokenId;

        emit BaronDefenseDeclared(districtId, gang, tokenId);
    }

    function joinGangAttack(
        uint256 districtIdFrom,
        uint256 districtIdTo,
        uint256[] calldata tokenIds
    ) external isActiveSeason {
        Gang gang = gangOf(tokenIds[0]);

        District storage district = s().districts[districtIdTo];
        District storage districtFrom = s().districts[districtIdFrom];

        uint256 baronAttackId = district.baronAttackId;

        if (baronAttackId == 0 || gangOf(baronAttackId) != gang) revert BaronMustDeclareInitialAttack();
        // if using sewers skip
        if ((district.activeItems >> ITEM_SEWER) & 1 == 0) {
            if (districtFrom.occupants != gang) revert ConnectingDistrictNotOwnedByGang();
            if (districtFrom.baronAttackId != 0) revert ConnectingDistrictUnderAttack();
        }

        _enterGangWar(districtIdTo, tokenIds, gang, true);
    }

    function joinGangDefense(uint256 districtIdTo, uint256[] calldata tokenIds) external isActiveSeason {
        Gang gang = gangOf(tokenIds[0]);
        District storage districtTo = s().districts[districtIdTo];

        if (districtTo.occupants != gang) revert InvalidConnectingDistrict();
        if (districtTo.baronAttackId == 0) revert BaronMustDeclareInitialAttack();

        _enterGangWar(districtIdTo, tokenIds, gang, false);
    }

    function exitGangWar(uint256[] calldata tokenIds) external isActiveSeason {
        for (uint256 i; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];

            (PLAYER_STATE state, ) = _gangsterStateAndCountdown(tokenId);

            if (isBaron(tokenId)) revert TokenMustBeGangster();
            if (state != PLAYER_STATE.ATTACK && state != PLAYER_STATE.DEFEND) revert GangsterInvalidState();

            _verifyAuthorizedUser(msg.sender, tokenId);
            _collectBadges(tokenId);

            bool attacking = state == PLAYER_STATE.ATTACK;

            Gangster storage gangster = s().gangsters[tokenId];

            uint256 roundId = gangster.roundId;
            uint256 districtId = gangster.location;

            if (attacking) s().districtAttackForces[districtId][roundId]--;
            else s().districtDefenseForces[districtId][roundId]--;

            emit ExitGangWar(districtId, gangOf(tokenId), tokenId);

            delete s().gangsters[tokenId];
        }
    }

    function collectBadges(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; ++i) {
            _verifyAuthorizedUser(msg.sender, tokenIds[i]);

            _collectBadges(tokenIds[i]);
        }
    }

    /* ------------- enter ------------- */

    function _enterGangWar(
        uint256 districtId,
        uint256[] calldata tokenIds,
        Gang gang,
        bool attack
    ) private {
        District storage district = s().districts[districtId];

        (DISTRICT_STATE districtState, ) = _districtStateAndCountdown(district);

        if (districtState != DISTRICT_STATE.IDLE && districtState != DISTRICT_STATE.REINFORCEMENT)
            revert DistrictInvalidState();

        uint256 districtRoundId = district.roundId;

        for (uint256 i; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];

            if (isBaron(tokenId)) revert TokenMustBeGangster();
            if (gang != gangOf(tokenId)) revert IdsMustBeOfSameGang();

            _verifyAuthorizedUser(msg.sender, tokenId);

            Gangster storage gangster = s().gangsters[tokenId];

            (PLAYER_STATE state, ) = _gangsterStateAndCountdown(tokenId);

            if (state != PLAYER_STATE.IDLE && state != PLAYER_STATE.ATTACK && state != PLAYER_STATE.DEFEND)
                revert GangsterInactionable();

            // already attacking/defending in another district
            if (state == PLAYER_STATE.ATTACK || state == PLAYER_STATE.DEFEND) {
                uint256 gangsterLocation = gangster.location;

                if (gangsterLocation == districtId) revert AlreadyInDistrict();

                uint256 oldDistrictRoundId = s().districts[gangsterLocation].roundId;

                // remove from old district
                if (attack) s().districtAttackForces[gangsterLocation][oldDistrictRoundId]--;
                else s().districtDefenseForces[gangsterLocation][oldDistrictRoundId]--;

                emit ExitGangWar(gangsterLocation, gang, tokenId);
            }

            _collectBadges(tokenId);

            gangster.attack = attack;
            gangster.roundId = districtRoundId;
            gangster.location = districtId;
            gangster.briberyTimeReduction = 0;
            gangster.recoveryTimeReduction = 0;

            emit EnterGangWar(districtId, gang, tokenId);
        }

        if (attack) s().districtAttackForces[districtId][districtRoundId] += tokenIds.length;
        else s().districtDefenseForces[districtId][districtRoundId] += tokenIds.length;
    }

    /* ------------- state ------------- */

    function isBaron(uint256 tokenId) private pure returns (bool) {
        return tokenId >= 10_000;
    }

    function gangOf(uint256 id) private view returns (Gang) {
        return Gang(gmc.gangOf(id));
    }

    function gangWarOutcome(uint256 districtId, uint256 roundId) external view returns (uint256) {
        return s().gangWarOutcomes[districtId][roundId];
    }

    function isConnecting(uint256 districtA, uint256 districtB) private view returns (bool) {
        return LibPackedMap.isConnecting(packedDistrictConnections, districtA, districtB);
    }

    function _spendMice(
        uint256 gang,
        uint256 micePrice,
        uint256 exchangeType
    ) internal {
        uint256 yakuzaTokenAmount;
        uint256 cartelTokenAmount;
        uint256 cyberpunkTokenAmount;

        if (exchangeType == 1) {
            yakuzaTokenAmount = micePrice * 3;
        } else if (exchangeType == 2) {
            cartelTokenAmount = micePrice * 3;
        } else if (exchangeType == 3) {
            cyberpunkTokenAmount = micePrice * 3;
        } else if (exchangeType == 4) {
            cartelTokenAmount = micePrice;
            cyberpunkTokenAmount = micePrice;
        } else if (exchangeType == 5) {
            yakuzaTokenAmount = micePrice;
            cyberpunkTokenAmount = micePrice;
        } else if (exchangeType == 6) {
            yakuzaTokenAmount = micePrice;
            cartelTokenAmount = micePrice;
        } else {
            yakuzaTokenAmount = micePrice / 2;
            cartelTokenAmount = micePrice / 2;
            cyberpunkTokenAmount = micePrice / 2;
        }

        vault.spendGangVaultBalance(uint256(gang), yakuzaTokenAmount, cartelTokenAmount, cyberpunkTokenAmount, true);
    }

    function _isInjured(
        uint256 gangsterId,
        uint256 districtId,
        uint256 roundId
    ) private view returns (bool) {
        uint256 gRand = s().gangWarOutcomes[districtId][roundId];

        uint256 wonP = gangWarWinProbability(districtId, roundId);

        bool won = gRand >> 128 < wonP;

        uint256 p = isInjuredProbFn(wonP, won);

        uint256 pRand = uint256(keccak256(abi.encode(gRand, gangsterId)));

        return pRand >> 128 < p;
    }

    function gangWarWinProbability(uint256 districtId, uint256 roundId) public view returns (uint256) {
        uint256 attackForce = s().districtAttackForces[districtId][roundId];
        uint256 defenseForce = s().districtDefenseForces[districtId][roundId];

        District storage district = s().districts[districtId];

        uint256 items = district.activeItems;

        attackForce += ((items >> ITEM_SMOKE) & 1) * attackForce * ITEM_SMOKE_ATTACK_INCREASE;
        defenseForce += ((items >> ITEM_BARRICADES) & 1) * defenseForce * ITEM_BARRICADES_DEFENSE_INCREASE;

        bool baronDefense = district.baronDefenseId != 0;

        return gangWarWonProbFn(attackForce, defenseForce, baronDefense);
    }

    function _gangsterStateAndCountdown(uint256 gangsterId) private view returns (PLAYER_STATE, int256) {
        Gangster storage gangster = s().gangsters[gangsterId];

        uint256 districtId = gangster.location;
        District storage district = s().districts[districtId];

        uint256 districtRoundId = district.roundId;
        uint256 gangsterRoundId = gangster.roundId;

        // gangster not in sync with district => IDLE
        if (districtRoundId > 1 + gangsterRoundId) return (PLAYER_STATE.IDLE, 0);

        int256 stateCountdown;

        // -------- check lockup (takes precedence); if lockupTime is still active, then player must be in round
        uint256 lockupTime = district.lockupTime;

        if (lockupTime != 0) {
            stateCountdown =
                int256(TIME_LOCKUP) -
                int256(block.timestamp - lockupTime) -
                int256(gangster.briberyTimeReduction);
            if (stateCountdown > 0) return (PLAYER_STATE.LOCKUP, stateCountdown);
        }

        bool isActiveRound = districtRoundId == gangsterRoundId;

        if (isActiveRound) {
            Gang gang = gangOf(gangsterId);

            bool attacking = district.attackers == gang;

            // -------- check gang war outcome
            uint256 attackDeclarationTime = district.attackDeclarationTime;

            if (attackDeclarationTime == 0) return (PLAYER_STATE.IDLE, 0);

            stateCountdown = int256(TIME_REINFORCEMENTS) - int256(block.timestamp - attackDeclarationTime);

            // player in reinforcement phase; not committed yet
            if (stateCountdown > 0) return (attacking ? PLAYER_STATE.ATTACK : PLAYER_STATE.DEFEND, stateCountdown);

            stateCountdown += int256(TIME_GANG_WAR);

            return (attacking ? PLAYER_STATE.ATTACK_LOCKED : PLAYER_STATE.DEFEND_LOCKED, stateCountdown);
        }

        // we assume district.lastOutcomeTime must be non-zero
        // as otherwise the roundIds would match

        // -------- check injury
        bool injured = _isInjured(gangsterId, districtId, districtRoundId);

        if (injured) {
            stateCountdown =
                int256(TIME_RECOVERY) -
                int256(block.timestamp - district.lastOutcomeTime) -
                int256(gangster.recoveryTimeReduction);

            if (stateCountdown > 0) return (PLAYER_STATE.INJURED, stateCountdown);
        }

        return (PLAYER_STATE.IDLE, 0);
    }

    function _districtStateAndCountdown(uint256 districtId) private view returns (DISTRICT_STATE, int256) {
        return _districtStateAndCountdown(s().districts[districtId]);
    }

    function _districtStateAndCountdown(District storage district) private view returns (DISTRICT_STATE, int256) {
        // check if district is in `lockup`-state
        int256 stateCountdown = int256(TIME_LOCKUP) - int256(block.timestamp - district.lockupTime);
        if (stateCountdown > 0) return (DISTRICT_STATE.LOCKUP, stateCountdown);

        // check if district is in `truce`-state
        stateCountdown = int256(TIME_TRUCE) - int256(block.timestamp - district.lastOutcomeTime);
        if (stateCountdown > 0) return (DISTRICT_STATE.TRUCE, stateCountdown);

        // check if district is in initial `idle`-state
        uint256 attackDeclarationTime = district.attackDeclarationTime;
        if (attackDeclarationTime == 0) return (DISTRICT_STATE.IDLE, 0);

        // check if district is in all other states
        stateCountdown =
            int256(TIME_REINFORCEMENTS)
            - int256(block.timestamp - attackDeclarationTime)
            - int256(district.blitzTimeReduction); // prettier-ignore

        if (stateCountdown > 0) return (DISTRICT_STATE.REINFORCEMENT, stateCountdown);

        stateCountdown += int256(TIME_GANG_WAR);
        if (stateCountdown > 0) return (DISTRICT_STATE.GANG_WAR, stateCountdown);

        return (DISTRICT_STATE.POST_GANG_WAR, stateCountdown);
    }

    function _advanceDistrictRound(uint256 districtId) private {
        District storage district = s().districts[districtId];

        district.attackers = Gang.NONE;
        district.activeItems = 0;
        district.baronAttackId = 0;
        district.baronDefenseId = 0;
        district.lastOutcomeTime = block.timestamp;
        district.attackDeclarationTime = 0;
        district.blitzTimeReduction = 0;

        ++district.roundId;
    }

    function _call911Now(uint256 districtId) private {
        District storage district = s().districts[districtId];

        Gang token = district.token;

        uint256 lockupAmount0;
        uint256 lockupAmount1;
        uint256 lockupAmount2;

        if (token == Gang.YAKUZA) lockupAmount0 = LOCKUP_FINE;
        else if (token == Gang.CARTEL) lockupAmount1 = LOCKUP_FINE;
        else if (token == Gang.CYBERP) lockupAmount2 = LOCKUP_FINE;

        uint256 lockupOccupants = uint256(district.occupants);
        uint256 lockupAttackers = uint256(district.attackDeclarationTime != 0 ? district.attackers : Gang.NONE);

        vault.spendGangVaultBalance(lockupOccupants, lockupAmount0, lockupAmount1, lockupAmount2, false);

        // if attackers are present
        if (lockupAttackers != uint256(Gang.NONE)) {
            vault.spendGangVaultBalance(lockupAttackers, lockupAmount0, lockupAmount1, lockupAmount2, false);
        }

        _advanceDistrictRound(districtId);

        district.lockupTime = block.timestamp;

        emit CopsLockup(districtId, Gang(lockupOccupants), Gang(lockupAttackers));
    }

    function _applyBaronItemToDistrict(uint256 itemId, uint256 districtId) private {
        uint256 items = s().districts[districtId].activeItems;

        if (items & (1 << itemId) != 0) revert ItemAlreadyActive();

        s().districts[districtId].activeItems = items | (1 << itemId);
    }

    function _collectBadges(uint256 gangsterId) private {
        Gangster storage gangster = s().gangsters[gangsterId];

        uint256 roundId = gangster.roundId;

        if (roundId != 0) {
            uint256 districtId = gangster.location;

            uint256 outcome = s().gangWarOutcomes[districtId][roundId];

            if (outcome != 0) {
                bool lastRoundInjured = _isInjured(gangsterId, districtId, roundId);
                bool lastRoundVictory = gangster.attack == gangAttackSuccess(districtId, roundId);
                uint256 badgesEarned = lastRoundVictory ? BADGES_EARNED_VICTORY : BADGES_EARNED_DEFEAT;

                if (lastRoundInjured) emit GangsterInjured(districtId, gangsterId);

                // @note can we assume msg.sender?
                // should probably go into GMC contract
                address owner = gmc.ownerOf(gangsterId);

                Offer memory rental = gmc.getActiveOffer(gangsterId);

                address renter = rental.renter;

                if (renter != address(0)) {
                    uint256 renterAmount = (badgesEarned * rental.renterShare) / 100;

                    badges.mint(renter, renterAmount);

                    badgesEarned -= renterAmount;
                }

                badges.mint(owner, badgesEarned);

                uint256 p = gangWarWinProbability(districtId, roundId);

                emit BadgesEarned(districtId, gangsterId, gangOf(gangsterId), lastRoundVictory, p);

                gangster.roundId = 0;
            }
        }
    }

    function _verifyAuthorizedUser(address owner, uint256 tokenId) private view {
        if (!gmc.isAuthorizedUser(owner, tokenId)) revert NotAuthorized();
    }

    /* ------------- upkeep ------------- */

    function checkUpkeep(bytes calldata) external view returns (bool, bytes memory) {
        District storage district;
        uint256 upkeepIds;
        uint256 requestedIds = s().latestRequests;

        for (uint256 id; id < 21; ++id) {
            if ((requestedIds >> id) & 1 == 0) {
                district = s().districts[id];

                (DISTRICT_STATE districtState, ) = _districtStateAndCountdown(district);

                if (districtState == DISTRICT_STATE.POST_GANG_WAR) {
                    upkeepIds |= 1 << id;
                }
            }
        }

        return (upkeepIds > 0, abi.encode(upkeepIds));
    }

    function performUpkeep(bytes calldata performData) external {
        uint256 upkeepIds = uint256(bytes32(performData));

        District storage district;

        uint256 requestedIds = s().latestRequests;
        uint256 newRequestedIds = requestedIds;

        // should normally always only add new ids, but never remove any
        uint256 diffIds = newRequestedIds ^ upkeepIds;

        for (uint256 id; id < 21; ++id) {
            if ((diffIds >> id) & 1 != 0) {
                district = s().districts[id];

                (DISTRICT_STATE districtState, ) = _districtStateAndCountdown(district);

                if (districtState == DISTRICT_STATE.POST_GANG_WAR) {
                    newRequestedIds |= 1 << id;
                }
            }
        }

        if (newRequestedIds != 0 && (requestedIds >> REQUEST_SLOT_VRF) & 1 == 0) {
            requestVRF();

            newRequestedIds |= 1 << REQUEST_SLOT_VRF;
        }
        if (newRequestedIds != requestedIds) s().latestRequests = newRequestedIds;
    }

    function fulfillRandomWords(uint256, uint256[] calldata randomWords) internal override {
        uint256 requestIds = s().latestRequests;

        if (requestIds == 0) revert InvalidVRFRequest();

        bool copsLockupRequest = (requestIds >> REQUEST_SLOT_ITEM_911) & 1 == 1;

        uint256 rand = randomWords[0];
        District storage district;

        bool lockup = copsLockupRequest ||
            (rand % 100 < LOCKUP_CHANCE && block.timestamp - s().lastGlobalLockupTime > COPS_LOCKUP_MINIMUM_INTERVAL);
        uint256 lockupDistrictId = rand % 21;

        if (lockup) {
            uint256 i;

            for (; i < 16 && block.timestamp - s().districts[lockupDistrictId].lockupTime < TIME_LOCKUP; ++i) {
                rand = rand >> 16;
                lockupDistrictId = rand % 21; // first 16 districts have chance of 3121 in 2^16 (vs. 3120)
            }
            // we give up after 16 tries; tough luck
            if (lockup = i != 16) {
                _call911Now(lockupDistrictId);

                // signal that it was triggered by an item
                if (copsLockupRequest) {
                    _applyBaronItemToDistrict(ITEM_911, lockupDistrictId);

                    s().lastGlobalLockupTime = uint40(block.timestamp);
                }
            }
        }

        for (uint256 id; id < 21; ) {
            // fail-safe to not get stuck
            if (gasleft() < 2_000) break;

            if ((requestIds >> id) & 1 != 0) {
                district = s().districts[id];

                if (lockup && lockupDistrictId == id) {
                    unchecked {
                        ++id;
                    }
                    continue;
                }

                (DISTRICT_STATE districtState, ) = _districtStateAndCountdown(district);

                if (districtState == DISTRICT_STATE.POST_GANG_WAR) {
                    Gang attackers = district.attackers;
                    Gang occupants = district.occupants;

                    uint256 roundId = district.roundId;

                    uint256 r = uint256(keccak256(abi.encode(rand, id)));

                    s().gangWarOutcomes[id][roundId] = r;

                    if (gangAttackSuccess(id, roundId)) {
                        vault.transferYield(
                            uint256(occupants),
                            uint256(attackers),
                            uint256(district.token),
                            district.yield
                        );

                        district.occupants = attackers;

                        emit GangWarWon(id, occupants, attackers);
                    } else {
                        emit GangWarWon(id, attackers, occupants);
                    }

                    _advanceDistrictRound(id);
                }
            }

            unchecked {
                ++id;
            }
        }

        delete s().latestRequests;
    }

    /* ------------- modifier ------------- */

    modifier isActiveSeason() {
        if (block.timestamp < s().seasonStart || s().seasonEnd < block.timestamp) revert GangWarNotActive();
        _;
    }

    /* ------------- owner ------------- */

    function setSeason(uint40 start, uint40 end) external onlyOwner {
        s().seasonStart = start;
        s().seasonEnd = end;

        GangVault(vault).setSeason(start, end);
    }

    function setBaronItemBalances(uint256[] calldata itemIds, uint256[] calldata amounts) external payable onlyOwner {
        for (uint256 i; i < itemIds.length; ++i) {
            for (uint256 gang; gang < 3; ++gang) {
                s().baronItems[Gang(gang)][itemIds[i]] = amounts[i];
            }
        }
    }

    function setBaronItemCost(uint256 itemId, uint256 cost) external payable onlyOwner {
        s().baronItemCost[itemId] = cost;
    }

    function setBriberyFee(address token, uint256 amount) external payable onlyOwner {
        s().briberyFee[token] = amount;
    }

    function _authorizeUpgrade() internal override onlyOwner {}
}

function gangWarWonProbFn(
    uint256 attackForce,
    uint256 defenseForce,
    bool baronDefense
) pure returns (uint256) {
    attackForce += 1;
    defenseForce += 1;

    uint256 q = attackForce < DEFENSE_FAVOR_LIM ? ((1 << 32) - (attackForce << 32) / DEFENSE_FAVOR_LIM) ** 2 : 0; // prettier-ignore

    defenseForce = ((q * DEFENSE_FAVOR + ((1 << 64) - q) * ATTACK_FAVOR) * defenseForce) / 100;

    if (baronDefense) defenseForce += BARON_DEFENSE_FORCE << 64;

    uint256 p = (attackForce << 128) / ((attackForce << 64) + defenseForce);

    if (p > 1 << 63) p = (1 << 192) - ((((1 << 64) - p)**3) << 2);
    else p = (p**3) << 2;

    return p >> 64; // >> 128
}

function isInjuredProbFn(uint256 gangWarWonP, bool gangWarWon) pure returns (uint256) {
    uint256 c = gangWarWon ? INJURED_WON_FACTOR : INJURED_LOST_FACTOR;

    return (c * ((1 << 128) - 1 - gangWarWonP)) / 100; // >> 128
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GangToken} from "./tokens/GangToken.sol";
import {UUPSUpgrade} from "UDS/proxy/UUPSUpgrade.sol";
import {AccessControlUDS} from "UDS/auth/AccessControlUDS.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_GANG_VAULT = keccak256("diamond.storage.gang.vault");
// @note flexible storage, can be changed to reset accumulated yields
bytes32 constant DIAMOND_STORAGE_GANG_VAULT_FX = keccak256("diamond.storage.gang.vault.season.1");

struct GangVaultDS {
    uint40 seasonStart;
    uint40 seasonEnd;
    uint40[3] totalShares;
    uint40[3] lastUpdateTime;
    uint80[3][3] yield;
    mapping(address => uint40[3]) userShares;
    mapping(address => uint80[3]) userBalance;
    mapping(address => uint80[3]) accruedBalances;
}

struct GangVaultFlexibleDS {
    uint80[3][3] accruedYieldPerShare;
    mapping(address => uint80[3][3]) lastUserYieldPerShare;
}

function s() pure returns (GangVaultDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_GANG_VAULT;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

function fx() pure returns (GangVaultFlexibleDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_GANG_VAULT_FX;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

/// @title Gangsta Mice City Gang Vault Rewards
/// @author phaze (https://github.com/0xPhaze)
contract GangVault is UUPSUpgrade, AccessControlUDS {
    GangVaultDS private __storageLayoutPersistent;

    event Burn(uint256 indexed gang, uint256 indexed token, uint256 amount);
    event SharesAdded(address indexed user, uint256 indexed gang, uint256 shares);
    event SharesRemoved(address indexed user, uint256 indexed gang, uint256 shares);

    GangToken immutable token0;
    GangToken immutable token1;
    GangToken immutable token2;

    uint256 immutable gangVaultFeePercent;
    bytes32 constant CONTROLLER = keccak256("GANG.VAULT.CONTROLLER");

    constructor(address[3] memory gangTokens, uint256 gangVaultFee) {
        gangVaultFeePercent = gangVaultFee;

        require(gangVaultFee < 100);

        token0 = GangToken(gangTokens[0]);
        token1 = GangToken(gangTokens[1]);
        token2 = GangToken(gangTokens[2]);
    }

    function init() external initializer {
        __AccessControl_init();
    }

    /* ------------- external ------------- */

    function claimUserBalance() external {
        _updateUserBalance(0, msg.sender);
        _updateUserBalance(1, msg.sender);
        _updateUserBalance(2, msg.sender);

        uint256 balance_0 = uint256(s().userBalance[msg.sender][0]) * 1e10;
        uint256 balance_1 = uint256(s().userBalance[msg.sender][1]) * 1e10;
        uint256 balance_2 = uint256(s().userBalance[msg.sender][2]) * 1e10;

        token0.mint(msg.sender, balance_0);
        token1.mint(msg.sender, balance_1);
        token2.mint(msg.sender, balance_2);

        s().userBalance[msg.sender][0] = 0;
        s().userBalance[msg.sender][1] = 0;
        s().userBalance[msg.sender][2] = 0;
    }

    /* ------------- view ------------- */

    function seasonStart() external view returns (uint256) {
        return s().seasonStart;
    }

    function seasonEnd() external view returns (uint256) {
        return s().seasonEnd;
    }

    function getYield() external view returns (uint256[3][3] memory out) {
        uint80[3][3] memory yield = s().yield;
        assembly { out := yield } // prettier-ignore
    }

    function getUserShares(address account) external view returns (uint256[3] memory out) {
        uint40[3] memory shares = s().userShares[account];
        assembly { out := shares } // prettier-ignore
    }

    function getClaimableUserBalance(address account) public view returns (uint256[3] memory out) {
        uint256[3] memory unclaimed = _getUnclaimedUserBalance(account);

        out[0] = uint256(s().userBalance[account][0]) * 1e10 + unclaimed[0];
        out[1] = uint256(s().userBalance[account][1]) * 1e10 + unclaimed[1];
        out[2] = uint256(s().userBalance[account][2]) * 1e10 + unclaimed[2];
    }

    function getAccruedBalance(address account) external view returns (uint256[3] memory out) {
        uint256[3] memory unclaimed = _getUnclaimedUserBalance(account);

        out[0] = uint256(s().accruedBalances[account][0]) * 1e10 + unclaimed[0];
        out[1] = uint256(s().accruedBalances[account][1]) * 1e10 + unclaimed[1];
        out[2] = uint256(s().accruedBalances[account][2]) * 1e10 + unclaimed[2];
    }

    function getGangVaultBalance(uint256 gang) external view returns (uint256[3] memory out) {
        address gangAccount = _getGangAccount(gang);
        uint256[3] memory unclaimed = _getUnclaimedGangBalance(gang);

        out[0] = uint256(s().userBalance[gangAccount][0]) * 1e10 + unclaimed[0];
        out[1] = uint256(s().userBalance[gangAccount][1]) * 1e10 + unclaimed[1];
        out[2] = uint256(s().userBalance[gangAccount][2]) * 1e10 + unclaimed[2];
    }

    function getAccruedGangVaultBalances(uint256 gang) external view returns (uint256[3] memory out) {
        address gangAccount = _getGangAccount(gang);
        uint256[3] memory unclaimed = _getUnclaimedGangBalance(gang);

        out[0] = uint256(s().accruedBalances[gangAccount][0]) * 1e10 + unclaimed[0];
        out[1] = uint256(s().accruedBalances[gangAccount][1]) * 1e10 + unclaimed[1];
        out[2] = uint256(s().accruedBalances[gangAccount][2]) * 1e10 + unclaimed[2];
    }

    /* ------------- controller ------------- */

    function setSeason(uint40 start, uint40 end) external onlyRole(CONTROLLER) {
        require(start <= end);

        s().seasonStart = start;
        s().seasonEnd = end;
    }

    function setYield(uint256 gang, uint256[3] calldata yield) external onlyRole(CONTROLLER) {
        _updateYieldPerShare(gang);

        // implicit 1e18 decimals
        require(yield[0] <= 1e12);
        require(yield[1] <= 1e12);
        require(yield[2] <= 1e12);

        s().yield[gang][0] = uint80(yield[0]);
        s().yield[gang][1] = uint80(yield[1]);
        s().yield[gang][2] = uint80(yield[2]);
    }

    function addShares(
        address account,
        uint256 gang,
        uint40 amount
    ) external onlyRole(CONTROLLER) {
        _updateYieldPerShare(gang);
        _updateUserBalance(gang, account);

        s().totalShares[gang] += amount;
        s().userShares[account][gang] += amount;

        emit SharesAdded(account, gang, amount);
    }

    function removeShares(
        address account,
        uint256 gang,
        uint40 amount
    ) external onlyRole(CONTROLLER) {
        _updateYieldPerShare(gang);
        _updateUserBalance(gang, account);

        s().totalShares[gang] -= amount;
        s().userShares[account][gang] -= amount;

        emit SharesRemoved(account, gang, amount);
    }

    function transferShares(
        address from,
        address to,
        uint256 gang,
        uint40 amount
    ) external onlyRole(CONTROLLER) {
        _updateYieldPerShare(gang);
        _updateUserBalance(gang, from);
        _updateUserBalance(gang, to);

        s().userShares[from][gang] -= amount;
        s().userShares[to][gang] += amount;

        emit SharesRemoved(from, gang, amount);
        emit SharesAdded(to, gang, amount);
    }

    function resetShares(address account, uint40[3] memory shares) external onlyRole(CONTROLLER) {
        for (uint256 i; i < 3; ++i) {
            _updateYieldPerShare(i);
            _updateUserBalance(i, account);

            s().totalShares[i] -= s().userShares[account][i];
            s().totalShares[i] += shares[i];
            s().userShares[account][i] = shares[i];
        }
    }

    function transferYield(
        uint256 gangFrom,
        uint256 gangTo,
        uint256 token,
        uint256 yield
    ) external onlyRole(CONTROLLER) {
        _updateYieldPerShare(gangFrom);
        _updateYieldPerShare(gangTo);

        s().yield[gangFrom][token] -= uint80(yield);
        s().yield[gangTo][token] += uint80(yield);
    }

    function spendGangVaultBalance(
        uint256 gang,
        uint256 amount_0,
        uint256 amount_1,
        uint256 amount_2,
        bool strict
    ) external onlyRole(CONTROLLER) {
        address gangAccount = _getGangAccount(gang);
        uint256 totalShares = s().totalShares[gang];
        uint256 numSharesTimes100 = max(totalShares, 1) * gangVaultFeePercent;

        _updateUserBalance(gang, gangAccount, numSharesTimes100);

        uint256 balance_0 = uint256(s().userBalance[gangAccount][0]) * 1e10;
        uint256 balance_1 = uint256(s().userBalance[gangAccount][1]) * 1e10;
        uint256 balance_2 = uint256(s().userBalance[gangAccount][2]) * 1e10;

        if (!strict) {
            amount_0 = balance_0 > amount_0 ? amount_0 : balance_0;
            amount_1 = balance_1 > amount_1 ? amount_1 : balance_1;
            amount_2 = balance_2 > amount_2 ? amount_2 : balance_2;
        }

        s().userBalance[gangAccount][0] = uint80((balance_0 - amount_0) / 1e10);
        s().userBalance[gangAccount][1] = uint80((balance_1 - amount_1) / 1e10);
        s().userBalance[gangAccount][2] = uint80((balance_2 - amount_2) / 1e10);

        if (amount_0 > 0) emit Burn(gang, 0, amount_0);
        if (amount_1 > 0) emit Burn(gang, 1, amount_1);
        if (amount_2 > 0) emit Burn(gang, 2, amount_2);
    }

    /* ------------- private ------------- */

    /// @dev gang vault balances are stuck in user balances under accounts 13370, 13371, 13372.
    function _getGangAccount(uint256 gang) private pure returns (address) {
        return address(uint160(13370 + gang));
    }

    function _updateYieldPerShare(uint256 gang) private {
        (uint256 yps_0, uint256 yps_1, uint256 yps_2) = _accruedYieldPerShare(gang);

        fx().accruedYieldPerShare[gang][0] = uint80(yps_0);
        fx().accruedYieldPerShare[gang][1] = uint80(yps_1);
        fx().accruedYieldPerShare[gang][2] = uint80(yps_2);

        s().lastUpdateTime[gang] = uint40(block.timestamp);
    }

    function _accruedYieldPerShare(uint256 gang)
        private
        view
        returns (
            uint256 yps_0,
            uint256 yps_1,
            uint256 yps_2
        )
    {
        yps_0 = fx().accruedYieldPerShare[gang][0];
        yps_1 = fx().accruedYieldPerShare[gang][1];
        yps_2 = fx().accruedYieldPerShare[gang][2];

        // setting to 1 allows gangs to earn if there are no stakers
        // though this is a degenerate case
        uint256 totalShares = max(s().totalShares[gang], 1);

        // needs to be in the correct range
        // yield is daily yield with implicit 1e18 decimals
        // this number thus needs to be multiplied by 1e18
        // multiply by 1e8 first to ensure valid range (1e18 would overflow in 2^80)
        // multiply by 1e10 when claiming

        // overflow assumptions (for 1e4 days / 30 years of staking):
        // s().yield[gang][token] < 1e12 (closer to 1e8)
        // timeScaled < (1e4 days) * 1e8 = 1e12 days
        // => numerator < 1e24 days
        // => divisor > 1 days
        // => max_yps < 1e24 < 2^80
        uint256 divisor = totalShares * 1 days;
        uint256 lastUpdateTime = s().lastUpdateTime[gang];

        uint256 startTime = s().seasonStart;
        uint256 endTime = s().seasonEnd;

        // `lastUpdateTime` can become 0 when resetting to a new season.
        if (lastUpdateTime < startTime) lastUpdateTime = startTime;

        uint256 timestamp = block.timestamp > endTime ? endTime : block.timestamp;
        uint256 timeScaled = (timestamp > lastUpdateTime) ? (timestamp - lastUpdateTime) * 1e8 : 0;

        yps_0 += (timeScaled * s().yield[gang][0]) / divisor;
        yps_1 += (timeScaled * s().yield[gang][1]) / divisor;
        yps_2 += (timeScaled * s().yield[gang][2]) / divisor;
    }

    function _updateUserBalance(uint256 gang, address account) private {
        uint256 numSharesTimes100 = s().userShares[account][gang] * (100 - gangVaultFeePercent);

        _updateUserBalance(gang, account, numSharesTimes100);
    }

    function _updateUserBalance(
        uint256 gang,
        address account,
        uint256 numSharesTimes100
    ) private {
        (uint256 yps_0, uint256 yps_1, uint256 yps_2) = _accruedYieldPerShare(gang);

        // userBalance <= max_yps < 1e24 < 2^80
        uint80 addBalance_0 = uint80((numSharesTimes100 * (yps_0 - fx().lastUserYieldPerShare[account][gang][0])) / 100); // prettier-ignore
        uint80 addBalance_1 = uint80((numSharesTimes100 * (yps_1 - fx().lastUserYieldPerShare[account][gang][1])) / 100); // prettier-ignore
        uint80 addBalance_2 = uint80((numSharesTimes100 * (yps_2 - fx().lastUserYieldPerShare[account][gang][2])) / 100); // prettier-ignore

        s().userBalance[account][0] += addBalance_0;
        s().userBalance[account][1] += addBalance_1;
        s().userBalance[account][2] += addBalance_2;

        s().accruedBalances[account][0] += addBalance_0;
        s().accruedBalances[account][1] += addBalance_1;
        s().accruedBalances[account][2] += addBalance_2;

        fx().lastUserYieldPerShare[account][gang][0] = uint80(yps_0);
        fx().lastUserYieldPerShare[account][gang][1] = uint80(yps_1);
        fx().lastUserYieldPerShare[account][gang][2] = uint80(yps_2);
    }

    function _getUnclaimedUserBalance(address account) private view returns (uint256[3] memory out) {
        uint256 sharesFactor = 100 - gangVaultFeePercent;

        uint256 numSharesTimes100_0 = uint256(s().userShares[account][0]) * sharesFactor;
        uint256 numSharesTimes100_1 = uint256(s().userShares[account][1]) * sharesFactor;
        uint256 numSharesTimes100_2 = uint256(s().userShares[account][2]) * sharesFactor;

        uint256[3] memory balances_0 = _getUnclaimedUserBalance(0, account, numSharesTimes100_0);
        uint256[3] memory balances_1 = _getUnclaimedUserBalance(1, account, numSharesTimes100_1);
        uint256[3] memory balances_2 = _getUnclaimedUserBalance(2, account, numSharesTimes100_2);

        out[0] = balances_0[0] + balances_1[0] + balances_2[0];
        out[1] = balances_0[1] + balances_1[1] + balances_2[1];
        out[2] = balances_0[2] + balances_1[2] + balances_2[2];
    }

    function _getUnclaimedUserBalance(
        uint256 gang,
        address account,
        uint256 numSharesTimes100
    ) private view returns (uint256[3] memory balances) {
        (uint256 yps_0, uint256 yps_1, uint256 yps_2) = _accruedYieldPerShare(gang);

        balances[0] = numSharesTimes100 * (yps_0 - fx().lastUserYieldPerShare[account][gang][0]) * 1e10 / 100; // prettier-ignore
        balances[1] = numSharesTimes100 * (yps_1 - fx().lastUserYieldPerShare[account][gang][1]) * 1e10 / 100; // prettier-ignore
        balances[2] = numSharesTimes100 * (yps_2 - fx().lastUserYieldPerShare[account][gang][2]) * 1e10 / 100; // prettier-ignore
    }

    function _getUnclaimedGangBalance(uint256 gang) private view returns (uint256[3] memory balances) {
        address gangAccount = _getGangAccount(gang);
        uint256 totalShares = s().totalShares[gang];
        uint256 numSharesTimes100 = max(totalShares, 1) * gangVaultFeePercent;

        balances = _getUnclaimedUserBalance(gang, gangAccount, numSharesTimes100);
    }

    /* ------------- upgrade ------------- */

    function _authorizeUpgrade() internal view override onlyRole(DEFAULT_ADMIN_ROLE) {}
}

function max(uint256 a, uint256 b) pure returns (uint256) {
    return a < b ? b : a;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnableUDS} from "UDS/auth/OwnableUDS.sol";
import {UUPSUpgrade} from "UDS/proxy/UUPSUpgrade.sol";
import {ERC20BurnableUDS} from "UDS/tokens/extensions/ERC20BurnableUDS.sol";
import {AccessControlUDS} from "UDS/auth/AccessControlUDS.sol";

/// @title Gang Token
/// @author phaze (https://github.com/0xPhaze)
contract GangToken is UUPSUpgrade, OwnableUDS, ERC20BurnableUDS, AccessControlUDS {
    uint8 public constant override decimals = 18;

    bytes32 constant AUTHORITY = keccak256("AUTHORITY");

    function init(string calldata name_, string calldata symbol_) external initializer {
        __Ownable_init();
        __AccessControl_init();
        __ERC20_init(name_, symbol_, 18);
    }

    /* ------------- external ------------- */

    function mint(address user, uint256 amount) external onlyRole(AUTHORITY) {
        _mint(user, amount);
    }

    /* ------------- ERC20Burnable ------------- */

    function burnFrom(address from, uint256 amount) public override {
        if (msg.sender == from || hasRole(AUTHORITY, msg.sender)) _burn(from, amount);
        else super.burnFrom(from, amount);
    }

    /* ------------- owner ------------- */

    function _authorizeUpgrade() internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Library for Packed Boolean Mappings
 * @author phaze (https://github.com/0xPhaze)
 * @dev Example (n=10):
 *
 *   enc = 10 * i + j - ((i + 1)^2 + (i + 1)) / 2
 *
 *   ij  0  1  2  3  4  5  6  7  8  9
 *   0   \  0  1  2  3  4  5  6  7  8
 *   1      \  9 10 11 12 13 14 15 16
 *   2         \ 17 18 19 20 21 22 23
 *   3            \ 24 25 26 27 28 29
 *   4               \ 30 31 32 33 34
 *   5                  \ 35 36 37 38
 *   6                     \ 39 40 41
 *   7                        \ 42 43
 *   8                           \ 44
 *   9                              \
 *
 *   Bitcount:
 *
 *   n = 10 uses: 10 * 10 - 1 - 10 * 11 / 2 = 44 bits
 *   n = 21 uses: 21 * 21 - 1 - 21 * 22 / 2 = 209 bits
 *   n = 23 is the maximum to fit in a uint256:
 *       23 * 23 - 1 - 23 * 24 / 2 = 252 bits
 **/
library LibPackedMap {
    function encode(bool[10][10] memory map) internal pure returns (uint256 out) {
        unchecked {
            for (uint256 i; i < 10; i++) {
                for (uint256 j = i + 1; j < 10; j++) {
                    out |= uint256(map[i][j] ? 1 : 0) << (i * 10 + j - ((i + 1) * (i + 2)) / 2);
                }
            }
        }
    }

    function decode10(uint256 enc) internal pure returns (bool[10][10] memory out) {
        unchecked {
            for (uint256 i; i < 10; i++) {
                for (uint256 j = i + 1; j < 10; j++) {
                    out[i][j] = (enc >> (i * 10 + j - ((i + 1) * (i + 2)) / 2)) & 1 != 0;
                }
            }
        }
    }

    function encode(bool[21][21] memory map) internal pure returns (uint256 out) {
        unchecked {
            for (uint256 i; i < 21; i++) {
                for (uint256 j = i + 1; j < 21; j++) {
                    out |= uint256(map[i][j] ? 1 : 0) << (i * 21 + j - ((i + 1) * (i + 2)) / 2);
                }
            }
        }
    }

    function decode21(uint256 enc) internal pure returns (bool[21][21] memory out) {
        unchecked {
            for (uint256 i; i < 21; i++) {
                for (uint256 j = i + 1; j < 21; j++) {
                    out[i][j] = isConnecting(enc, i, j);
                }
            }
        }
    }

    function isConnecting(
        uint256 enc,
        uint256 a,
        uint256 b
    ) internal pure returns (bool) {
        if (a > b) (a, b) = (b, a);
        return (a != b) && (enc >> (a * 21 + b - ((a + 1) * (a + 2)) / 2)) & 1 != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ---------- constants

address constant COORDINATOR_RINKEBY = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
bytes32 constant KEYHASH_RINKEBY = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

address constant COORDINATOR_MUMBAI = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
bytes32 constant KEYHASH_MUMBAI = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

address constant COORDINATOR_POLYGON = 0xAE975071Be8F8eE67addBC1A82488F1C24858067;
bytes32 constant KEYHASH_POLYGON = 0x6e099d640cde6de9d40ac749b4b594126b0169747122711109c9985d47751f93;

address constant COORDINATOR_MAINNET = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
bytes32 constant KEYHASH_MAINNET = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

// ---------- interfaces

interface IVRFCoordinatorV2 {
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);
}

// ---------- errors

error CallerNotCoordinator();

/// @title VRFConsumerV2
/// @author phaze (https://github.com/0xPhaze)
abstract contract VRFConsumerV2 {
    bytes32 private immutable keyHash;
    address private immutable coordinator;
    uint64 private immutable subscriptionId;
    uint32 private immutable callbackGasLimit;
    uint16 private immutable requestConfirmations;

    constructor(
        address coordinator_,
        bytes32 keyHash_,
        uint64 subscriptionId_,
        uint16 requestConfirmations_,
        uint32 callbackGasLimit_
    ) {
        keyHash = keyHash_;
        coordinator = coordinator_;
        subscriptionId = subscriptionId_;
        callbackGasLimit = callbackGasLimit_;
        requestConfirmations = requestConfirmations_;
    }

    /* ------------- virtual ------------- */

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal virtual;

    /* ------------- external ------------- */

    function rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external payable {
        if (msg.sender != coordinator) revert CallerNotCoordinator();

        fulfillRandomWords(requestId, randomWords);
    }

    /* ------------- internal ------------- */

    function requestVRF() internal virtual returns (uint256) {
        return
            IVRFCoordinatorV2(coordinator).requestRandomWords(
                keyHash,
                subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                1
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GangVault} from "../GangVault.sol";
import {LibCrumbMap} from "../lib/LibCrumbMap.sol";
import {Gang, GangWar} from "../GangWar.sol";
import {GMCMarket, Offer, s as marketDS} from "../GMCMarket.sol";

import {ERC721UDS} from "UDS/tokens/ERC721UDS.sol";
import {OwnableUDS} from "UDS/auth/OwnableUDS.sol";
import {UUPSUpgrade} from "UDS/proxy/UUPSUpgrade.sol";
import {FxERC721Child} from "fx-contracts/FxERC721Child.sol";
import {FxERC721EnumerableChild} from "fx-contracts/extensions/FxERC721EnumerableChild.sol";
import {LibEnumerableSet, Uint256Set} from "UDS/lib/LibEnumerableSet.sol";

import "solady/utils/ECDSA.sol";
import "solady/utils/LibString.sol";

// @note fked the naming of this one up; needs to stay "rumble" for now
bytes32 constant DIAMOND_STORAGE_GMC_CHILD = keccak256("diamond.storage.gmc.child.season.rumble");

struct GMCDS {
    string baseURI;
    string postFixURI;
    string unrevealedURI;
    mapping(uint256 => string) name;
    mapping(address => string) playerName;
    mapping(uint256 => uint256) gangMap;
}

function s() pure returns (GMCDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_GMC_CHILD;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

error GangUnset();
error InvalidName();
error NotAuthorized();
error InvalidChoice();
error InvalidSignature();
error ChunkDataAlreadySet();
error GangstersAlreadyMinted();

/// @title Gangsta Mice City Child
/// @author phaze (https://github.com/0xPhaze)
contract GMCChild is UUPSUpgrade, OwnableUDS, FxERC721EnumerableChild, GMCMarket {
    using ECDSA for bytes32;
    using LibString for uint256;
    using LibCrumbMap for mapping(uint256 => uint256);
    using LibEnumerableSet for Uint256Set;

    address public immutable vault;

    string public constant name = "Gangsta Mice City";
    string public constant symbol = "GMC";

    constructor(address fxChild, address vault_) FxERC721EnumerableChild(fxChild) {
        vault = vault_;
    }

    function init() external initializer {
        __Ownable_init();
    }

    /* ------------- view ------------- */

    function ownerOf(uint256 id) public view override(FxERC721Child, GMCMarket) returns (address) {
        return FxERC721Child.ownerOf(id);
    }

    function isAuthorized(address user, uint256 id) public view override returns (bool) {
        return ownerOf(id) == user || renterOf(id) == user;
    }

    function isAuthorizedUser(address user, uint256 id) public view returns (bool) {
        address renter = renterOf(id);

        // first check renter (active user), and only if 0, check owner
        return (renter != address(0)) ? user == renter : user == ownerOf(id);
    }

    function isBaron(uint256 id) public pure returns (bool) {
        return id >= 10_000;
    }

    function gangOf(uint256 id) public view returns (Gang gang) {
        if (isBaron(id)) {
            return Gang((id - 10_001) / 7);
        }

        uint256 gangEnc = s().gangMap.get(id - 1);

        // enum Gang has convention of Gang.NONE (= 4) being invalid
        // more natural in a mapping to assume 0 (unset) is invalid
        // that's why we're making converting 0 <=> 4 (Gang.None)
        if (gangEnc == 0) gang = Gang.NONE;
        else gang = Gang(gangEnc - 1);
    }

    function gangBalancesOf(address user) public view returns (uint256[3] memory balances) {
        uint256 numOwned = erc721BalanceOf(user);

        for (uint256 i; i < numOwned; ++i) {
            uint256 id = tokenOfOwnerByIndex(user, i);

            balances[uint8(gangOf(id))] += 1;
        }
    }

    function getName(uint256 id) external view returns (string memory) {
        return s().name[id];
    }

    function getShares(uint256 id) public pure returns (uint40) {
        if (isBaron(id)) return 1000;
        return 100;
    }

    function getPlayerName(address user) external view returns (string memory) {
        return s().playerName[user];
    }

    function tokenURI(uint256 id) public view returns (string memory) {
        return 
            bytes(s().baseURI).length == 0 
              ? s().unrevealedURI 
              : string.concat(s().baseURI, id.toString(), s().postFixURI); // prettier-ignore
    }

    /* ------------- external ------------- */

    function setName(uint256 id, string calldata name_) external {
        if (!isValidString(name_, 20)) revert InvalidName();
        if (ownerOf(id) != msg.sender) revert NotAuthorized();

        s().name[id] = name_;
    }

    function setPlayerName(string calldata name_) external {
        if (!isValidString(name_, 20)) revert InvalidName();

        s().playerName[msg.sender] = name_;
    }

    /* ------------- hooks ------------- */

    /// @dev these hooks are called by Polygon's PoS bridge
    /// extra care must be taken such that these calls never fail!
    /// Only called when `from != to` (3 cases):
    /// - `from` = 0
    /// - `to` = 0
    /// - `from`, `to` != 0
    function _afterIdRegistered(
        address from,
        address to,
        uint256 id
    ) internal override {
        super._afterIdRegistered(from, to, id);

        Gang gang = gangOf(id);

        // allow users to transfer the token, but
        // without adding any shares. These will be
        // added as soon as the gangs are known.
        if (gang != Gang.NONE) {
            uint40 shares = getShares(id);

            if (from != address(0)) {
                // make sure any active rental is cleaned up
                // so that shares invariant holds.
                // calls `_afterEndRent` if rental is active.
                _removeListingAndCleanUp(from, id);

                // @dev: this call seems like a danger point that could possibly
                // fail during fxPortal call. Fails when gangVault storage is reset.
                // try GangVault(vault).removeShares(from, uint256(gang), shares) {} catch {}
                GangVault(vault).removeShares(from, uint256(gang), shares);
            }

            if (to != address(0)) {
                GangVault(vault).addShares(to, uint256(gangOf(id)), shares);
            }
        }
    }

    function _afterStartRent(
        address owner,
        address renter,
        uint256 id,
        uint256 renterShares
    ) internal override {
        Gang gang = gangOf(id);

        if (gang == Gang.NONE) revert GangUnset();

        GangVault(vault).transferShares(owner, renter, uint256(gang), uint8(renterShares));

        // Mock a transfer
        emit Transfer(owner, renter, id);
    }

    function _afterEndRent(
        address owner,
        address renter,
        uint256 id,
        uint256 renterShares
    ) internal override {
        Gang gang = gangOf(id);

        if (gang == Gang.NONE) revert GangUnset();

        GangVault(vault).transferShares(renter, owner, uint256(gang), uint8(renterShares));

        emit Transfer(renter, owner, id);
    }

    /// @dev resets and re-calculates shares
    function _resyncShares() internal {
        uint256 idsLength = erc721BalanceOf(msg.sender);

        uint40[3] memory shares;

        for (uint256 i; i < idsLength; ++i) {
            uint256 id = tokenOfOwnerByIndex(msg.sender, i);

            _removeListingAndCleanUp(msg.sender, id);

            uint256 gang = uint256(gangOf(id));
            shares[gang] += getShares(id);
        }

        GangVault(vault).resetShares(msg.sender, shares);
    }

    /* ------------- owner ------------- */

    function resyncRentedIds(uint256[] calldata ids) external onlyOwner {
        for (uint256 i; i < ids.length; i++) {
            Offer storage offer = marketDS().offers[ids[i]];

            marketDS().rentedIds[offer.renter].add(ids[i]);
        }
    }

    function resyncRentedIds(address user) external onlyOwner {
        uint256[] memory ids = getRentedIds(user);

        uint256 length = ids.length;

        for (uint256 i; i < length; i++) {
            Offer storage offer = marketDS().offers[ids[i]];

            address renter = offer.renter;

            if (renter != user) {
                marketDS().rentedIds[user].remove(ids[i]);
                // marketDS().rentedIds[renter].add(ids[i]);
            }
        }
    }

    function resyncBarons(address[] calldata tos) external onlyOwner {
        uint256 baronId = 10_000;

        for (uint256 i; i < tos.length; i++) {
            if (++baronId > 10_021) revert GangstersAlreadyMinted();

            _registerId(tos[i], baronId);
        }
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        s().baseURI = uri;
    }

    function setPostFixURI(string calldata postFix) external onlyOwner {
        s().postFixURI = postFix;
    }

    function setUnrevealedURI(string calldata uri) external onlyOwner {
        s().unrevealedURI = uri;
    }

    function resyncId(address to, uint256 id) external onlyOwner {
        _registerId(to, id);
    }

    function resyncIds(address to, uint256[] calldata ids) external onlyOwner {
        _registerIds(to, ids);
    }

    function setGangsInChunks(uint256 chunkIndex, uint256 chunkData) external onlyOwner {
        if (chunkData == 0) return;
        if (s().gangMap.get32BytesChunk(chunkIndex) != 0) revert ChunkDataAlreadySet();

        s().gangMap.set32BytesChunk(chunkIndex, chunkData);

        uint256 id;
        uint256 gang;
        address owner;

        unchecked {
            for (uint256 i; i < 128; i++) {
                // ids start at 1
                id = (chunkIndex << 7) + i + 1; // << 7 == * 128
                gang = (chunkData >> (i << 1)) & 3;

                owner = ownerOf(id);
                if (gang != 0 && owner != address(0)) {
                    // storing gangs in crumbMap uses convention 0 = invalid, 1 = Yakuza, ....
                    // gangwar uses convention 0 = Yakuza, .... 4 = invalid
                    GangVault(vault).addShares(owner, gang - 1, getShares(id));
                }
            }
        }
    }

    function _authorizeUpgrade() internal override onlyOwner {}

    function _authorizeTunnelController() internal override onlyOwner {}
}

function isValidString(string calldata str, uint256 maxLen) pure returns (bool) {
    bytes memory b = bytes(str);

    if (b.length < 1 || b.length > maxLen || b[0] == 0x20 || b[b.length - 1] == 0x20) return false;

    bytes1 lastChar = b[0];

    bytes1 char;
    for (uint256 i; i < b.length; ++i) {
        char = b[i];

        if (
            (char > 0x60 && char < 0x7B) || //a-z
            (char > 0x40 && char < 0x5B) || //A-Z
            (char == 0x20 && lastChar != 0x20) || //space
            (char > 0x2F && char < 0x3A) //9-0
        ) {
            lastChar = char;
        } else {
            return false;
        }
    }

    return true;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Context} from "../utils/Context.sol";
import {Initializable} from "../utils/Initializable.sol";
import {EIP712PermitUDS} from "../auth/EIP712PermitUDS.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_ERC20 = keccak256("diamond.storage.erc20");

function s() pure returns (ERC20DS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_ERC20;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct ERC20DS {
    string name;
    string symbol;
    uint8 decimals;
    uint256 totalSupply;
    mapping(address => uint256) balanceOf;
    mapping(address => mapping(address => uint256)) allowance;
}

/// @title ERC20 (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate)
abstract contract ERC20UDS is Context, Initializable, EIP712PermitUDS {
    ERC20DS private __storageLayout; // storage layout for upgrade compatibility checks

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed operator, uint256 amount);

    /* ------------- init ------------- */

    function __ERC20_init(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) internal initializer {
        s().name = _name;
        s().symbol = _symbol;
        s().decimals = _decimals;
    }

    /* ------------- view ------------- */

    function name() external view virtual returns (string memory) {
        return s().name;
    }

    function symbol() external view virtual returns (string memory) {
        return s().symbol;
    }

    function decimals() external view virtual returns (uint8) {
        return s().decimals;
    }

    function totalSupply() external view virtual returns (uint256) {
        return s().totalSupply;
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        return s().balanceOf[owner];
    }

    function allowance(address owner, address operator) public view virtual returns (uint256) {
        return s().allowance[owner][operator];
    }

    /* ------------- public ------------- */

    function approve(address operator, uint256 amount) public virtual returns (bool) {
        s().allowance[_msgSender()][operator] = amount;

        emit Approval(_msgSender(), operator, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        s().balanceOf[_msgSender()] -= amount;

        unchecked {
            s().balanceOf[to] += amount;
        }

        emit Transfer(_msgSender(), to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = s().allowance[from][_msgSender()];

        if (allowed != type(uint256).max) s().allowance[from][_msgSender()] = allowed - amount;

        s().balanceOf[from] -= amount;

        unchecked {
            s().balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    // EIP-2612 permit
    function permit(
        address owner,
        address operator,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s_
    ) public virtual {
        _usePermit(owner, operator, value, deadline, v, r, s_);

        s().allowance[owner][operator] = value;

        emit Approval(owner, operator, value);
    }

    /* ------------- internal ------------- */

    function _mint(address to, uint256 amount) internal virtual {
        s().totalSupply += amount;

        unchecked {
            s().balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        s().balanceOf[from] -= amount;

        unchecked {
            s().totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Context} from "../utils/Context.sol";
import {Initializable} from "../utils/Initializable.sol";
import {EIP712PermitUDS} from "../auth/EIP712PermitUDS.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_ERC721 = keccak256("diamond.storage.erc721");

function s() pure returns (ERC721DS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_ERC721;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct ERC721DS {
    string name;
    string symbol;
    mapping(uint256 => address) ownerOf;
    mapping(address => uint256) balanceOf;
    mapping(uint256 => address) getApproved;
    mapping(address => mapping(address => bool)) isApprovedForAll;
}

// ------------- errors

error NonexistentToken();
error NonERC721Receiver();
error MintExistingToken();
error MintToZeroAddress();
error BalanceOfZeroAddress();
error TransferToZeroAddress();
error CallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();

/// @title ERC721 (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate)
/// @notice Integrates EIP712Permit
abstract contract ERC721UDS is Context, Initializable, EIP712PermitUDS {
    ERC721DS private __storageLayout; // storage layout for upgrade compatibility checks

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed operator, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /* ------------- init ------------- */

    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        s().name = name_;
        s().symbol = symbol_;
    }

    /* ------------- virtual ------------- */

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /* ------------- view ------------- */

    function name() external view virtual returns (string memory) {
        return s().name;
    }

    function symbol() external view virtual returns (string memory) {
        return s().symbol;
    }

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        if ((owner = s().ownerOf[id]) == address(0)) revert NonexistentToken();
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) revert BalanceOfZeroAddress();

        return s().balanceOf[owner];
    }

    function getApproved(uint256 id) public view returns (address) {
        return s().getApproved[id];
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return s().isApprovedForAll[owner][operator];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /* ------------- public ------------- */

    function approve(address operator, uint256 id) public virtual {
        address owner = s().ownerOf[id];

        if (_msgSender() != owner && !s().isApprovedForAll[owner][_msgSender()]) revert CallerNotOwnerNorApproved();

        s().getApproved[id] = operator;

        emit Approval(owner, operator, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        s().isApprovedForAll[_msgSender()][operator] = approved;

        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        if (to == address(0)) revert TransferToZeroAddress();
        if (from != s().ownerOf[id]) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            s().isApprovedForAll[from][_msgSender()] ||
            s().getApproved[id] == _msgSender());

        if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();

        unchecked {
            s().balanceOf[from]--;
            s().balanceOf[to]++;
        }

        s().ownerOf[id] = to;

        delete s().getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiver(to).onERC721Received(_msgSender(), from, id, "") !=
            ERC721TokenReceiver.onERC721Received.selector
        ) revert NonERC721Receiver();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiver(to).onERC721Received(_msgSender(), from, id, data) !=
            ERC721TokenReceiver.onERC721Received.selector
        ) revert NonERC721Receiver();
    }

    // EIP-4494 permit; differs from the current EIP
    function permit(
        address owner,
        address operator,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s_
    ) public virtual {
        _usePermit(owner, operator, 1, deadline, v, r, s_);

        s().isApprovedForAll[owner][operator] = true;

        emit ApprovalForAll(owner, operator, true);
    }

    /* ------------- internal ------------- */

    function _mint(address to, uint256 id) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (s().ownerOf[id] != address(0)) revert MintExistingToken();

        unchecked {
            s().balanceOf[to]++;
        }

        s().ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = s().ownerOf[id];

        if (owner == address(0)) revert NonexistentToken();

        unchecked {
            s().balanceOf[owner]--;
        }

        delete s().ownerOf[id];
        delete s().getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiver(to).onERC721Received(_msgSender(), address(0), id, "") !=
            ERC721TokenReceiver.onERC721Received.selector
        ) revert NonERC721Receiver();
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiver(to).onERC721Received(_msgSender(), address(0), id, data) !=
            ERC721TokenReceiver.onERC721Received.selector
        ) revert NonERC721Receiver();
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Context} from "../utils/Context.sol";
import {Initializable} from "../utils/Initializable.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_OWNABLE = keccak256("diamond.storage.ownable");

function s() pure returns (OwnableDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_OWNABLE;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct OwnableDS {
    address owner;
}

// ------------- errors

error CallerNotOwner();

/// @title Ownable (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @dev Requires `__Ownable_init` to be called in proxy
abstract contract OwnableUDS is Context, Initializable {
    OwnableDS private __storageLayout; // storage layout for upgrade compatibility checks

    event OwnerChanged(address oldOwner, address newOwner);

    function __Ownable_init() internal initializer {
        s().owner = _msgSender();
    }

    /* ------------- external ------------- */

    function owner() public view returns (address) {
        return s().owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        s().owner = newOwner;

        emit OwnerChanged(_msgSender(), newOwner);
    }

    /* ------------- modifier ------------- */

    modifier onlyOwner() {
        if (_msgSender() != s().owner) revert CallerNotOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1967, ERC1967_PROXY_STORAGE_SLOT} from "./ERC1967Proxy.sol";

// ------------- errors

error OnlyProxyCallAllowed();
error DelegateCallNotAllowed();

/// @title Minimal UUPSUpgrade
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract UUPSUpgrade is ERC1967 {
    address private immutable __implementation = address(this);

    /* ------------- external ------------- */

    function upgradeToAndCall(address logic, bytes calldata data) external virtual {
        _authorizeUpgrade();
        _upgradeToAndCall(logic, data);
    }

    /* ------------- view ------------- */

    function proxiableUUID() external view virtual returns (bytes32) {
        if (address(this) != __implementation) revert DelegateCallNotAllowed();

        return ERC1967_PROXY_STORAGE_SLOT;
    }

    /* ------------- virtual ------------- */

    function _authorizeUpgrade() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Context} from "../utils/Context.sol";
import {Initializable} from "../utils/Initializable.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_ACCESS_CONTROL = keccak256("diamond.storage.access.control");

function s() pure returns (AccessControlDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_ACCESS_CONTROL;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct AccessControlDS {
    mapping(bytes32 => RoleData) roles;
}

struct RoleData {
    bytes32 adminRole;
    mapping(address => bool) members;
}

// ------------- errors

error NotAuthorized();
error RenounceForCallerOnly();

/// @title AccessControl (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts)
/// @dev Requires `__AccessControl_init` to be called in proxy
abstract contract AccessControlUDS is Context, Initializable {
    AccessControlDS private __storageLayout; // storage layout for upgrade compatibility checks

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /* ------------- init ------------- */

    function __AccessControl_init() internal initializer {
        s().roles[DEFAULT_ADMIN_ROLE].members[_msgSender()] = true;

        emit RoleGranted(DEFAULT_ADMIN_ROLE, _msgSender(), _msgSender());
    }

    /* ------------- view ------------- */

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x7965db0b; // ERC165 Interface ID for AccessControl
    }

    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return s().roles[role].members[account];
    }

    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return s().roles[role].adminRole;
    }

    /* ------------- public ------------- */

    function grantRole(bytes32 role, address account) public virtual {
        if (!hasRole(getRoleAdmin(role), _msgSender())) revert NotAuthorized();

        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual {
        if (!hasRole(getRoleAdmin(role), _msgSender())) revert NotAuthorized();

        _revokeRole(role, account);
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) public virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);

        if (!hasRole(previousAdminRole, _msgSender())) revert NotAuthorized();

        _setRoleAdmin(role, adminRole);
    }

    function renounceRole(bytes32 role) public virtual {
        s().roles[role].members[_msgSender()] = false;

        emit RoleRevoked(role, _msgSender(), _msgSender());
    }

    /* ------------- internal ------------- */

    function _grantRole(bytes32 role, address account) internal virtual {
        s().roles[role].members[account] = true;

        emit RoleGranted(role, account, _msgSender());
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
        s().roles[role].members[account] = false;

        emit RoleRevoked(role, account, _msgSender());
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        s().roles[role].adminRole = adminRole;

        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
    }

    /* ------------- modifier ------------- */

    modifier onlyRole(bytes32 role) {
        if (!hasRole(role, _msgSender())) revert NotAuthorized();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20UDS, s as erc20ds} from "../ERC20UDS.sol";

/// @title ERC20Burnable (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @notice Allows for burning ERC20 tokens
abstract contract ERC20BurnableUDS is ERC20UDS {
    /* ------------- public ------------- */

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address from, uint256 amount) public virtual {
        if (_msgSender() != from) {
            uint256 allowed = erc20ds().allowance[from][_msgSender()];

            if (allowed != type(uint256).max) erc20ds().allowance[from][_msgSender()] = allowed - amount;
        }

        _burn(from, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

using LibCrumbMap for LibCrumbMap.CrumbMap;


/// @notice Efficient crumb map library for mapping integers to crumbs.
/// @author phaze (https://github.com/0xPhaze)
/// @author adapted from Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibBytemap.sol)
library LibCrumbMap {
    struct CrumbMap {
        mapping(uint256 => uint256) map;
    }

    /* ------------- CrumbMap ------------- */

    function get(CrumbMap storage crumbMap, uint256 index) internal view returns (uint256 result) {
        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, shr(7, index))
            result := and(shr(shl(1, and(index, 0x7f)), sload(keccak256(0x00, 0x20))), 0x03)
        }
    }

    function get32BytesChunk(CrumbMap storage crumbMap, uint256 bytesIndex) internal view returns (uint256 result) {
        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, bytesIndex)
            result := sload(keccak256(0x00, 0x20))
        }
    }

    function set32BytesChunk(
        CrumbMap storage crumbMap,
        uint256 bytesIndex,
        uint256 value
    ) internal {
        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, bytesIndex)
            sstore(keccak256(0x00, 0x20), value)
        }
    }

    function set(
        CrumbMap storage crumbMap,
        uint256 index,
        uint256 value
    ) internal {
        require(value < 4);

        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, shr(7, index))
            let storageSlot := keccak256(0x00, 0x20)
            let shift := shl(1, and(index, 0x7f))
            // Unset crumb at index and store.
            let chunkValue := and(sload(storageSlot), not(shl(shift, 0x03)))
            // Set crumb to `value` at index and store.
            chunkValue := or(chunkValue, shl(shift, value))
            sstore(storageSlot, chunkValue)
        }
    }

    /* ------------- mapping(uint256 => uint256) ------------- */

    function get(mapping(uint256 => uint256) storage crumbMap, uint256 index) internal view returns (uint256 result) {
        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, shr(7, index))
            result := and(shr(shl(1, and(index, 0x7f)), sload(keccak256(0x00, 0x20))), 0x03)
        }
    }

    function get32BytesChunk(mapping(uint256 => uint256) storage crumbMap, uint256 bytesIndex) internal view returns (uint256 result) {
        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, bytesIndex)
            result := sload(keccak256(0x00, 0x20))
        }
    }

    function set32BytesChunk(
        mapping(uint256 => uint256) storage crumbMap,
        uint256 bytesIndex,
        uint256 value
    ) internal {
        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, bytesIndex)
            sstore(keccak256(0x00, 0x20), value)
        }
    }

    function set(
        mapping(uint256 => uint256) storage crumbMap,
        uint256 index,
        uint256 value
    ) internal {
        require(value < 4);

        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, shr(7, index))
            let storageSlot := keccak256(0x00, 0x20)
            let shift := shl(1, and(index, 0x7f))
            // Unset crumb at index and store.
            let chunkValue := and(sload(storageSlot), not(shl(shift, 0x03)))
            // Set crumb to `value` at index and store.
            chunkValue := or(chunkValue, shl(shift, value))
            sstore(storageSlot, chunkValue)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721UDS} from "UDS/tokens/ERC721UDS.sol";
import {OwnableUDS} from "UDS/auth/OwnableUDS.sol";
import {UUPSUpgrade} from "UDS/proxy/UUPSUpgrade.sol";
import {LibEnumerableSet, Uint256Set} from "UDS/lib/LibEnumerableSet.sol";

uint256 constant RENTAL_ACCEPTANCE_MINIMUM_TIME_DELAY = 1 hours;

// ------------- storage

bytes32 constant DIAMOND_STORAGE_GMC_MARKET = keccak256("diamond.storage.gmc.market.v2");

struct Offer {
    address renter;
    uint8 renterShare;
    bool expiresOnAcceptance;
}

struct GangMarketDS {
    mapping(uint256 => Offer) offers;
    mapping(address => uint256) lastRentalAcceptance;
    // `listedIds` is stuck in a mapping at [0],
    // in order to avoid nested structs.
    mapping(uint256 => Uint256Set) listedIds;
    mapping(address => Uint256Set) rentedIds;
}

function s() pure returns (GangMarketDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_GMC_MARKET;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

// ------------- error

error InvalidOffer();
error ActiveRental();
error AlreadyListed();
error NotAuthorized();
error InvalidRenterShare();
error OfferAlreadyAccepted();
error MinimumTimeDelayNotReached();

/// @title Gangsta Mice City Market
/// @author phaze (https://github.com/0xPhaze)
abstract contract GMCMarket {
    using LibEnumerableSet for Uint256Set;

    GangMarketDS private __storageLayout;

    /* ------------- virtual ------------- */

    function ownerOf(uint256 id) public view virtual returns (address);

    function isAuthorized(address user, uint256 id) public view virtual returns (bool);

    /* ------------- view ------------- */

    function renterOf(uint256 id) public view virtual returns (address) {
        return s().offers[id].renter;
    }

    function getListedOfferByIndex(uint256 index) public view returns (uint256, Offer memory) {
        uint256 id = s().listedIds[0].at(index);
        return (id, s().offers[id]);
    }

    function getListedOffersIds() public view returns (uint256[] memory) {
        return s().listedIds[0].values();
    }

    function numListedOffers() public view returns (uint256) {
        return s().listedIds[0].length();
    }

    function getActiveOffer(uint256 id) public view returns (Offer memory) {
        return s().offers[id];
    }

    function getRentedIds(address user) public view returns (uint256[] memory) {
        return s().rentedIds[user].values();
    }

    function isListed(uint256 id) public view returns (bool) {
        return s().listedIds[0].includes(id);
    }

    /* ------------- external ------------- */

    function listOffer(uint256[] calldata ids, Offer[] calldata offers) external {
        for (uint256 i; i < ids.length; i++) {
            uint256 id = ids[i];

            Offer calldata offer = offers[i];
            uint256 renterShare = offer.renterShare;
            // address currentRenter = offer.renter;

            address owner = ownerOf(id);

            if (id > 10_000) revert NotAuthorized();
            if (owner != msg.sender) revert NotAuthorized();
            if (offer.renter == msg.sender) revert InvalidOffer();
            // if (currentRenter != address(0)) revert ActiveRental();
            if (renterShare < 30 || 100 < renterShare) revert InvalidRenterShare();

            // note: this prevents ids being "rented" out
            // multiple times, because they need to be delisted
            // and _cleanUp needs to run first; could also check
            // active rentals and clean up
            bool added = s().listedIds[0].add(id);

            if (!added) revert AlreadyListed();

            // direct offer to renter
            if (offer.renter != address(0)) {
                s().rentedIds[offer.renter].add(id);

                _afterStartRent(owner, offer.renter, id, renterShare);
            }

            // three steps to "accepting an offer":
            // - set `address offer.renter`
            // - add id to `rentedIds[offer.renter]` enumeration
            // - call `_afterStartRent` to transfer shares
            s().offers[id] = offers[i];
        }
    }

    function acceptOffer(uint256 id) external {
        Offer storage offer = s().offers[id];

        if (!isListed(id)) revert InvalidOffer();
        if (offer.renterShare == 0) revert InvalidOffer();
        if (offer.renter != address(0)) revert OfferAlreadyAccepted();
        if (block.timestamp - s().lastRentalAcceptance[msg.sender] < RENTAL_ACCEPTANCE_MINIMUM_TIME_DELAY) {
            revert MinimumTimeDelayNotReached();
        }

        offer.renter = msg.sender;

        s().rentedIds[msg.sender].add(id);
        s().lastRentalAcceptance[msg.sender] = block.timestamp;

        _afterStartRent(ownerOf(id), msg.sender, id, offer.renterShare);
    }

    function deleteOffer(uint256[] calldata ids) external {
        for (uint256 i; i < ids.length; i++) {
            if (ownerOf(ids[i]) != msg.sender) revert NotAuthorized();

            _removeListingAndCleanUp(msg.sender, ids[i]);
        }
    }

    function endRent(uint256[] calldata ids) external {
        for (uint256 i; i < ids.length; ++i) {
            uint256 id = ids[i];

            if (!isAuthorized(msg.sender, id)) revert NotAuthorized();

            Offer storage offer = s().offers[id];

            uint256 renterShare = offer.renterShare;
            bool expires = offer.expiresOnAcceptance;

            // offer has not been accepted / is invalid
            if (offer.renter == address(0)) revert InvalidOffer();

            _removeListingAndCleanUp(ownerOf(id), id);

            // note: make this more robust
            if (!expires) {
                offer.renterShare = uint8(renterShare);
            }
        }
    }

    function _removeListingAndCleanUp(address owner, uint256 id) internal {
        if (s().listedIds[0].remove(id)) {
            Offer storage offer = s().offers[id];

            address renter = offer.renter;
            uint256 renterShare = offer.renterShare;

            if (renter != address(0)) {
                s().rentedIds[renter].remove(id);

                _afterEndRent(owner, renter, id, renterShare);
            }
        }

        delete s().offers[id];
    }

    /* ------------- hooks ------------- */

    function _afterStartRent(
        address owner,
        address renter,
        uint256 id,
        uint256 renterShares
    ) internal virtual {}

    function _afterEndRent(
        address owner,
        address renter,
        uint256 id,
        uint256 renterShares
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBaseChildTunnel} from "./base/FxBaseChildTunnel.sol";
import {REGISTER_ERC721_IDS_SELECTOR} from "./FxERC721Root.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_FX_ERC721_CHILD_TUNNEL = keccak256("diamond.storage.fx.erc721.child.tunnel");

function s() pure returns (FxERC721ChildRegistryDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_FX_ERC721_CHILD_TUNNEL;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct FxERC721ChildRegistryDS {
    mapping(uint256 => address) ownerOf;
}

// ------------- error

error InvalidSelector();

/// @title ERC721 FxChildTunnel
/// @author phaze (https://github.com/0xPhaze/fx-contracts)
abstract contract FxERC721Child is FxBaseChildTunnel {
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event StateResync(address oldOwner, address newOwner, uint256 id);

    constructor(address fxChild) FxBaseChildTunnel(fxChild) {}

    /* ------------- virtual ------------- */

    function _authorizeTunnelController() internal virtual override;

    /* ------------- view ------------- */

    function ownerOf(uint256 id) public view virtual returns (address) {
        return s().ownerOf[id];
    }

    /* ------------- internal ------------- */

    // @note doesn't need to validate sender, since this already happens in FxBase
    function _processMessageFromRoot(
        uint256,
        address,
        bytes calldata message
    ) internal virtual override {
        bytes4 selector = bytes4(message);

        if (selector != REGISTER_ERC721_IDS_SELECTOR) revert InvalidSelector();

        address to = address(uint160(uint256(bytes32(message[4:36]))));

        uint256[] calldata ids;
        // abi-decode `ids` directly in calldata.
        assembly {
            // Skip bytes4 selector + bytes32 encoded address
            // starting from message's offset in calldata
            // to get the relative offset of the uint256[] encoded array's size.
            let idsLenOffset := add(add(message.offset, 0x04), calldataload(add(message.offset, 0x24)))
            ids.length := calldataload(idsLenOffset)
            ids.offset := add(idsLenOffset, 0x20)
        }

        _registerIds(to, ids);
    }

    function _registerIds(address to, uint256[] calldata ids) internal virtual {
        for (uint256 i; i < ids.length; ++i) {
            _registerId(to, ids[i]);
        }
    }

    function _registerId(address to, uint256 id) internal virtual {
        address from = s().ownerOf[id];

        // Should normally not happen unless re-syncing.
        if (from == to) {
            emit StateResync(from, to, id);
        } else {
            // Registering id, but it is already owned by someone else..
            // This should not happen, because deregistering on L1 should
            // send message to burn first, or require proof of burn on L2.
            // Though could happen if an explicit re-sync is triggered.
            if (from != address(0) && to != address(0)) {
                emit StateResync(from, to, id);
            }

            s().ownerOf[id] = to;

            emit Transfer(from, to, id);

            _afterIdRegistered(from, to, id);
        }
    }

    /* ------------- hooks ------------- */

    function _afterIdRegistered(
        address from,
        address to,
        uint256 id
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxERC721Child} from "../FxERC721Child.sol";
import {LibEnumerableSet, Uint256Set} from "UDS/lib/LibEnumerableSet.sol";

import "forge-std/console.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_FX_ERC721_ENUMERABLE_CHILD = keccak256("diamond.storage.fx.erc721.enumerable.child");

function s() pure returns (FxERC721EnumerableChildDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_FX_ERC721_ENUMERABLE_CHILD;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct FxERC721EnumerableChildDS {
    mapping(address => Uint256Set) ownedIds;
}

abstract contract FxERC721EnumerableChild is FxERC721Child {
    using LibEnumerableSet for Uint256Set;

    constructor(address fxChild) FxERC721Child(fxChild) {}

    /* ------------- virtual ------------- */

    function _authorizeTunnelController() internal virtual override;

    /* ------------- public ------------- */

    function getOwnedIds(address user) public view virtual returns (uint256[] memory) {
        return s().ownedIds[user].values();
    }

    function erc721BalanceOf(address user) public view virtual returns (uint256) {
        return s().ownedIds[user].length();
    }

    function userOwnsId(address user, uint256 id) public view virtual returns (bool) {
        return s().ownedIds[user].includes(id);
    }

    function tokenOfOwnerByIndex(address user, uint256 index) public view virtual returns (uint256) {
        return s().ownedIds[user].at(index);
    }

    /* ------------- hooks ------------- */

    function _afterIdRegistered(
        address from,
        address to,
        uint256 id
    ) internal virtual override {
        if (from != address(0)) s().ownedIds[from].remove(id);
        if (to != address(0)) s().ownedIds[to].add(id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Bytes32Set {
    bytes32[] _values;
    mapping(bytes32 => uint256) _indices;
}

struct Uint256Set {
    uint256[] _values;
    mapping(uint256 => uint256) _indices;
}

struct AddressSet {
    address[] _values;
    mapping(address => uint256) _indices;
}

/// @title EnumerableSet
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts)
/// @dev usage: `using LibEnumerableSet for Uint256Set;`
library LibEnumerableSet {
    // ---------------------------------------------------------------------
    // Bytes32Set
    // ---------------------------------------------------------------------

    function add(Bytes32Set storage set, bytes32 val) internal returns (bool) {
        uint256 setIndex = set._indices[val];
        if (setIndex != 0) return false;

        set._values.push(val);
        set._indices[val] = set._values.length;

        return true;
    }

    function remove(Bytes32Set storage set, bytes32 val) internal returns (bool) {
        uint256 indexToReplace = set._indices[val];
        if (indexToReplace == 0) return false;

        uint256 lastIndex = set._values.length;

        if (indexToReplace != lastIndex) {
            unchecked {
                // lastIndex != 0,
                // as otherwise .length would be 0
                // and indexToReplace would be 0
                bytes32 lastValue = set._values[lastIndex - 1];

                set._values[indexToReplace - 1] = lastValue;
                set._indices[lastValue] = indexToReplace;
            }
        }

        set._indices[val] = 0;
        set._values.pop();

        return true;
    }

    function includes(Bytes32Set storage set, bytes32 val) internal view returns (bool) {
        return set._indices[val] != 0;
    }

    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return set._values;
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return set._values[index];
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    // ---------------------------------------------------------------------
    // Uint256Set
    // ---------------------------------------------------------------------

    function add(Uint256Set storage set, uint256 val) internal returns (bool) {
        Bytes32Set storage set_;
        bytes32 val_;
        assembly {
            set_.slot := set.slot
            val_ := val
        }
        return add(set_, val_);
    }

    function remove(Uint256Set storage set, uint256 val) internal returns (bool) {
        Bytes32Set storage set_;
        bytes32 val_;
        assembly {
            set_.slot := set.slot
            val_ := val
        }
        return remove(set_, val_);
    }

    function includes(Uint256Set storage set, uint256 val) internal view returns (bool) {
        return set._indices[val] != 0;
    }

    function values(Uint256Set storage set) internal view returns (uint256[] memory) {
        return set._values;
    }

    function at(Uint256Set storage set, uint256 index) internal view returns (uint256) {
        return set._values[index];
    }

    function length(Uint256Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    // ---------------------------------------------------------------------
    // AddressSet
    // ---------------------------------------------------------------------

    function add(AddressSet storage set, address val) internal returns (bool) {
        Bytes32Set storage set_;
        bytes32 val_;
        assembly {
            set_.slot := set.slot
            val_ := val
        }
        return add(set_, val_);
    }

    function remove(AddressSet storage set, address val) internal returns (bool) {
        Bytes32Set storage set_;
        bytes32 val_;
        assembly {
            set_.slot := set.slot
            val_ := shr(96, shl(96, val)) // make sure no "dirty" bits remain
        }
        return remove(set_, val_);
    }

    function includes(AddressSet storage set, address val) internal view returns (bool) {
        return set._indices[val] != 0;
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return set._values[index];
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        return set._values;
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return set._values.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Gas optimized ECDSA wrapper.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ECDSA.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ECDSA.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol)
library ECDSA {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The number which `s` must not exceed in order for
    /// the signature to be non-malleable.
    bytes32 private constant _MALLEABILITY_THRESHOLD =
        0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    RECOVERY OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the `signature`.
    ///
    /// This function does NOT accept EIP-2098 short form signatures.
    /// Use `recover(bytes32 hash, bytes32 r, bytes32 vs)` for EIP-2098
    /// short form signatures instead.
    ///
    /// WARNING!
    /// The `result` will be the zero address upon recovery failure.
    /// As such, it is extremely important to ensure that the address which
    /// the `result` is compared against is never zero.
    function recover(bytes32 hash, bytes calldata signature) internal view returns (address result) {
        assembly {
            if eq(signature.length, 65) {
                // Copy the free memory pointer so that we can restore it later.
                let m := mload(0x40)
                // Directly copy `r` and `s` from the calldata.
                calldatacopy(0x40, signature.offset, 0x40)

                // If `s` in lower half order, such that the signature is not malleable.
                if iszero(gt(mload(0x60), _MALLEABILITY_THRESHOLD)) {
                    mstore(0x00, hash)
                    // Compute `v` and store it in the scratch space.
                    mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40))))
                    pop(
                        staticcall(
                            gas(), // Amount of gas left for the transaction.
                            0x01, // Address of `ecrecover`.
                            0x00, // Start of input.
                            0x80, // Size of input.
                            0x40, // Start of output.
                            0x20 // Size of output.
                        )
                    )
                    // Restore the zero slot.
                    mstore(0x60, 0)
                    // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                    result := mload(sub(0x60, returndatasize()))
                }
                // Restore the free memory pointer.
                mstore(0x40, m)
            }
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the EIP-2098 short form signature defined by `r` and `vs`.
    ///
    /// This function only accepts EIP-2098 short form signatures.
    /// See: https://eips.ethereum.org/EIPS/eip-2098
    ///
    /// To be honest, I do not recommend using EIP-2098 signatures
    /// for simplicity, performance, and security reasons. Most if not
    /// all clients support traditional non EIP-2098 signatures by default.
    /// As such, this method is intentionally not fully inlined.
    /// It is merely included for completeness.
    ///
    /// WARNING!
    /// The `result` will be the zero address upon recovery failure.
    /// As such, it is extremely important to ensure that the address which
    /// the `result` is compared against is never zero.
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal view returns (address result) {
        uint8 v;
        bytes32 s;
        assembly {
            s := shr(1, shl(1, vs))
            v := add(shr(255, vs), 27)
        }
        result = recover(hash, v, r, s);
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the signature defined by `v`, `r`, `s`.
    ///
    /// WARNING!
    /// The `result` will be the zero address upon recovery failure.
    /// As such, it is extremely important to ensure that the address which
    /// the `result` is compared against is never zero.
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address result) {
        assembly {
            // Copy the free memory pointer so that we can restore it later.
            let m := mload(0x40)

            // If `s` in lower half order, such that the signature is not malleable.
            if iszero(gt(s, _MALLEABILITY_THRESHOLD)) {
                mstore(0x00, hash)
                mstore(0x20, v)
                mstore(0x40, r)
                mstore(0x60, s)
                pop(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        0x01, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x40, // Start of output.
                        0x20 // Size of output.
                    )
                )
                // Restore the zero slot.
                mstore(0x60, 0)
                // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                result := mload(sub(0x60, returndatasize()))
            }
            // Restore the free memory pointer.
            mstore(0x40, m)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HASHING OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an Ethereum Signed Message, created from a `hash`.
    /// This produces a hash corresponding to the one signed with the
    /// [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
    /// JSON-RPC method as part of EIP-191.
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 result) {
        assembly {
            // Store into scratch space for keccak256.
            mstore(0x20, hash)
            mstore(0x00, "\x00\x00\x00\x00\x19Ethereum Signed Message:\n32")
            // 0x40 - 0x04 = 0x3c
            result := keccak256(0x04, 0x3c)
        }
    }

    /// @dev Returns an Ethereum Signed Message, created from `s`.
    /// This produces a hash corresponding to the one signed with the
    /// [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
    /// JSON-RPC method as part of EIP-191.
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32 result) {
        assembly {
            // We need at most 128 bytes for Ethereum signed message header.
            // The max length of the ASCII reprenstation of a uint256 is 78 bytes.
            // The length of "\x19Ethereum Signed Message:\n" is 26 bytes (i.e. 0x1a).
            // The next multiple of 32 above 78 + 26 is 128 (i.e. 0x80).

            // Instead of allocating, we temporarily copy the 128 bytes before the
            // start of `s` data to some variables.
            let m3 := mload(sub(s, 0x60))
            let m2 := mload(sub(s, 0x40))
            let m1 := mload(sub(s, 0x20))
            // The length of `s` is in bytes.
            let sLength := mload(s)

            let ptr := add(s, 0x20)

            // `end` marks the end of the memory which we will compute the keccak256 of.
            let end := add(ptr, sLength)

            // Convert the length of the bytes to ASCII decimal representation
            // and store it into the memory.
            // prettier-ignore
            for { let temp := sLength } 1 {} {
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            // Copy the header over to the memory.
            mstore(sub(ptr, 0x20), "\x00\x00\x00\x00\x00\x00\x19Ethereum Signed Message:\n")
            // Compute the keccak256 of the memory.
            result := keccak256(sub(ptr, 0x1a), sub(end, sub(ptr, 0x1a)))

            // Restore the previous memory.
            mstore(s, sLength)
            mstore(sub(s, 0x20), m1)
            mstore(sub(s, 0x40), m2)
            mstore(sub(s, 0x60), m3)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for converting numbers into strings and other string operations.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibString.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
library LibString {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The `length` of the output is too small to contain all the hex digits.
    error HexLengthInsufficient();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The constant returned when the `search` is not found in the string.
    uint256 internal constant NOT_FOUND = uint256(int256(-1));

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     DECIMAL OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the base 10 decimal representation of `value`.
    function toString(uint256 value) internal pure returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   HEXADECIMAL OPERATIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the hexadecimal representation of `value`,
    /// left-padded to an input length of `length` bytes.
    /// The output is prefixed with "0x" encoded using 2 hexadecimal digits per byte,
    /// giving a total length of `length * 2 + 2` bytes.
    /// Reverts if `length` is too small for the output to contain all the digits.
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the trailing zeros padding, `length * 2` bytes
            // for the digits, 0x02 bytes for the prefix, and 0x20 bytes for the length.
            // We add 0x20 to the total and round down to a multiple of 0x20.
            // (0x20 + 0x20 + 0x02 + 0x20) = 0x62.
            let m := add(start, and(add(shl(1, length), 0x62), not(0x1f)))
            // Allocate the memory.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end to calculate the length later.
            let end := str
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            let temp := value
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for {} 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                length := sub(length, 1)
                // prettier-ignore
                if iszero(length) { break }
            }

            if temp {
                // Store the function selector of `HexLengthInsufficient()`.
                mstore(0x00, 0x2194895a)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Compute the string's length.
            let strLength := add(sub(end, str), 2)
            // Move the pointer and write the "0x" prefix.
            str := sub(str, 0x20)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, strLength)
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is prefixed with "0x" and encoded using 2 hexadecimal digits per byte.
    /// As address are 20 bytes long, the output will left-padded to have
    /// a length of `20 * 2 + 2` bytes.
    function toHexString(uint256 value) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the trailing zeros padding, 0x20 bytes for the length,
            // 0x02 bytes for the prefix, and 0x40 bytes for the digits.
            // The next multiple of 0x20 above (0x20 + 0x20 + 0x02 + 0x40) is 0xa0.
            let m := add(start, 0xa0)
            // Allocate the memory.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end to calculate the length later.
            let end := str
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute the string's length.
            let strLength := add(sub(end, str), 2)
            // Move the pointer and write the "0x" prefix.
            str := sub(str, 0x20)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, strLength)
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is prefixed with "0x" and encoded using 2 hexadecimal digits per byte.
    function toHexString(address value) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the length, 0x02 bytes for the prefix,
            // and 0x28 bytes for the digits.
            // The next multiple of 0x20 above (0x20 + 0x02 + 0x28) is 0x60.
            str := add(start, 0x60)

            // Allocate the memory.
            mstore(0x40, str)
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            let length := 20
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                length := sub(length, 1)
                // prettier-ignore
                if iszero(length) { break }
            }

            // Move the pointer and write the "0x" prefix.
            str := sub(str, 32)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, 42)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   OTHER STRING OPERATIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // For performance and bytecode compactness, all indices of the following operations
    // are byte (ASCII) offsets, not UTF character offsets.

    /// @dev Returns `subject` all occurances of `search` replaced with `replacement`.
    function replace(
        string memory subject,
        string memory search,
        string memory replacement
    ) internal pure returns (string memory result) {
        assembly {
            let subjectLength := mload(subject)
            let searchLength := mload(search)
            let replacementLength := mload(replacement)

            subject := add(subject, 0x20)
            search := add(search, 0x20)
            replacement := add(replacement, 0x20)
            result := add(mload(0x40), 0x20)

            let subjectEnd := add(subject, subjectLength)
            if iszero(gt(searchLength, subjectLength)) {
                let subjectSearchEnd := add(sub(subjectEnd, searchLength), 1)
                let h := 0
                if iszero(lt(searchLength, 32)) {
                    h := keccak256(search, searchLength)
                }
                let m := shl(3, sub(32, and(searchLength, 31)))
                let s := mload(search)
                // prettier-ignore
                for {} 1 {} {
                    let t := mload(subject)
                    // Whether the first `searchLength % 32` bytes of 
                    // `subject` and `search` matches.
                    if iszero(shr(m, xor(t, s))) {
                        if h {
                            if iszero(eq(keccak256(subject, searchLength), h)) {
                                mstore(result, t)
                                result := add(result, 1)
                                subject := add(subject, 1)
                                // prettier-ignore
                                if iszero(lt(subject, subjectSearchEnd)) { break }
                                continue
                            }
                        }
                        // Copy the `replacement` one word at a time.
                        // prettier-ignore
                        for { let o := 0 } 1 {} {
                            mstore(add(result, o), mload(add(replacement, o)))
                            o := add(o, 0x20)
                            // prettier-ignore
                            if iszero(lt(o, replacementLength)) { break }
                        }
                        result := add(result, replacementLength)
                        subject := add(subject, searchLength)
                        if searchLength {
                            // prettier-ignore
                            if iszero(lt(subject, subjectSearchEnd)) { break }
                            continue
                        }
                    }
                    mstore(result, t)
                    result := add(result, 1)
                    subject := add(subject, 1)
                    // prettier-ignore
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
            }

            let resultRemainder := result
            result := add(mload(0x40), 0x20)
            let k := add(sub(resultRemainder, result), sub(subjectEnd, subject))
            // Copy the rest of the string one word at a time.
            // prettier-ignore
            for {} lt(subject, subjectEnd) {} {
                mstore(resultRemainder, mload(subject))
                resultRemainder := add(resultRemainder, 0x20)
                subject := add(subject, 0x20)
            }
            result := sub(result, 0x20)
            // Zeroize the slot after the string.
            let last := add(add(result, 0x20), k)
            mstore(last, 0)
            // Allocate memory for the length and the bytes,
            // rounded up to a multiple of 32.
            mstore(0x40, and(add(last, 31), not(31)))
            // Store the length of the result.
            mstore(result, k)
        }
    }

    /// @dev Returns the byte index of the first location of `search` in `subject`,
    /// searching from left to right, starting from `from`.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function indexOf(
        string memory subject,
        string memory search,
        uint256 from
    ) internal pure returns (uint256 result) {
        assembly {
            // prettier-ignore
            for { let subjectLength := mload(subject) } 1 {} {
                if iszero(mload(search)) {
                    // `result = min(from, subjectLength)`.
                    result := xor(from, mul(xor(from, subjectLength), lt(subjectLength, from)))
                    break
                }
                let searchLength := mload(search)
                let subjectStart := add(subject, 0x20)    
                
                result := not(0) // Initialize to `NOT_FOUND`.

                subject := add(subjectStart, from)
                let subjectSearchEnd := add(sub(add(subjectStart, subjectLength), searchLength), 1)

                let m := shl(3, sub(32, and(searchLength, 31)))
                let s := mload(add(search, 0x20))

                // prettier-ignore
                if iszero(lt(subject, subjectSearchEnd)) { break }

                if iszero(lt(searchLength, 32)) {
                    // prettier-ignore
                    for { let h := keccak256(add(search, 0x20), searchLength) } 1 {} {
                        if iszero(shr(m, xor(mload(subject), s))) {
                            if eq(keccak256(subject, searchLength), h) {
                                result := sub(subject, subjectStart)
                                break
                            }
                        }
                        subject := add(subject, 1)
                        // prettier-ignore
                        if iszero(lt(subject, subjectSearchEnd)) { break }
                    }
                    break
                }
                // prettier-ignore
                for {} 1 {} {
                    if iszero(shr(m, xor(mload(subject), s))) {
                        result := sub(subject, subjectStart)
                        break
                    }
                    subject := add(subject, 1)
                    // prettier-ignore
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
                break
            }
        }
    }

    /// @dev Returns the byte index of the first location of `search` in `subject`,
    /// searching from left to right.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function indexOf(string memory subject, string memory search) internal pure returns (uint256 result) {
        result = indexOf(subject, search, 0);
    }

    /// @dev Returns the byte index of the first location of `search` in `subject`,
    /// searching from right to left, starting from `from`.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function lastIndexOf(
        string memory subject,
        string memory search,
        uint256 from
    ) internal pure returns (uint256 result) {
        assembly {
            // prettier-ignore
            for {} 1 {} {
                let searchLength := mload(search)
                let fromMax := sub(mload(subject), searchLength)
                if iszero(gt(fromMax, from)) {
                    from := fromMax
                }
                if iszero(mload(search)) {
                    result := from
                    break
                }
                result := not(0) // Initialize to `NOT_FOUND`.

                let subjectSearchEnd := sub(add(subject, 0x20), 1)

                subject := add(add(subject, 0x20), from)
                // prettier-ignore
                if iszero(gt(subject, subjectSearchEnd)) { break }
                // As this function is not too often used,
                // we shall simply use keccak256 for smaller bytecode size.
                // prettier-ignore
                for { let h := keccak256(add(search, 0x20), searchLength) } 1 {} {
                    if eq(keccak256(subject, searchLength), h) {
                        result := sub(subject, add(subjectSearchEnd, 1))
                        break
                    }
                    subject := sub(subject, 1)
                    // prettier-ignore
                    if iszero(gt(subject, subjectSearchEnd)) { break }
                }
                break
            }
        }
    }

    /// @dev Returns the index of the first location of `search` in `subject`,
    /// searching from right to left.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function lastIndexOf(string memory subject, string memory search) internal pure returns (uint256 result) {
        result = lastIndexOf(subject, search, uint256(int256(-1)));
    }

    /// @dev Returns whether `subject` starts with `search`.
    function startsWith(string memory subject, string memory search) internal pure returns (bool result) {
        assembly {
            let searchLength := mload(search)
            // Just using keccak256 directly is actually cheaper.
            result := and(
                iszero(gt(searchLength, mload(subject))),
                eq(keccak256(add(subject, 0x20), searchLength), keccak256(add(search, 0x20), searchLength))
            )
        }
    }

    /// @dev Returns whether `subject` ends with `search`.
    function endsWith(string memory subject, string memory search) internal pure returns (bool result) {
        assembly {
            let searchLength := mload(search)
            let subjectLength := mload(subject)
            // Whether `search` is not longer than `subject`.
            let withinRange := iszero(gt(searchLength, subjectLength))
            // Just using keccak256 directly is actually cheaper.
            result := and(
                withinRange,
                eq(
                    keccak256(
                        // `subject + 0x20 + max(subjectLength - searchLength, 0)`.
                        add(add(subject, 0x20), mul(withinRange, sub(subjectLength, searchLength))),
                        searchLength
                    ),
                    keccak256(add(search, 0x20), searchLength)
                )
            )
        }
    }

    /// @dev Returns `subject` repeated `times`.
    function repeat(string memory subject, uint256 times) internal pure returns (string memory result) {
        assembly {
            let subjectLength := mload(subject)
            if iszero(or(iszero(times), iszero(subjectLength))) {
                subject := add(subject, 0x20)
                result := mload(0x40)
                let output := add(result, 0x20)
                // prettier-ignore
                for {} 1 {} {
                    // Copy the `subject` one word at a time.
                    // prettier-ignore
                    for { let o := 0 } 1 {} {
                        mstore(add(output, o), mload(add(subject, o)))
                        o := add(o, 0x20)
                        // prettier-ignore
                        if iszero(lt(o, subjectLength)) { break }
                    }
                    output := add(output, subjectLength)
                    times := sub(times, 1)
                    // prettier-ignore
                    if iszero(times) { break }
                }
                // Zeroize the slot after the string.
                mstore(output, 0)
                // Store the length.
                let resultLength := sub(output, add(result, 0x20))
                mstore(result, resultLength)
                // Allocate memory for the length and the bytes,
                // rounded up to a multiple of 32.
                mstore(0x40, add(result, and(add(resultLength, 63), not(31))))
            }
        }
    }

    /// @dev Returns a copy of `subject` sliced from `start` to `end` (exclusive).
    /// `start` and `end` are byte offsets.
    function slice(
        string memory subject,
        uint256 start,
        uint256 end
    ) internal pure returns (string memory result) {
        assembly {
            let subjectLength := mload(subject)
            if iszero(gt(subjectLength, end)) {
                end := subjectLength
            }
            if iszero(gt(subjectLength, start)) {
                start := subjectLength
            }
            if lt(start, end) {
                result := mload(0x40)
                let resultLength := sub(end, start)
                mstore(result, resultLength)
                subject := add(subject, start)
                // Copy the `subject` one word at a time, backwards.
                // prettier-ignore
                for { let o := and(add(resultLength, 31), not(31)) } 1 {} {
                    mstore(add(result, o), mload(add(subject, o)))
                    o := sub(o, 0x20)
                    // prettier-ignore
                    if iszero(o) { break }
                }
                // Zeroize the slot after the string.
                mstore(add(add(result, 0x20), resultLength), 0)
                // Allocate memory for the length and the bytes,
                // rounded up to a multiple of 32.
                mstore(0x40, add(result, and(add(resultLength, 63), not(31))))
            }
        }
    }

    /// @dev Returns a copy of `subject` sliced from `start` to the end of the string.
    /// `start` is a byte offset.
    function slice(string memory subject, uint256 start) internal pure returns (string memory result) {
        result = slice(subject, start, uint256(int256(-1)));
    }

    /// @dev Returns all the indices of `search` in `subject`.
    /// The indices are byte offsets.
    function indicesOf(string memory subject, string memory search) internal pure returns (uint256[] memory result) {
        assembly {
            let subjectLength := mload(subject)
            let searchLength := mload(search)

            if iszero(gt(searchLength, subjectLength)) {
                subject := add(subject, 0x20)
                search := add(search, 0x20)
                result := add(mload(0x40), 0x20)

                let subjectStart := subject
                let subjectSearchEnd := add(sub(add(subject, subjectLength), searchLength), 1)
                let h := 0
                if iszero(lt(searchLength, 32)) {
                    h := keccak256(search, searchLength)
                }
                let m := shl(3, sub(32, and(searchLength, 31)))
                let s := mload(search)
                // prettier-ignore
                for {} 1 {} {
                    let t := mload(subject)
                    // Whether the first `searchLength % 32` bytes of 
                    // `subject` and `search` matches.
                    if iszero(shr(m, xor(t, s))) {
                        if h {
                            if iszero(eq(keccak256(subject, searchLength), h)) {
                                subject := add(subject, 1)
                                // prettier-ignore
                                if iszero(lt(subject, subjectSearchEnd)) { break }
                                continue
                            }
                        }
                        // Append to `result`.
                        mstore(result, sub(subject, subjectStart))
                        result := add(result, 0x20)
                        // Advance `subject` by `searchLength`.
                        subject := add(subject, searchLength)
                        if searchLength {
                            // prettier-ignore
                            if iszero(lt(subject, subjectSearchEnd)) { break }
                            continue
                        }
                    }
                    subject := add(subject, 1)
                    // prettier-ignore
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
                let resultEnd := result
                // Assign `result` to the free memory pointer.
                result := mload(0x40)
                // Store the length of `result`.
                mstore(result, shr(5, sub(resultEnd, add(result, 0x20))))
                // Allocate memory for result.
                // We allocate one more word, so this array can be recycled for {split}.
                mstore(0x40, add(resultEnd, 0x20))
            }
        }
    }

    /// @dev Returns a arrays of strings based on the `delimiter` inside of the `subject` string.
    function split(string memory subject, string memory delimiter) internal pure returns (string[] memory result) {
        uint256[] memory indices = indicesOf(subject, delimiter);
        assembly {
            if mload(indices) {
                let indexPtr := add(indices, 0x20)
                let indicesEnd := add(indexPtr, shl(5, add(mload(indices), 1)))
                mstore(sub(indicesEnd, 0x20), mload(subject))
                mstore(indices, add(mload(indices), 1))
                let prevIndex := 0
                // prettier-ignore
                for {} 1 {} {
                    let index := mload(indexPtr)
                    mstore(indexPtr, 0x60)                        
                    if iszero(eq(index, prevIndex)) {
                        let element := mload(0x40)
                        let elementLength := sub(index, prevIndex)
                        mstore(element, elementLength)
                        // Copy the `subject` one word at a time, backwards.
                        // prettier-ignore
                        for { let o := and(add(elementLength, 31), not(31)) } 1 {} {
                            mstore(add(element, o), mload(add(add(subject, prevIndex), o)))
                            o := sub(o, 0x20)
                            // prettier-ignore
                            if iszero(o) { break }
                        }
                        // Zeroize the slot after the string.
                        mstore(add(add(element, 0x20), elementLength), 0)
                        // Allocate memory for the length and the bytes,
                        // rounded up to a multiple of 32.
                        mstore(0x40, add(element, and(add(elementLength, 63), not(31))))
                        // Store the `element` into the array.
                        mstore(indexPtr, element)                        
                    }
                    prevIndex := add(index, mload(delimiter))
                    indexPtr := add(indexPtr, 0x20)
                    // prettier-ignore
                    if iszero(lt(indexPtr, indicesEnd)) { break }
                }
                result := indices
                if iszero(mload(delimiter)) {
                    result := add(indices, 0x20)
                    mstore(result, sub(mload(indices), 2))
                }
            }
        }
    }

    /// @dev Returns a concatenated string of `a` and `b`.
    /// Cheaper than `string.concat()` and does not de-align the free memory pointer.
    function concat(string memory a, string memory b) internal pure returns (string memory result) {
        assembly {
            result := mload(0x40)
            let aLength := mload(a)
            // Copy `a` one word at a time, backwards.
            // prettier-ignore
            for { let o := and(add(mload(a), 32), not(31)) } 1 {} {
                mstore(add(result, o), mload(add(a, o)))
                o := sub(o, 0x20)
                // prettier-ignore
                if iszero(o) { break }
            }
            let bLength := mload(b)
            let output := add(result, mload(a))
            // Copy `b` one word at a time, backwards.
            // prettier-ignore
            for { let o := and(add(bLength, 32), not(31)) } 1 {} {
                mstore(add(output, o), mload(add(b, o)))
                o := sub(o, 0x20)
                // prettier-ignore
                if iszero(o) { break }
            }
            let totalLength := add(aLength, bLength)
            let last := add(add(result, 0x20), totalLength)
            // Zeroize the slot after the string.
            mstore(last, 0)
            // Stores the length.
            mstore(result, totalLength)
            // Allocate memory for the length and the bytes,
            // rounded up to a multiple of 32.
            mstore(0x40, and(add(last, 31), not(31)))
        }
    }

    /// @dev Packs a single string with its length into a single word.
    /// Returns `bytes32(0)` if the length is zero or greater than 31.
    function packOne(string memory a) internal pure returns (bytes32 result) {
        assembly {
            // We don't need to zero right pad the string,
            // since this is our own custom non-standard packing scheme.
            result := mul(
                // Load the length and the bytes.
                mload(add(a, 0x1f)),
                // `length != 0 && length < 32`. Abuses underflow.
                // Assumes that the length is valid and within the block gas limit.
                lt(sub(mload(a), 1), 0x1f)
            )
        }
    }

    /// @dev Unpacks a string packed using {packOne}.
    /// Returns the empty string if `packed` is `bytes32(0)`.
    /// If `packed` is not an output of {packOne}, the output behaviour is undefined.
    function unpackOne(bytes32 packed) internal pure returns (string memory result) {
        assembly {
            // Grab the free memory pointer.
            result := mload(0x40)
            // Allocate 2 words (1 for the length, 1 for the bytes).
            mstore(0x40, add(result, 0x40))
            // Zeroize the length slot.
            mstore(result, 0)
            // Store the length and bytes.
            mstore(add(result, 0x1f), packed)
            // Right pad with zeroes.
            mstore(add(add(result, 0x20), mload(result)), 0)
        }
    }

    /// @dev Packs two strings with their lengths into a single word.
    /// Returns `bytes32(0)` if combined length is zero or greater than 30.
    function packTwo(string memory a, string memory b) internal pure returns (bytes32 result) {
        assembly {
            let aLength := mload(a)
            // We don't need to zero right pad the strings,
            // since this is our own custom non-standard packing scheme.
            result := mul(
                // Load the length and the bytes of `a` and `b`.
                or(shl(shl(3, sub(0x1f, aLength)), mload(add(a, aLength))), mload(sub(add(b, 0x1e), aLength))),
                // `totalLength != 0 && totalLength < 31`. Abuses underflow.
                // Assumes that the lengths are valid and within the block gas limit.
                lt(sub(add(aLength, mload(b)), 1), 0x1e)
            )
        }
    }

    /// @dev Unpacks strings packed using {packTwo}.
    /// Returns the empty strings if `packed` is `bytes32(0)`.
    /// If `packed` is not an output of {packTwo}, the output behaviour is undefined.
    function unpackTwo(bytes32 packed) internal pure returns (string memory resultA, string memory resultB) {
        assembly {
            // Grab the free memory pointer.
            resultA := mload(0x40)
            resultB := add(resultA, 0x40)
            // Allocate 2 words for each string (1 for the length, 1 for the byte). Total 4 words.
            mstore(0x40, add(resultB, 0x40))
            // Zeroize the length slots.
            mstore(resultA, 0)
            mstore(resultB, 0)
            // Store the lengths and bytes.
            mstore(add(resultA, 0x1f), packed)
            mstore(add(resultB, 0x1f), mload(add(add(resultA, 0x20), mload(resultA))))
            // Right pad with zeroes.
            mstore(add(add(resultA, 0x20), mload(resultA)), 0)
            mstore(add(add(resultB, 0x20), mload(resultB)), 0)
        }
    }

    /// @dev Directly returns `a` without copying.
    function directReturn(string memory a) internal pure {
        assembly {
            // Right pad with zeroes. Just in case the string is produced
            // by a method that doesn't zero right pad.
            mstore(add(add(a, 0x20), mload(a)), 0)
            // Store the return offset.
            // Assumes that the string does not start from the scratch space.
            mstore(sub(a, 0x20), 0x20)
            // End the transaction, returning the string.
            return(sub(a, 0x20), add(mload(a), 0x40))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Context
/// @notice Overridable context for meta-transactions
/// @author OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts)
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {s as erc1967ds} from "../proxy/ERC1967Proxy.sol";

// ------------- errors

error ProxyCallRequired();
error AlreadyInitialized();

/// @title Initializable
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @dev functions using the `initializer` modifier are only callable during proxy deployment
/// @dev functions using the `reinitializer` modifier are only callable through a proxy
/// @dev and only before a proxy upgrade migration has completed
/// @dev (only when `upgradeToAndCall`'s `initCalldata` is being executed)
/// @dev allows re-initialization during upgrades
abstract contract Initializable {
    address private immutable __implementation = address(this);

    /* ------------- modifier ------------- */

    modifier initializer() {
        if (address(this).code.length != 0) revert AlreadyInitialized();
        _;
    }

    modifier reinitializer() {
        if (address(this) == __implementation) revert ProxyCallRequired();
        if (erc1967ds().implementation == __implementation) revert AlreadyInitialized();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

bytes32 constant DIAMOND_STORAGE_EIP_712_PERMIT = keccak256("diamond.storage.eip.712.permit");

function s() pure returns (EIP2612DS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_EIP_712_PERMIT;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct EIP2612DS {
    mapping(address => uint256) nonces;
}

// ------------- errors

error InvalidSigner();
error DeadlineExpired();

/// @title EIP712Permit (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate)
/// @dev `DOMAIN_SEPARATOR` needs to be re-computed every time
/// @dev for use with a proxy due to `address(this)`
abstract contract EIP712PermitUDS {
    EIP2612DS private __storageLayout; // storage layout for upgrade compatibility checks

    /* ------------- public ------------- */

    function nonces(address owner) public view returns (uint256) {
        return s().nonces[owner];
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256("EIP712"),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /* ------------- internal ------------- */

    function _usePermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) internal virtual {
        if (deadline < block.timestamp) revert DeadlineExpired();

        unchecked {
            uint256 nonce = s().nonces[owner]++;

            address recovered = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonce,
                                deadline
                            )
                        )
                    )
                ),
                v_,
                r_,
                s_
            );

            if (recovered == address(0) || recovered != owner) revert InvalidSigner();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

// keccak256("eip1967.proxy.implementation") - 1
bytes32 constant ERC1967_PROXY_STORAGE_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

function s() pure returns (ERC1967UpgradeDS storage diamondStorage) {
    assembly { diamondStorage.slot := ERC1967_PROXY_STORAGE_SLOT } // prettier-ignore
}

struct ERC1967UpgradeDS {
    address implementation;
}

// ------------- errors

error InvalidUUID();
error NotAContract();

/// @title ERC1967
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract ERC1967 {
    event Upgraded(address indexed implementation);

    function _upgradeToAndCall(address logic, bytes memory data) internal {
        if (logic.code.length == 0) revert NotAContract();

        if (ERC1822(logic).proxiableUUID() != ERC1967_PROXY_STORAGE_SLOT) revert InvalidUUID();

        if (data.length != 0) {
            (bool success, ) = logic.delegatecall(data);

            if (!success) {
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }

        s().implementation = logic;

        emit Upgraded(logic);
    }
}

/// @title Minimal ERC1967Proxy
/// @author phaze (https://github.com/0xPhaze/UDS)
contract ERC1967Proxy is ERC1967 {
    constructor(address logic, bytes memory data) payable {
        _upgradeToAndCall(logic, data);
    }

    fallback() external payable {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let success := delegatecall(gas(), sload(ERC1967_PROXY_STORAGE_SLOT), 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            if success {
                return(0, returndatasize())
            }

            revert(0, returndatasize())
        }
    }
}

/// @title ERC1822
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract ERC1822 {
    function proxiableUUID() external view virtual returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

bytes32 constant DIAMOND_STORAGE_FX_BASE_CHILD_TUNNEL = keccak256("diamond.storage.fx.base.child.tunnel");

function s() pure returns (FxBaseChildTunnelDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_FX_BASE_CHILD_TUNNEL;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct FxBaseChildTunnelDS {
    address fxRootTunnel;
}

// ------------- error

error CallerNotFxChild();
error InvalidRootSender();

abstract contract FxBaseChildTunnel {
    event MessageSent(bytes message);

    address public immutable fxChild;

    constructor(address fxChild_) {
        fxChild = fxChild_;
    }

    /* ------------- virtual ------------- */

    function _authorizeTunnelController() internal virtual;

    /* ------------- view ------------- */

    function fxRootTunnel() public view returns (address) {
        return s().fxRootTunnel;
    }

    /* ------------- restricted ------------- */

    function setFxRootTunnel(address fxRootTunnel_) external {
        _authorizeTunnelController();

        s().fxRootTunnel = fxRootTunnel_;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external {
        if (msg.sender != fxChild) revert CallerNotFxChild();
        if (rootMessageSender == address(0) || rootMessageSender != s().fxRootTunnel) revert InvalidRootSender();

        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /* ------------- internal ------------- */

    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes calldata message
    ) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBaseRootTunnel} from "./base/FxBaseRootTunnel.sol";

bytes4 constant REGISTER_ERC721_IDS_SELECTOR = bytes4(keccak256("registerERC721IdsWithChild(address,uint256[])"));
bytes4 constant DEREGISTER_ERC721_IDS_SELECTOR = bytes4(keccak256("deregisterERC721IdsWithChild(uint256[])"));

/// @title ERC721 FxRootTunnel
/// @author phaze (https://github.com/0xPhaze/fx-contracts)
abstract contract FxERC721Root is FxBaseRootTunnel {
    constructor(address checkpointManager, address fxRoot) FxBaseRootTunnel(checkpointManager, fxRoot) {}

    /* ------------- virtual ------------- */

    function _authorizeTunnelController() internal virtual override;

    /* ------------- internal ------------- */

    function _registerERC721IdsWithChild(address to, uint256[] calldata ids) internal virtual {
        _sendMessageToChild(abi.encodeWithSelector(REGISTER_ERC721_IDS_SELECTOR, to, ids));
    }

    function _registerERC721IdsWithChildMem(address to, uint256[] memory ids) internal virtual {
        _sendMessageToChild(abi.encodeWithSelector(REGISTER_ERC721_IDS_SELECTOR, to, ids));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int)", p0));
    }

    function logUint(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
    }

    function log(uint p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
    }

    function log(uint p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
    }

    function log(uint p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
    }

    function log(string memory p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
    }

    function log(uint p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
    }

    function log(uint p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
    }

    function log(uint p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
    }

    function log(uint p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
    }

    function log(uint p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
    }

    function log(uint p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
    }

    function log(uint p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
    }

    function log(uint p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
    }

    function log(uint p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
    }

    function log(uint p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
    }

    function log(uint p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
    }

    function log(bool p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
    }

    function log(bool p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
    }

    function log(bool p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
    }

    function log(address p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
    }

    function log(address p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
    }

    function log(address p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Merkle} from "../lib/Merkle.sol";
import {RLPReader} from "../lib/RLPReader.sol";
import {ExitPayloadReader} from "../lib/ExitPayloadReader.sol";
import {MerklePatriciaProof} from "../lib/MerklePatriciaProof.sol";

// ------------- interfaces

interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

interface ICheckpointManager {
    function headerBlocks(uint256 headerNumber)
        external
        view
        returns (
            bytes32 root,
            uint256 start,
            uint256 end,
            uint256 createdAt,
            address proposer
        );
}

// ------------- storage

bytes32 constant DIAMOND_STORAGE_FX_BASE_ROOT_TUNNEL = keccak256("diamond.storage.fx.base.root.tunnel");

function s() pure returns (FxBaseRootTunnelDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_FX_BASE_ROOT_TUNNEL;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct FxBaseRootTunnelDS {
    address fxChildTunnel;
    mapping(bytes32 => bool) processedExits;
}

// ------------- errors

error FxChildUnset();
error InvalidHeader();
error InvalidSelector();
error InvalidReceiptProof();
error InvalidFxChildTunnel();
error ExitAlreadyProcessed();

abstract contract FxBaseRootTunnel {
    using RLPReader for RLPReader.RLPItem;
    using Merkle for bytes32;
    using ExitPayloadReader for bytes;
    using ExitPayloadReader for ExitPayloadReader.ExitPayload;
    using ExitPayloadReader for ExitPayloadReader.Log;
    using ExitPayloadReader for ExitPayloadReader.LogTopics;
    using ExitPayloadReader for ExitPayloadReader.Receipt;

    bytes32 private constant SEND_MESSAGE_EVENT_SELECTOR =
        0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036;

    IFxStateSender public immutable fxRoot;
    ICheckpointManager public immutable checkpointManager;

    constructor(address checkpointManager_, address fxRoot_) {
        checkpointManager = ICheckpointManager(checkpointManager_);
        fxRoot = IFxStateSender(fxRoot_);
    }

    /* ------------- virtual ------------- */

    function _authorizeTunnelController() internal virtual;

    /* ------------- view ------------- */

    function fxChildTunnel() public view virtual returns (address) {
        return s().fxChildTunnel;
    }

    function processedExits(bytes32 exitHash) public view virtual returns (bool) {
        return s().processedExits[exitHash];
    }

    function setFxChildTunnel(address fxChildTunnel_) public virtual {
        _authorizeTunnelController();

        s().fxChildTunnel = fxChildTunnel_;
    }

    /* ------------- internal ------------- */

    function _sendMessageToChild(bytes memory message) internal virtual {
        if (s().fxChildTunnel == address(0)) revert FxChildUnset();

        fxRoot.sendMessageToChild(s().fxChildTunnel, message);
    }

    /**
     * @notice receive message from  L2 to L1, validated by proof
     * @dev This function verifies if the transaction actually happened on child chain
     *
     * @param proofData RLP encoded data of the reference tx containing following list of fields
     *  0 - headerNumber - Checkpoint header block number containing the reference tx
     *  1 - blockProof - Proof that the block header (in the child chain) is a leaf in the submitted merkle root
     *  2 - blockNumber - Block number containing the reference tx on child chain
     *  3 - blockTime - Reference tx block time
     *  4 - txRoot - Transactions root of block
     *  5 - receiptRoot - Receipts root of block
     *  6 - receipt - Receipt of the reference transaction
     *  7 - receiptProof - Merkle proof of the reference receipt
     *  8 - branchMask - 32 bits denoting the path of receipt in merkle tree
     *  9 - receiptLogIndex - Log Index to read from the receipt
     */
    function _validateAndExtractMessage(bytes memory proofData) internal returns (bytes memory) {
        address childTunnel = s().fxChildTunnel;

        if (childTunnel == address(0)) revert FxChildUnset();

        ExitPayloadReader.ExitPayload memory payload = proofData.toExitPayload();

        bytes memory branchMaskBytes = payload.getBranchMaskAsBytes();
        uint256 blockNumber = payload.getBlockNumber();
        // checking if exit has already been processed
        // unique exit is identified using hash of (blockNumber, branchMask, receiptLogIndex)
        bytes32 exitHash = keccak256(
            abi.encodePacked(
                blockNumber,
                // first 2 nibbles are dropped while generating nibble array
                // this allows branch masks that are valid but bypass exitHash check (changing first 2 nibbles only)
                // so converting to nibble array and then hashing it
                MerklePatriciaProof._getNibbleArray(branchMaskBytes),
                payload.getReceiptLogIndex()
            )
        );

        if (s().processedExits[exitHash]) revert ExitAlreadyProcessed();

        s().processedExits[exitHash] = true;

        ExitPayloadReader.Receipt memory receipt = payload.getReceipt();
        ExitPayloadReader.Log memory log = receipt.getLog();

        // check child tunnel
        if (childTunnel != log.getEmitter()) revert InvalidFxChildTunnel();

        bytes32 receiptRoot = payload.getReceiptRoot();
        // verify receipt inclusion
        if (!MerklePatriciaProof.verify(receipt.toBytes(), branchMaskBytes, payload.getReceiptProof(), receiptRoot))
            revert InvalidReceiptProof();

        (bytes32 headerRoot, uint256 startBlock, , , ) = checkpointManager.headerBlocks(payload.getHeaderNumber());

        bytes32 leaf = keccak256(
            abi.encodePacked(blockNumber, payload.getBlockTime(), payload.getTxRoot(), receiptRoot)
        );

        if (!leaf.checkMembership(blockNumber - startBlock, headerRoot, payload.getBlockProof()))
            revert InvalidHeader();

        ExitPayloadReader.LogTopics memory topics = log.getTopics();

        if (bytes32(topics.getField(0).toUint()) != SEND_MESSAGE_EVENT_SELECTOR) revert InvalidSelector();

        // received message data
        bytes memory message = abi.decode(log.getData(), (bytes)); // event decodes params again, so decoding bytes to get message

        return message;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Merkle {
    function checkMembership(
        bytes32 leaf,
        uint256 index,
        bytes32 rootHash,
        bytes memory proof
    ) internal pure returns (bool) {
        require(proof.length % 32 == 0, "Invalid proof length");
        uint256 proofHeight = proof.length / 32;
        // Proof of size n means, height of the tree is n+1.
        // In a tree of height n+1, max #leafs possible is 2 ^ n
        require(index < 2**proofHeight, "Leaf index is too big");

        bytes32 proofElement;
        bytes32 computedHash = leaf;
        for (uint256 i = 32; i <= proof.length; i += 32) {
            assembly {
                proofElement := mload(add(proof, i))
            }

            if (index % 2 == 0) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }

            index = index / 2;
        }
        return computedHash == rootHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * @author Hamdi Allam [email protected]
 * Please reach out with any questions or concerns
 */
library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint256 len;
        uint256 memPtr;
    }

    struct Iterator {
        RLPItem item; // Item that's being iterated over.
        uint256 nextPtr; // Position of the next item in the list.
    }

    /*
     * @dev Returns the next element in the iteration. Reverts if it has not next element.
     * @param self The iterator.
     * @return The next element in the iteration.
     */
    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self));

        uint256 ptr = self.nextPtr;
        uint256 itemLength = _itemLength(ptr);
        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }

    /*
     * @dev Returns true if the iteration has more elements.
     * @param self The iterator.
     * @return true if the iteration has more elements.
     */
    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }

    /*
     * @param item RLP encoded bytes
     */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint256 memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
     * @dev Create an iterator. Reverts if item is not a list.
     * @param self The RLP item.
     * @return An 'Iterator' over the item.
     */
    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self));

        uint256 ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    /*
     * @param item RLP encoded bytes
     */
    function rlpLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len;
    }

    /*
     * @param item RLP encoded bytes
     */
    function payloadLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len - _payloadOffset(item.memPtr);
    }

    /*
     * @param item RLP encoded list in bytes
     */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item));

        uint256 items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint256 memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 dataLen;
        for (uint256 i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint256 memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START) return false;
        return true;
    }

    /*
     * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
     * @return keccak256 hash of RLP encoded bytes.
     */
    function rlpBytesKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        uint256 ptr = item.memPtr;
        uint256 len = item.len;
        bytes32 result;
        assembly {
            result := keccak256(ptr, len)
        }
        return result;
    }

    function payloadLocation(RLPItem memory item) internal pure returns (uint256, uint256) {
        uint256 offset = _payloadOffset(item.memPtr);
        uint256 memPtr = item.memPtr + offset;
        uint256 len = item.len - offset; // data length
        return (memPtr, len);
    }

    /*
     * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
     * @return keccak256 hash of the item payload.
     */
    function payloadKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        (uint256 memPtr, uint256 len) = payloadLocation(item);
        bytes32 result;
        assembly {
            result := keccak256(memPtr, len)
        }
        return result;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint256 ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint256 result;
        uint256 memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        return result == 0 ? false : true;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21);

        return address(uint160(toUint(item)));
    }

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        require(item.len > 0 && item.len <= 33);

        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset;

        uint256 result;
        uint256 memPtr = item.memPtr + offset;
        assembly {
            result := mload(memPtr)

            // shfit to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint256) {
        // one byte prefix
        require(item.len == 33);

        uint256 result;
        uint256 memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);

        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset; // data length
        bytes memory result = new bytes(len);

        uint256 destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }

    /*
     * Private Helpers
     */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint256) {
        if (item.len == 0) return 0;

        uint256 count = 0;
        uint256 currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr); // skip over an item
            count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint256 memPtr) private pure returns (uint256) {
        uint256 itemLen;
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) itemLen = 1;
        else if (byte0 < STRING_LONG_START) itemLen = byte0 - STRING_SHORT_START + 1;
        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte
                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        } else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        } else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint256 memPtr) private pure returns (uint256) {
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)) return 1;
        else if (byte0 < LIST_SHORT_START)
            // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else return byte0 - (LIST_LONG_START - 1) + 1;
    }

    /*
     * @param src Pointer to source
     * @param dest Pointer to destination
     * @param len Amount of memory to copy from the source
     */
    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len == 0) return;

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint256 mask = 256**(WORD_SIZE - len) - 1;

        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RLPReader} from "./RLPReader.sol";

library ExitPayloadReader {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    uint8 constant WORD_SIZE = 32;

    struct ExitPayload {
        RLPReader.RLPItem[] data;
    }

    struct Receipt {
        RLPReader.RLPItem[] data;
        bytes raw;
        uint256 logIndex;
    }

    struct Log {
        RLPReader.RLPItem data;
        RLPReader.RLPItem[] list;
    }

    struct LogTopics {
        RLPReader.RLPItem[] data;
    }

    // copy paste of private copy() from RLPReader to avoid changing of existing contracts
    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint256 mask = 256**(WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }

    function toExitPayload(bytes memory data) internal pure returns (ExitPayload memory) {
        RLPReader.RLPItem[] memory payloadData = data.toRlpItem().toList();

        return ExitPayload(payloadData);
    }

    function getHeaderNumber(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[0].toUint();
    }

    function getBlockProof(ExitPayload memory payload) internal pure returns (bytes memory) {
        return payload.data[1].toBytes();
    }

    function getBlockNumber(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[2].toUint();
    }

    function getBlockTime(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[3].toUint();
    }

    function getTxRoot(ExitPayload memory payload) internal pure returns (bytes32) {
        return bytes32(payload.data[4].toUint());
    }

    function getReceiptRoot(ExitPayload memory payload) internal pure returns (bytes32) {
        return bytes32(payload.data[5].toUint());
    }

    function getReceipt(ExitPayload memory payload) internal pure returns (Receipt memory receipt) {
        receipt.raw = payload.data[6].toBytes();
        RLPReader.RLPItem memory receiptItem = receipt.raw.toRlpItem();

        if (receiptItem.isList()) {
            // legacy tx
            receipt.data = receiptItem.toList();
        } else {
            // pop first byte before parsting receipt
            bytes memory typedBytes = receipt.raw;
            bytes memory result = new bytes(typedBytes.length - 1);
            uint256 srcPtr;
            uint256 destPtr;
            assembly {
                srcPtr := add(33, typedBytes)
                destPtr := add(0x20, result)
            }

            copy(srcPtr, destPtr, result.length);
            receipt.data = result.toRlpItem().toList();
        }

        receipt.logIndex = getReceiptLogIndex(payload);
        return receipt;
    }

    function getReceiptProof(ExitPayload memory payload) internal pure returns (bytes memory) {
        return payload.data[7].toBytes();
    }

    function getBranchMaskAsBytes(ExitPayload memory payload) internal pure returns (bytes memory) {
        return payload.data[8].toBytes();
    }

    function getBranchMaskAsUint(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[8].toUint();
    }

    function getReceiptLogIndex(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[9].toUint();
    }

    // Receipt methods
    function toBytes(Receipt memory receipt) internal pure returns (bytes memory) {
        return receipt.raw;
    }

    function getLog(Receipt memory receipt) internal pure returns (Log memory) {
        RLPReader.RLPItem memory logData = receipt.data[3].toList()[receipt.logIndex];
        return Log(logData, logData.toList());
    }

    // Log methods
    function getEmitter(Log memory log) internal pure returns (address) {
        return RLPReader.toAddress(log.list[0]);
    }

    function getTopics(Log memory log) internal pure returns (LogTopics memory) {
        return LogTopics(log.list[1].toList());
    }

    function getData(Log memory log) internal pure returns (bytes memory) {
        return log.list[2].toBytes();
    }

    function toRlpBytes(Log memory log) internal pure returns (bytes memory) {
        return log.data.toRlpBytes();
    }

    // LogTopics methods
    function getField(LogTopics memory topics, uint256 index) internal pure returns (RLPReader.RLPItem memory) {
        return topics.data[index];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RLPReader} from "./RLPReader.sol";

library MerklePatriciaProof {
    /*
     * @dev Verifies a merkle patricia proof.
     * @param value The terminating value in the trie.
     * @param encodedPath The path in the trie leading to value.
     * @param rlpParentNodes The rlp encoded stack of nodes.
     * @param root The root hash of the trie.
     * @return The boolean validity of the proof.
     */
    function verify(
        bytes memory value,
        bytes memory encodedPath,
        bytes memory rlpParentNodes,
        bytes32 root
    ) internal pure returns (bool) {
        RLPReader.RLPItem memory item = RLPReader.toRlpItem(rlpParentNodes);
        RLPReader.RLPItem[] memory parentNodes = RLPReader.toList(item);

        bytes memory currentNode;
        RLPReader.RLPItem[] memory currentNodeList;

        bytes32 nodeKey = root;
        uint256 pathPtr = 0;

        bytes memory path = _getNibbleArray(encodedPath);
        if (path.length == 0) {
            return false;
        }

        for (uint256 i = 0; i < parentNodes.length; i++) {
            if (pathPtr > path.length) {
                return false;
            }

            currentNode = RLPReader.toRlpBytes(parentNodes[i]);
            if (nodeKey != keccak256(currentNode)) {
                return false;
            }
            currentNodeList = RLPReader.toList(parentNodes[i]);

            if (currentNodeList.length == 17) {
                if (pathPtr == path.length) {
                    if (keccak256(RLPReader.toBytes(currentNodeList[16])) == keccak256(value)) {
                        return true;
                    } else {
                        return false;
                    }
                }

                uint8 nextPathNibble = uint8(path[pathPtr]);
                if (nextPathNibble > 16) {
                    return false;
                }
                nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[nextPathNibble]));
                pathPtr += 1;
            } else if (currentNodeList.length == 2) {
                uint256 traversed = _nibblesToTraverse(RLPReader.toBytes(currentNodeList[0]), path, pathPtr);
                if (pathPtr + traversed == path.length) {
                    //leaf node
                    if (keccak256(RLPReader.toBytes(currentNodeList[1])) == keccak256(value)) {
                        return true;
                    } else {
                        return false;
                    }
                }

                //extension node
                if (traversed == 0) {
                    return false;
                }

                pathPtr += traversed;
                nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[1]));
            } else {
                return false;
            }
        }

        return false;
    }

    function _nibblesToTraverse(
        bytes memory encodedPartialPath,
        bytes memory path,
        uint256 pathPtr
    ) private pure returns (uint256) {
        uint256 len = 0;
        // encodedPartialPath has elements that are each two hex characters (1 byte), but partialPath
        // and slicedPath have elements that are each one hex character (1 nibble)
        bytes memory partialPath = _getNibbleArray(encodedPartialPath);
        bytes memory slicedPath = new bytes(partialPath.length);

        // pathPtr counts nibbles in path
        // partialPath.length is a number of nibbles
        for (uint256 i = pathPtr; i < pathPtr + partialPath.length; i++) {
            bytes1 pathNibble = path[i];
            slicedPath[i - pathPtr] = pathNibble;
        }

        if (keccak256(partialPath) == keccak256(slicedPath)) {
            len = partialPath.length;
        } else {
            len = 0;
        }
        return len;
    }

    // bytes b must be hp encoded
    function _getNibbleArray(bytes memory b) internal pure returns (bytes memory) {
        bytes memory nibbles = "";
        if (b.length > 0) {
            uint8 offset;
            uint8 hpNibble = uint8(_getNthNibbleOfBytes(0, b));
            if (hpNibble == 1 || hpNibble == 3) {
                nibbles = new bytes(b.length * 2 - 1);
                bytes1 oddNibble = _getNthNibbleOfBytes(1, b);
                nibbles[0] = oddNibble;
                offset = 1;
            } else {
                nibbles = new bytes(b.length * 2 - 2);
                offset = 0;
            }

            for (uint256 i = offset; i < nibbles.length; i++) {
                nibbles[i] = _getNthNibbleOfBytes(i - offset + 2, b);
            }
        }
        return nibbles;
    }

    function _getNthNibbleOfBytes(uint256 n, bytes memory str) private pure returns (bytes1) {
        return bytes1(n % 2 == 0 ? uint8(str[n / 2]) / 0x10 : uint8(str[n / 2]) % 0x10);
    }
}