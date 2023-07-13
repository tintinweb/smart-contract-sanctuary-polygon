// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// todo: create FishingShop contract for buying bait and equipment

struct FishingHole {
    uint256 id;
    address owner;
    uint256 waterDepthLevel; // 0 shallows, 1 deep, 2 abyss
    FishingAavegotchiRequirement aavegotchiRequirement;
    // FishingEquipmentRequirement equipmentRequirement;
}

struct FishingAavegotchiRequirement {
    // uint256 minBRS;
    // uint256 minKinship;
    // uint256 minXP;
    uint256 equippedWearableRequirement;
    // uint256 equippedWearableSetRequirement;
    // uint256[6] minimumTraitRequirements;
}

// struct FishingEquipmentRequirement {
//     uint256 minimumBaitLevel;
//     uint256 baitAmount;
//     uint256 minimumRodLevel;
// }

struct FishingReward {
    uint256 fishId;
    uint256 fishAmount;
    uint256 fishingXP;
    // address rewardERC20TokenContract;
    // uint256 rewardERC20TokenQuantity;
    // address rewardERC721TokenContract;
    // uint256 rewardERC721TokenId;
    // address rewardERC1155TokenContract;
    // uint256 rewardERC1155TokenId;
    // uint256 rewardERC1155TokenQuantity;
    address firstClaimed;
}

struct Cast {
    uint256 holeId;
    uint256 blockNumber;
}

uint256 constant EQUIPPED_WEARABLE_SLOTS = 16;
uint256 constant NUMERIC_TRAITS_NUM = 6;
uint256 constant TRAIT_BONUSES_NUM = 5;
uint256 constant PORTAL_AAVEGOTCHIS_NUM = 10;

struct AavegotchiInfo {
    uint256 tokenId;
    string name;
    address owner;
    uint256 randomNumber;
    uint256 status;
    int16[NUMERIC_TRAITS_NUM] numericTraits;
    int16[NUMERIC_TRAITS_NUM] modifiedNumericTraits;
    uint16[EQUIPPED_WEARABLE_SLOTS] equippedWearables;
    address collateral;
    address escrow;
    uint256 stakedAmount;
    uint256 minimumStake;
    uint256 kinship; //The kinship value of this Aavegotchi. Default is 50.
    uint256 lastInteracted;
    uint256 experience; //How much XP this Aavegotchi has accrued. Begins at 0.
    uint256 toNextLevel;
    uint256 usedSkillPoints; //number of skill points used
    uint256 level; //the current aavegotchi level
    uint256 hauntId;
    uint256 baseRarityScore;
    uint256 modifiedRarityScore;
    bool locked;
    ItemTypeIO[] items;
}

struct ItemTypeIO {
    uint256 balance;
    uint256 itemId;
    ItemType itemType;
}

struct ItemType {
    string name; //The name of the item
    string description;
    string author;
    // treated as int8s array
    // [Experience, Rarity Score, Kinship, Eye Color, Eye Shape, Brain Size, Spookiness, Aggressiveness, Energy]
    int8[NUMERIC_TRAITS_NUM] traitModifiers; //[WEARABLE ONLY] How much the wearable modifies each trait. Should not be more than +-5 total
    //[WEARABLE ONLY] The slots that this wearable can be added to.
    bool[EQUIPPED_WEARABLE_SLOTS] slotPositions;
    // this is an array of uint indexes into the collateralTypes array
    uint8[] allowedCollaterals; //[WEARABLE ONLY] The collaterals this wearable can be equipped to. An empty array is "any"
    // SVG x,y,width,height
    Dimensions dimensions;
    uint256 ghstPrice; //How much GHST this item costs
    uint256 maxQuantity; //Total number that can be minted of this item.
    uint256 totalQuantity; //The total quantity of this item minted so far
    uint32 svgId; //The svgId of the item
    uint8 rarityScoreModifier; //Number from 1-50.
    // Each bit is a slot position. 1 is true, 0 is false
    bool canPurchaseWithGhst;
    uint16 minLevel; //The minimum Aavegotchi level required to use this item. Default is 1.
    bool canBeTransferred;
    uint8 category; // 0 is wearable, 1 is badge, 2 is consumable
    int16 kinshipBonus; //[CONSUMABLE ONLY] How much this consumable boosts (or reduces) kinship score
    uint32 experienceBonus; //[CONSUMABLE ONLY]
}

struct Dimensions {
    uint8 x;
    uint8 y;
    uint8 width;
    uint8 height;
}

interface IAavegotchi {
    function ownerOf(uint256 _tokenId) external view returns (address owner_);

    function getAavegotchi(
        uint256 _tokenId
    ) external view returns (AavegotchiInfo memory aavegotchiInfo_);

    function equippedWearables(
        uint256 _tokenId
    )
        external
        view
        returns (uint16[EQUIPPED_WEARABLE_SLOTS] memory wearableIds_);
}

