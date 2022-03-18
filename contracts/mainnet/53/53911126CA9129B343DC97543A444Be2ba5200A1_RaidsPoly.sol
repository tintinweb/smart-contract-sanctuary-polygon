// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "../interfaces/Interfaces.sol";

contract RaidsPoly {

    /*///////////////////////////////////////////////////////////////
                   STORAGE SLOTS  
    //////////////////////////////////////////////////////////////*/

    address        implementation_;
    address public admin; 

    ERC721Like          public orcs;
    ERC20Like           public zug;
    ERC20Like           public boneShards;
    HallOfChampionsLike public hallOfChampions;

    mapping (uint256 => Raid)     public locations;
    mapping (uint256 => Campaign) public campaigns;
    mapping (uint256 => address)  public commanders;

    uint256 public giantCrabHealth;
    uint256 public dbl_discount;

    bytes32 internal entropySauce;

    ERC721Like  allies;
    ERC1155Like items;

    address public vendor;
    address public gamingOracle;

    uint256 public seedCounter;
    uint256 public vendorPct;
    uint256 public runeBoost;

    uint256 public constant HND_PCT   = 10_000; // Probabilities are given in a scale from 0 - 10_000, where 10_000 == 100% and 0 == 0%
    uint256 public constant POTION_ID = 1;
    uint256 public constant RUNES_ID  = 3;  
    uint256 public constant MAX_RUNES = 3;  

    // All that in a single storage slot. Fuck yeah!
    struct Raid {
        uint16 minLevel;  uint16 maxLevel;  uint16 duration;  uint16 cost;
        uint16 grtAtMin;  uint16 grtAtMax;  uint16 supAtMin;  uint16 supAtMax;
        uint16 regReward; uint16 grtReward; uint16 supReward; uint16 minPotions; uint16 maxPotions; // Rewards are scale down to 100(= 1BS & 1=0.01) to fit uint16. 
    }    

    struct Campaign { uint8 location; bool double; uint64 end; uint112 runesUsed; uint64 seed; } // warning: runesUsed is both indication that a campaing has rewards and the actual numbers of runes used.

    event BossHit(uint256 orcId, uint256 damage, uint256 remainingHealth);
    event RaidOutcome(uint256 id, uint256 level, uint256 location, uint256 reward);

    /*///////////////////////////////////////////////////////////////
                   Admin Functions 
    //////////////////////////////////////////////////////////////*/

    function initialize(address orcs_, address zug_, address boneShards_, address hallOfChampions_) external {
        require(msg.sender == admin, "not auth");
        
        orcs            = ERC721Like(orcs_);
        zug             = ERC20Like(zug_);
        boneShards      = ERC20Like(boneShards_);
        hallOfChampions = HallOfChampionsLike(hallOfChampions_);
    }

     function init(address allies_, address vendor_, address potions_, address orcl) external {
        require(msg.sender == admin);

        dbl_discount    = 200;
        runeBoost       = 200;

        allies       = ERC721Like(allies_);
        items        = ERC1155Like(potions_);
        gamingOracle = orcl;
        vendor       = vendor_;
    }

    function setRaids() external {
        require(msg.sender == admin);

        //disable all old raids
        locations[10].cost = type(uint16).max;
        locations[11].cost = type(uint16).max;
        locations[12].cost = type(uint16).max;
        locations[13].cost = type(uint16).max;
        locations[14].cost = type(uint16).max; 
        locations[15].cost = type(uint16).max;
        locations[16].cost = type(uint16).max;
        locations[17].cost = type(uint16).max;
        locations[18].cost = type(uint16).max;

        Raid memory spidersDenNew = Raid({ minLevel:  15, maxLevel: 35,  duration:  192, cost: 165, grtAtMin: 1500, grtAtMax: 2000, supAtMin: 1000, supAtMax: 1500, regReward: 300, grtReward: 700, supReward: 1500, minPotions: 0, maxPotions: 1});
        Raid memory unstableQuagNew = Raid({ minLevel:  45, maxLevel: 65,  duration:  192, cost: 155, grtAtMin: 1500, grtAtMax: 2000, supAtMin: 1000, supAtMax: 1500, regReward: 600, grtReward: 600, supReward: 600, minPotions: 2, maxPotions: 2});
        Raid memory spiderlordNew = Raid({ minLevel:  70, maxLevel: 90,  duration:  168, cost: 105, grtAtMin: 2000, grtAtMax: 2500, supAtMin: 1500, supAtMax: 2000, regReward: 200, grtReward: 300, supReward: 1200, minPotions: 2, maxPotions: 2});
        Raid memory pirateCoveNew = Raid({ minLevel:  100, maxLevel: 120,  duration:  264, cost: 195, grtAtMin: 2000, grtAtMax: 2500, supAtMin: 1500, supAtMax: 2000, regReward: 500, grtReward: 800, supReward: 1800, minPotions: 3, maxPotions: 3});
        Raid memory boneshardBeach = Raid({ minLevel:  155, maxLevel: 175,  duration:  192, cost: 135, grtAtMin: 1000, grtAtMax: 1500, supAtMin: 0, supAtMax: 500, regReward: 500, grtReward: 800, supReward: 1800, minPotions: 2, maxPotions: 2});
        Raid memory hiddenCatacomb = Raid({ minLevel:  180, maxLevel: 200,  duration:  168, cost: 110, grtAtMin: 0, grtAtMax: 500, supAtMin: 0, supAtMax: 500, regReward: 400, grtReward: 1200, supReward: 1600, minPotions: 2, maxPotions: 2});
        Raid memory lostRuins = Raid({ minLevel:  230, maxLevel: 250,  duration:  264, cost: 215, grtAtMin: 1500, grtAtMax: 2000, supAtMin: 1000, supAtMax: 1500, regReward: 800, grtReward: 1200, supReward: 2000, minPotions: 3, maxPotions: 3});
        Raid memory piratesBounty = Raid({ minLevel:  260, maxLevel: 280,  duration:  120, cost: 95, grtAtMin: 0, grtAtMax: 500, supAtMin: 0, supAtMax: 500, regReward: 400, grtReward: 800, supReward: 2000, minPotions: 1, maxPotions: 1});
        Raid memory vendorStash = Raid({ minLevel:  260, maxLevel: 280,  duration:  72, cost: 35, grtAtMin: 0, grtAtMax: 500, supAtMin: 0, supAtMax: 500, regReward: 0, grtReward: 1000, supReward: 2000, minPotions: 1, maxPotions: 1});

        locations[19] = spidersDenNew;
        locations[20] = unstableQuagNew;
        locations[21] = spiderlordNew;
        locations[22] = pirateCoveNew;
        locations[23] = boneshardBeach;
        locations[24] = hiddenCatacomb;
        locations[25] = lostRuins;
        locations[26] = piratesBounty;
        locations[27] = vendorStash;


        dbl_discount    = 200;
        runeBoost       = 200;
    }

    function setVendorPercentage(uint256 pct) external {
        require(msg.sender == admin, "not authed");

        vendorPct = pct;
    }

    function setRuneBoost(uint256 pct) external {
        require(msg.sender == admin, "not authed");

        runeBoost = pct;
    }

    /*///////////////////////////////////////////////////////////////
                   PUBLIC FUNCTIONS 
    //////////////////////////////////////////////////////////////*/

    function unstake(uint256 orcishId) public {
        Campaign memory cmp = campaigns[orcishId];

        require(msg.sender == (orcishId < 5051 ? address(orcs) : address(allies)), "Not orcs contract");
        require(_ended(campaigns[orcishId]),   "Still raiding");

        _claim(orcishId);

        if (orcishId < 5051) {
            orcs.transfer(commanders[orcishId], orcishId);
        } else {
            allies.transfer(commanders[orcishId], orcishId);
        }

        delete commanders[orcishId];
    }

    function claim(uint256[] calldata ids) external {
        for (uint256 i = 0; i < ids.length; i++) {
            _claim(ids[i]);
        }
    }   

    function stakeManyAndStartCampaign(uint256[] calldata ids_, address owner_, uint256 location_, bool double_, uint256[] calldata potions_, uint256[] calldata runes_) external {
        for (uint256 i = 0; i < ids_.length; i++) {
            _stake(ids_[i], owner_);
            _startCampaign(ids_[i], location_, double_, potions_[i], runes_[i]);
        }
    }

    function startCampaignWithMany(uint256[] calldata ids, uint256 location_, bool double_, uint256[] calldata potions_, uint256[] calldata runes_) external {
        for (uint256 i = 0; i < ids.length; i++) {
            _startCampaign(ids[i], location_, double_, potions_[i], runes_[i]);
        }
    } 

    /*///////////////////////////////////////////////////////////////
                   INTERNAl HELPERS  
    //////////////////////////////////////////////////////////////*/

    function _claim(uint256 id) internal returns(uint256 reward){
        Campaign memory cmp = campaigns[id]; 

        if (cmp.location > 0 && _ended(campaigns[id])) {
            reward = cmp.runesUsed;
            if (cmp.seed != 0) {
                // New case - calculate the result from seed
                Raid memory raid = locations[cmp.location];
                uint16 level     = _getLevel(id);
                uint256 rdn      = OracleLike(gamingOracle).getRandom(cmp.seed);
                
                require(rdn != 0, "no random value yet");
                
                reward = _getReward(raid, id, level, _getBoosted(cmp, _getRandom(id, rdn, "RAID")));
                emit RaidOutcome(id, level, cmp.location, reward);

                if (cmp.double) {
                    uint256 reward2 = _getReward(raid, id, level, _getBoosted(cmp, _getRandom(id, rdn, "DOUBLE RAID")));
                    reward += reward2;
                    _foundSomething(raid, cmp, _getRandom(id, rdn, "FIRST TRY"), id);
                    emit RaidOutcome(id, level, cmp.location, reward2);
                }
                _foundSomething(raid, cmp, _getRandom(id, rdn, "LUCKY"), id);
            } 
            delete campaigns[id];

            boneShards.mint(commanders[id], reward);
        }
    } 

    function _stake(uint256 id, address owner) internal {
        require(commanders[id] == address(0), "already Staked");
        require(msg.sender == (id < 5051 ? address(orcs) : address(allies)));
        require((id < 5051 ? orcs.ownerOf(id) : allies.ownerOf(id)) == address(this), "orc not transferred");

        commanders[id] = owner;
    }

    function _startCampaign(uint orcishId, uint256 location_, bool double, uint256 potions_, uint256 runes_) internal {
        Raid memory raid = locations[location_];
        address owner = commanders[orcishId];

        require(runes_   <= (double ? MAX_RUNES * 2 : MAX_RUNES),             "too much runes");
        require(potions_ <= (double ? raid.maxPotions * 2 : raid.maxPotions), "too much potions");
        require(potions_ >= (double ? raid.minPotions * 2 : raid.minPotions), "too few potions");
        require(msg.sender == (orcishId < 5051 ? address(orcs) : address(allies)), "Not allowed");
        require(_ended(campaigns[orcishId]),   "Currently on campaign");

        _claim(orcishId);

        require(_getLevel(orcishId) >= raid.minLevel, "below min level");

        if (double) require(runes_ % 2 == 0, "odd runes in double raids");

        uint256 zugAmount = uint256(raid.cost) * 1 ether;
        uint256 duration  = raid.duration;
         
        campaigns[orcishId].double = false;
        
        if (double) {
            uint256 totalCost = zugAmount * 2;
            zugAmount  = totalCost - (totalCost * dbl_discount / HND_PCT);
            duration  += raid.duration;

            campaigns[orcishId].double = true;
        }
        _distributeZug(owner, zugAmount);

        if(potions_ > 0) {
            items.burn(owner, POTION_ID, potions_ * 1 ether);
            duration -= potions_ * 24;
        }

        if (runes_ > 0) items.burn(owner, RUNES_ID, runes_ * 1 ether);

        campaigns[orcishId].location   = uint8(location_);
        campaigns[orcishId].runesUsed  = uint112(runes_);
        campaigns[orcishId].end        = uint64(block.timestamp + (duration * 1 hours));
        campaigns[orcishId].seed       = requestSeed();
    }   

    function _distributeZug(address owner, uint256 amount) internal {
        uint256 vendorAmt = amount * vendorPct / HND_PCT;
        zug.burn(owner, amount);
        zug.mint(vendor, vendorAmt);
    }

    function _updateEntropy() internal {
        entropySauce = keccak256(abi.encodePacked(tx.origin, block.coinbase));
    }

    function _ended(Campaign memory cmp) internal view returns(bool) {
        return cmp.end == 0 || block.timestamp > (giantCrabHealth == 0 ? cmp.end - (cmp.double ? 2 days : 1 days) : cmp.end);
    }

    function requestSeed() internal returns(uint64 seed) {
        return OracleLike(gamingOracle).request();
    }

    function _getReward(Raid memory raid, uint256 orcId, uint16 orcLevel, uint256 rdn) internal view returns(uint176 reward) {
        uint256 champBonus = _getChampionBonus(uint16(orcId));
        uint256 greatProb  = _getBaseOutcome(raid.minLevel, raid.maxLevel, raid.grtAtMin, raid.grtAtMax, orcLevel) + _getLevelBonus(raid.maxLevel, orcLevel) + champBonus;
        uint256 superbProb = _getBaseOutcome(raid.minLevel, raid.maxLevel, raid.supAtMin, raid.supAtMax, orcLevel) + champBonus;

        reward = uint176(rdn <= superbProb ? raid.supReward  : rdn <= greatProb + superbProb ? raid.grtReward : raid.regReward) * 1e16;
    }

    function _getBoosted(Campaign memory cmp, uint256 rdn) internal view returns (uint256 boosted) {
        // Either an old raid (with rewards) or no runes used
        if (cmp.runesUsed > 2 * MAX_RUNES || cmp.runesUsed == 0) return rdn;
        
        uint256 boost = uint256(uint256(cmp.runesUsed) / (cmp.double ? 2 : 1) * runeBoost);
        boosted = boost < rdn ? rdn - boost : 0;
    }

    function _getRandom(uint256 orcId, uint256 ramdom, string memory salt) internal pure returns (uint256 rdn) {
        rdn = uint256(keccak256(abi.encode(ramdom, orcId, salt))) % 10_000 + 1;
    }

    function _getLevel(uint256 id) internal view returns(uint16 level) {
        if (id < 5051) {
            (,,,, level,,) = EtherOrcsLike(address(orcs)).orcs(id);
        } else {
            (,level,,,,) = AlliesLike(address(allies)).allies(id);
        }
    }

    function _getBaseOutcome(uint256 minLevel, uint256 maxLevel, uint256 minProb, uint256 maxProb, uint256 orcishLevel) internal pure returns(uint256 prob) {
        orcishLevel = orcishLevel > maxLevel ? maxLevel : orcishLevel;
        prob = minProb + ((orcishLevel - minLevel) * (maxProb - minProb)/(maxLevel == minLevel ? 1 : (maxLevel - minLevel))) ;
    }

    function _getLevelBonus(uint256 maxLevel, uint256 orcishLevel) internal pure returns (uint256 prob){
        if(orcishLevel <= maxLevel) return 0;
        if (orcishLevel <= maxLevel + 20) return ((orcishLevel - maxLevel) * HND_PCT / 20 * 500) / HND_PCT;
        prob = 500;
    }

    function _getChampionBonus(uint16 id) internal view returns (uint256 bonus){
        bonus =  HallOfChampionsLike(hallOfChampions).joined(id) > 0 ? 100 : 0;
    }

    function _foundSomething(Raid memory raid, Campaign memory cmp, uint256 rdn, uint256 id) internal {
        if (cmp.runesUsed == 0 || cmp.runesUsed > 2 * MAX_RUNES) return;

        if (rdn >= 9_700) {
            if (items.balanceOf(address(this), 100) > 0) items.safeTransferFrom(address(this), commanders[id], 100, 1, new bytes(0));
        }

        if (rdn <= 300) {
            if (items.balanceOf(address(this), 101) > 0) items.safeTransferFrom(address(this), commanders[id], 101, 1, new bytes(0));
        }

    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

interface OrcishLike {
    function pull(address owner, uint256[] calldata ids) external;
    function manuallyAdjustOrc(uint256 id, uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level, uint16 zugModifier, uint32 lvlProgress) external;
    function transfer(address to, uint256 tokenId) external;
    function orcs(uint256 id) external view returns(uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level, uint16 zugModifier, uint32 lvlProgress);
    function allies(uint256 id) external view returns (uint8 class, uint16 level, uint32 lvlProgress, uint16 modF, uint8 skillCredits, bytes22 details);
    function adjustAlly(uint256 id, uint8 class_, uint16 level_, uint32 lvlProgress_, uint16 modF_, uint8 skillCredits_, bytes22 details_) external;
    function ogres(uint256 id) external view returns(uint16 level, uint32 lvlProgress, uint16 modF, uint8 skillCredits, uint8 body, uint8 mouth, uint8 nose, uint8 eyes, uint8 armor, uint8 mainhand, uint8 offhand);
    function claim(uint256[] calldata ids) external;
    function rogue(bytes22 details) external pure returns(uint8 body, uint8 face, uint8 boots, uint8 pants,uint8 shirt,uint8 hair ,uint8 armor ,uint8 mainhand,uint8 offhand);
}


        

interface PortalLike {
    function sendMessage(bytes calldata message_) external;
}

interface OracleLike {
    function request() external returns (uint64 key);
    function getRandom(uint64 id) external view returns(uint256 rand);
}

interface MetadataHandlerLike {
    function getTokenURI(uint16 id, uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level, uint16 zugModifier) external view returns (string memory);
}

interface MetadataHandlerAllies {
    function getTokenURI(uint256 id_, uint256 class_, uint256 level_, uint256 modF_, uint256 skillCredits_, bytes22 details_) external view returns (string memory);
}

interface RaidsLike {
    function stakeManyAndStartCampaign(uint256[] calldata ids_, address owner_, uint256 location_, bool double_) external;
    function startCampaignWithMany(uint256[] calldata ids, uint256 location_, bool double_) external;
    function commanders(uint256 id) external returns(address);
    function unstake(uint256 id) external;
}

interface RaidsLikePoly {
    function stakeManyAndStartCampaign(uint256[] calldata ids_, address owner_, uint256 location_, bool double_, uint256[] calldata potions_, uint256[] calldata runes_) external;
    function startCampaignWithMany(uint256[] calldata ids, uint256 location_, bool double_,  uint256[] calldata potions_, uint256[] calldata runes_) external;
    function commanders(uint256 id) external returns(address);
    function unstake(uint256 id) external;
}

interface CastleLike {
    function pullCallback(address owner, uint256[] calldata ids) external;
}

interface EtherOrcsLike {
    function ownerOf(uint256 id) external view returns (address owner_);
    function activities(uint256 id) external view returns (address owner, uint88 timestamp, uint8 action);
    function orcs(uint256 orcId) external view returns (uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level, uint16 zugModifier, uint32 lvlProgress);
}

interface ERC20Like {
    function balanceOf(address from) external view returns(uint256 balance);
    function burn(address from, uint256 amount) external;
    function mint(address from, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
}

interface ERC1155Like {
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function mint(address to, uint256 id, uint256 amount) external;
    function burn(address from, uint256 id, uint256 amount) external;
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data) external;
}

interface ERC721Like {
    function transferFrom(address from, address to, uint256 id) external;   
    function transfer(address to, uint256 id) external;
    function ownerOf(uint256 id) external returns (address owner);
    function mint(address to, uint256 tokenid) external;
}

interface HallOfChampionsLike {
    function joined(uint256 orcId) external view returns (uint256 joinDate);
} 

interface AlliesLike {
    function allies(uint256 id) external view returns (uint8 class, uint16 level, uint32 lvlProgress, uint16 modF, uint8 skillCredits, bytes22 details);
}