contract FishingHoleContract {
    uint256 public holesCount;
    mapping(uint256 => FishingHole) public fishingHoles;
    mapping(uint256 => FishingReward) public fishingRewards;
    mapping(uint256 => uint256) public aavegotchiFishingXP;
    mapping(address => uint256) public accountCodexPoints;
    mapping(address => mapping(uint256 => uint256)) public rewardUnlocked; // account => holeId => 0: not tried, 1: successful, 2: failed
    mapping(address => mapping(uint256 => bool)) public rewardClaimed;
    mapping(uint256 => Cast) public activeGotchiCasts; // gotchiId => Cast (one gotchi cannot have multiple active casts)

    address public aavegotchiDiamondAddress;
    uint256 public castTimeInBlocks;

    constructor(address _aavegotchiDiamondAddress, uint256 _castTimeInBlocks) {
        aavegotchiDiamondAddress = _aavegotchiDiamondAddress;
        castTimeInBlocks = _castTimeInBlocks;

        FishingHole[] memory _holes = new FishingHole[](3);
        _holes[0] = FishingHole(
            0,
            address(0),
            1,
            FishingAavegotchiRequirement(0)
        );
        _holes[1] = FishingHole(
            1,
            address(0),
            1,
            FishingAavegotchiRequirement(239)
        );
        _holes[2] = FishingHole(
            2,
            address(0),
            1,
            FishingAavegotchiRequirement(21)
        );
        setFishingHoles(_holes);
    }

    function setFishingHoles(FishingHole[] memory _holes) public {
        for (uint256 i; i < _holes.length; i++) {
            fishingHoles[i] = _holes[i];
        }
    }

    // function setFishingHoles(FishingHole[] calldata _holes) public {
    //     for (uint256 i; i < _holes.length; i++) {
    //         fishingHoles[i] = _holes[i];
    //     }
    // }

    function cast(uint _gotchiId, uint _holeId) public {
        IAavegotchi aavegotchi = IAavegotchi(aavegotchiDiamondAddress);
        require(
            aavegotchi.ownerOf(_gotchiId) == msg.sender,
            "FishingHole: Must be owner of Aavegotchi"
        );
        require(_holeId < holesCount, "FishingHole: Hole does not exist");

        require(
            activeGotchiCasts[_gotchiId].blockNumber == 0,
            "FishingHole: Active cast must not already exist"
        );

        // add equipment checks here (later)

        activeGotchiCasts[_gotchiId] = Cast(_holeId, block.number);
    }

    function claimCast(uint _gotchiId, uint _holeId) public returns (bool) {
        IAavegotchi aavegotchi = IAavegotchi(aavegotchiDiamondAddress);
        require(_holeId < holesCount, "FishingHole: Hole does not exist");

        require(
            aavegotchi.ownerOf(_gotchiId) == msg.sender,
            "FishingHole: Must be owner of Aavegotchi"
        );

        require(
            activeGotchiCasts[_gotchiId].holeId == _holeId,
            "FishingHole: Hole must match active cast"
        );

        require(
            activeGotchiCasts[_gotchiId].blockNumber != 0,
            "FishingHole: Active cast must exist"
        );

        require(
            (activeGotchiCasts[_gotchiId].blockNumber + castTimeInBlocks) >=
                block.number,
            "FishingHole: Cast time must have passed"
        );

        uint256 result = 0; // 0: not tried, 1: successful, 2: failed

        // check aavegotchi requirements are meet
        FishingAavegotchiRequirement storage aavegotchiReq = fishingHoles[
            _holeId
        ].aavegotchiRequirement;

        if (aavegotchiReq.equippedWearableRequirement != 0) {
            uint16[EQUIPPED_WEARABLE_SLOTS]
                memory equippedWearables = aavegotchi.equippedWearables(
                    _gotchiId
                );
            for (uint16 i = 0; i < EQUIPPED_WEARABLE_SLOTS; i++) {
                if (
                    equippedWearables[i] ==
                    aavegotchiReq.equippedWearableRequirement
                ) {
                    result = 1;
                    break;
                }
                result = 2;
            }
        } else {
            result = 1;
        }

        delete activeGotchiCasts[_gotchiId];
        rewardUnlocked[msg.sender][_holeId] = result;

        if (result == 1) {
            return true;
        }
        return false;
    }

    // function setFishingHole(
    //     uint256 _id,
    //     uint256 _waterDepthLevel,
    //     uint256 _brsRequirement,
    //     uint256 _kinshipRequirement,
    //     uint256 _xpRequirement,
    //     uint256 _equippedWearableRequirement,
    //     uint256 _equippedWearableSetRequirement,
    //     uint256[6] calldata _minimumTraitRequirements
    // ) public {
    //     fishingHoles[_id] = FishingHole({
    //         id: _id,
    //         owner: address(0),
    //         waterDepthLevel: _waterDepthLevel,
    //         aavegotchiRequirement: FishingAavegotchiRequirement({
    //             gotchiRequirements: [
    //                 _brsRequirement,
    //                 _kinshipRequirement,
    //                 _xpRequirement
    //             ],
    //             equippedWearableRequirement: _equippedWearableRequirement,
    //             minimumTraitRequirements: _minimumTraitRequirements
    //         })
    //     });
    // }
}