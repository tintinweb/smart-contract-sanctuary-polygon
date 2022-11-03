// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "./PolyERC721.sol"; 

import "../interfaces/Interfaces.sol";
import "../interfaces/WorldLike.sol";

contract EtherOrcsAlliesPoly is PolyERC721 {

    mapping(uint256 => Ally)      public allies;
    mapping(address => bool)      public auth;
    mapping(uint256 => Action)    public activities;
    mapping(uint256 => Location)  public locations;
    mapping(uint256 => Adventure) public adventures;

    ERC20Like   zug;
    ERC20Like   boneShards;
    ERC1155Like potions;

    MetadataHandlerAllies metadaHandler;

    address raids;
    address castle;
    address gamingOracle;

    WorldLike world;

    bytes32 internal entropySauce;

    uint256 public constant POTION_ID = 1; 
    uint256 public constant DUMMY_ID  = 2; 

    // Action: 0 - Unstaked | 1 - Farming | 2 - Training
    struct Action  { address owner; uint88 timestamp; uint8 action; }

    struct Ally {uint8 class; uint16 level; uint32 lvlProgress; uint16 modF; uint8 skillCredits; bytes22 details;}

    struct Shaman {uint8 body; uint8 featA; uint8 featB; uint8 helm; uint8 mainhand; uint8 offhand;}
    struct Ogre   {uint8 body; uint8 mouth; uint8 nose;  uint8 eyes; uint8 armor; uint8 mainhand; uint8 offhand;}
    struct Rogue  {uint8 body; uint8 face; uint8 boots; uint8 pants; uint8 shirt; uint8 hair; uint8 armor; uint8 mainhand; uint8 offhand;}


    struct Adventure {uint64 seed; uint64 location; uint64 equipment;}

    struct Location { 
        uint8  minLevel; uint8  skillCost; uint16  cost; uint8 classAllowed;
        uint8 tier_1Prob;uint8 tier_2Prob; uint8 tier_3Prob; uint8 tier_1; uint8 tier_2; uint8 tier_3; 
    }

    event ActionMade(address owner, uint256 id, uint256 timestamp, uint8 activity);

    /*///////////////////////////////////////////////////////////////
                    MODIFIERS 
    //////////////////////////////////////////////////////////////*/

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly { size := extcodesize(acc)}

        require(auth[msg.sender] || (msg.sender == tx.origin && size == 0), "you're trying to cheat!");
        _;

        // We'll use the last caller hash to add entropy to next caller
        entropySauce = keccak256(abi.encodePacked(acc, block.coinbase));
    }

    modifier ownerOfAlly(uint256 id, address who_) { 
        require(ownerOf[id] == who_ || activities[id].owner == who_, "not your ally");
        _;
    }

    modifier isOwnerOfAlly(uint256 id) {
         require(ownerOf[id] == msg.sender || activities[id].owner == msg.sender, "not your ally");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                    PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function initialize(address zug_, address shr_, address potions_, address raids_, address castle_, address gamingOracle_) external {
        require(msg.sender == admin);

        zug          = ERC20Like(zug_);
        potions      = ERC1155Like(potions_);
        boneShards   = ERC20Like(shr_);
        raids        = raids_;
        castle       = castle_;
        gamingOracle = gamingOracle_;
    }

    function setLocations() external {
        require(msg.sender == admin, "not admin");

        // {
        //     Location memory swampHealerHut    = Location({minLevel:25, skillCost: 5, cost:  0, classAllowed: 1, tier_1Prob:88, tier_2Prob:10, tier_3Prob:2, tier_1:1, tier_2:2, tier_3:3});
        //     Location memory enchantedGrove    = Location({minLevel:31, skillCost: 5, cost:  0, classAllowed: 1, tier_1Prob:50, tier_2Prob:40, tier_3Prob:10, tier_1:1, tier_2:2, tier_3:3});
        //     Location memory jungleHealerHut   = Location({minLevel:35, skillCost: 25, cost:  0, classAllowed: 1, tier_1Prob:85, tier_2Prob:10, tier_3Prob:5, tier_1:3, tier_2:4, tier_3:5});
        //     Location memory monkTemple        = Location({minLevel:35, skillCost: 20, cost:  0, classAllowed: 1, tier_1Prob:80, tier_2Prob:20, tier_3Prob:0, tier_1:2, tier_2:5, tier_3:5});
        //     Location memory forgottenDesert   = Location({minLevel:40, skillCost: 35, cost:  0, classAllowed: 1, tier_1Prob:85, tier_2Prob:10, tier_3Prob:5, tier_1:4, tier_2:5, tier_3:6});
        //     Location memory moldyCitadel      = Location({minLevel:45, skillCost: 30, cost:  0, classAllowed: 1, tier_1Prob:75, tier_2Prob:25, tier_3Prob:0, tier_1:3, tier_2:6, tier_3:6});
        //     Location memory swampEnchanterDen = Location({minLevel:55, skillCost: 45, cost:  200, classAllowed: 1, tier_1Prob:40, tier_2Prob:60, tier_3Prob:0, tier_1:3, tier_2:6, tier_3:0});
        //     Location memory theFallsOfTruth   = Location({minLevel:55, skillCost: 45, cost:  200, classAllowed: 1, tier_1Prob:70, tier_2Prob:30, tier_3Prob:0, tier_1:4, tier_2:7, tier_3:0});
        //     Location memory ethereanPlains    = Location({minLevel:60, skillCost: 50, cost:  200, classAllowed: 1, tier_1Prob:80, tier_2Prob:15, tier_3Prob:5, tier_1:5, tier_2:6, tier_3:7});
        //     Location memory djinnOasis        = Location({minLevel:60, skillCost: 10, cost:  150, classAllowed: 1, tier_1Prob:70, tier_2Prob:25, tier_3Prob:5, tier_1:2, tier_2:3, tier_3:4});
        //     locations[0] = swampHealerHut;
        //     locations[1] = enchantedGrove;
        //     locations[2] = jungleHealerHut;
        //     locations[3] = monkTemple;
        //     locations[4] = forgottenDesert;
        //     locations[5] = moldyCitadel;
        //     locations[6] = swampEnchanterDen;
        //     locations[7] = theFallsOfTruth;
        //     locations[8] = ethereanPlains;
        //     locations[9] = djinnOasis;
        // }
        
        // {
        //     Location memory spiritWorld       = Location({minLevel:70, skillCost: 60, cost:  300, classAllowed: 1, tier_1Prob:30, tier_2Prob:30, tier_3Prob:40, tier_1:5, tier_2:6, tier_3:7});
        //     Location memory assassin          = Location({minLevel:30, skillCost: 5, cost:  25, classAllowed: 2, tier_1Prob:92, tier_2Prob:0, tier_3Prob:8, tier_1:1, tier_2:1, tier_3:5}); 
        //     Location memory plainsGolem       = Location({minLevel:35, skillCost: 10, cost:  0, classAllowed: 2, tier_1Prob:30, tier_2Prob:30, tier_3Prob:40, tier_1:2, tier_2:3, tier_3:4}); 
        //     Location memory lostYeti          = Location({minLevel:45, skillCost: 10, cost:  0, classAllowed: 2, tier_1Prob:55, tier_2Prob:40, tier_3Prob:5, tier_1:2, tier_2:4, tier_3:5}); 
        //     Location memory giantSpider       = Location({minLevel:45, skillCost: 20, cost:  0, classAllowed: 2, tier_1Prob:65, tier_2Prob:25, tier_3Prob:10, tier_1:3, tier_2:4, tier_3:5}); 
        //     Location memory wolf              = Location({minLevel:50, skillCost: 10, cost:  0, classAllowed: 2, tier_1Prob:90, tier_2Prob:0, tier_3Prob:10, tier_1:3, tier_2:3, tier_3:5}); 
        //     Location memory beholder          = Location({minLevel:50, skillCost: 10, cost:  45, classAllowed: 2, tier_1Prob:85, tier_2Prob:10, tier_3Prob:5, tier_1:3, tier_2:5, tier_3:6}); 
        //     Location memory serpent           = Location({minLevel:60, skillCost: 15, cost:  60, classAllowed: 2, tier_1Prob:90, tier_2Prob:0, tier_3Prob:10, tier_1:3, tier_2:3, tier_3:6}); 
        //     Location memory machine           = Location({minLevel:65, skillCost: 35, cost:  90, classAllowed: 2, tier_1Prob:60, tier_2Prob:20, tier_3Prob:20, tier_1:3, tier_2:5, tier_3:6});
        //     locations[10] = spiritWorld;
        //     locations[11] = assassin;
        //     locations[12] = plainsGolem;
        //     locations[13] = lostYeti;
        //     locations[14] = giantSpider;
        //     locations[15] = wolf;
        //     locations[16] = beholder;
        //     locations[17] = serpent;
        //     locations[18] = machine;
        // }

        locations[19] = Location({minLevel:85, skillCost: 30, cost: 0,  classAllowed: 3, tier_1Prob:85, tier_2Prob:15, tier_3Prob:0, tier_1:3, tier_2:4, tier_3:4});
        locations[20] = Location({minLevel:85, skillCost: 30, cost: 0,  classAllowed: 3, tier_1Prob:50, tier_2Prob:50, tier_3Prob:0, tier_1:0, tier_2:5, tier_3:5});
        locations[21] = Location({minLevel:85, skillCost: 30, cost: 0,  classAllowed: 3, tier_1Prob:75, tier_2Prob:25, tier_3Prob:0, tier_1:0, tier_2:6, tier_3:6});
        locations[22] = Location({minLevel:85, skillCost: 3,  cost: 80, classAllowed: 3, tier_1Prob:50, tier_2Prob:50, tier_3Prob:0, tier_1:2, tier_2:3, tier_3:3});
    }

    function setAuth(address add_, bool status) external {
        require(msg.sender == admin);
        auth[add_] = status;
    }

    function tokenURI(uint256 id) external view returns(string memory) {
        Ally memory ally = allies[id];
        return metadaHandler.getTokenURI(id, ally.class, ally.level, ally.modF, ally.skillCredits, ally.details);
    }

    function claimable(uint256 id) external view returns (uint256 amount) {
        uint256 timeDiff = block.timestamp > activities[id].timestamp ? uint256(block.timestamp - activities[id].timestamp) : 0;
        amount = activities[id].action == 1 ? _claimable(timeDiff, allies[id].modF) : timeDiff * 3000 / 1 days;
    }

    function transfer(address to, uint256 tokenId) external {
        require(auth[msg.sender], "not authorized");
        require(msg.sender == ownerOf[tokenId], "NOT_OWNER");
        
        _transfer(msg.sender, to, tokenId);
    }

    function doAction(uint256 id, uint8 action_) public ownerOfAlly(id, msg.sender) {
       _doAction(id, msg.sender, action_, msg.sender);
    }

    function _doAction(uint256 id, address allyOwner, uint8 action_, address who_) internal ownerOfAlly(id, who_) {
        require(action_ < 3, "invalid action");
        Action memory action = activities[id];
        require(action.action != action_, "already doing that");

        uint88 timestamp = uint88(block.timestamp > action.timestamp ? block.timestamp : action.timestamp);

        if (action.action == 0)  _transfer(allyOwner, address(this), id);
     
        else {
            if (block.timestamp > action.timestamp) _claim(id);
            timestamp = timestamp > action.timestamp ? timestamp : action.timestamp;
        }

        address owner_ = action_ == 0 ? address(0) : allyOwner;
        if (action_ == 0) _transfer(address(this), allyOwner, id);

        activities[id] = Action({owner: owner_, action: action_,timestamp: timestamp});
        emit ActionMade(allyOwner, id, block.timestamp, uint8(action_));
    }

    function doActionWithManyAllies(uint256[] calldata ids, uint8 action_) external {
        for (uint256 index = 0; index < ids.length; index++) {
            _doAction(ids[index], msg.sender, action_, msg.sender);
        }
    }

    function startAdventureWithMany(uint256[] calldata ids, uint8 place, uint8 equipment) external {
        for (uint256 index = 0; index < ids.length; index++) {
            startAdventure(ids[index], place, equipment);
        }
    }

    function endAdventureWithMany(uint256[] calldata ids) external {
        for (uint256 index = 0; index < ids.length; index++) {
            endAdventure(ids[index]);
        }
    }

    function claim(uint256[] calldata ids) external {
        for (uint256 index = 0; index < ids.length; index++) {
            _claim(ids[index]);
        }
    }

    function _claim(uint256 id) internal {
        Action memory action = activities[id];
        Ally   memory ally   = allies[id];

        if(block.timestamp <= action.timestamp) return;

        uint256 timeDiff = uint256(block.timestamp - action.timestamp);

        if (action.action == 2) {
            allies[id].lvlProgress += uint32(timeDiff * 3000 / 1 days);
            allies[id].level        = uint16(allies[id].lvlProgress / 1000);
        }

        activities[id].timestamp = uint88(block.timestamp);
    }

    function startAdventure(uint256 id, uint8 place, uint8 equipment) public isOwnerOfAlly(id) {
        require(equipment < 3, "invalid equipment");
        require(adventures[id].seed == 0, "already ongoin journey");

        if(activities[id].timestamp < block.timestamp) _claim(id);

        Ally     memory ally = allies[id];
        Location memory loc  = locations[place];

        require(loc.classAllowed == ally.class, "wrong location for class");
        require(ally.level >= uint16(loc.minLevel), "below minimum level");
        
        allies[id].skillCredits -= loc.skillCost;
  
        if (loc.cost > 0) {
            zug.burn(msg.sender, uint256(loc.cost) * 1 ether);
        } 

        adventures[id] = Adventure({seed: OracleLike(gamingOracle).request(), location: place, equipment: equipment});
    }

    function endAdventure(uint256 id) public isOwnerOfAlly(id) {
        Adventure memory adv  = adventures[id];
        Ally      memory ally = allies[id];
        Location  memory loc  = locations[adv.location];

        uint256 rdn = OracleLike(gamingOracle).getRandom(adv.seed);
        require(rdn != 0, "too soon");

        if(activities[id].timestamp < block.timestamp) _claim(id); // Need to claim to not have equipment reatroactively multiplying

        bytes22 newDetails = ally.class == 1 ? _equipShaman(loc, ally.details, adv.equipment, rdn) : ally.class == 2 ? _equipOgre(loc, ally.details, adv.equipment, rdn) : _equipRogue(loc, ally.details, adv.equipment, rdn);

        allies[id].details = newDetails;
        allies[id].modF    = ally.class == 1 ? _modFSh(newDetails) : ally.class == 2 ? _modFOg(newDetails) : _modFRg(newDetails);

        delete adventures[id];
    }

    function sendToRaid(uint256[] calldata ids, uint8 location_, bool double_,uint256[] calldata potions_, uint256[] calldata runes_) external { 
        require(address(raids) != address(0), "raids not set");
        for (uint256 index = 0; index < ids.length; index++) {
            if (activities[ids[index]].action != 0) _doAction(ids[index], msg.sender, 0, msg.sender);
            _transfer(msg.sender, raids, ids[index]);
        }
        RaidsLikePoly(raids).stakeManyAndStartCampaign(ids, msg.sender, location_, double_,potions_, runes_ );
    }

    function startRaidCampaign(uint256[] calldata ids, uint8 location_, bool double_,  uint256[] calldata potions_, uint256[] calldata runes_) external { 
        require(address(raids) != address(0), "raids not set");
        for (uint256 index = 0; index < ids.length; index++) {
            require(msg.sender == RaidsLikePoly(raids).commanders(ids[index]) && ownerOf[ids[index]] == address(raids), "not staked or not your orc");
        }
        RaidsLikePoly(raids).startCampaignWithMany(ids, location_, double_, potions_, runes_);
    }

    function returnFromRaid(uint256[] calldata ids, uint8 action_) external { 
        require(action_ < 3, "invalid action");
        RaidsLikePoly raidsContract = RaidsLikePoly(raids);
        for (uint256 index = 0; index < ids.length; index++) {
            require(msg.sender == raidsContract.commanders(ids[index]), "not your orc");
            raidsContract.unstake(ids[index]);
            if (action_ != 0) _doAction(ids[index], msg.sender, action_, msg.sender);
        }
    }

    function pull(address owner_, uint256[] calldata ids) external {
        require (auth[msg.sender], "not authed");
        for (uint256 index = 0; index < ids.length; index++) {
            if (activities[ids[index]].action != 0) _doAction(ids[index], owner_, 0, owner_);

            // If farming in the new world contract, end farming for convenience.
            // Location of `1` is farming
            //
            if(address(world) != address(0)
                && msg.sender != address(world)
                && world.locationForStakedEntity(ids[index]) == 1
                && world.ownerForStakedEntity(ids[index]) == owner_)
            {
                world.adminTransferEntityOutOfWorld(owner_, uint16(ids[index]));
            }

            _transfer(owner_, msg.sender, ids[index]);
        }
        CastleLike(msg.sender).pullCallback(owner_, ids);
    }

    function adjustAlly(uint256 id, uint8 class_, uint16 level_, uint32 lvlProgress_, uint16 modF_, uint8 skillCredits_, bytes22 details_) external {
        require(auth[msg.sender], "not authorized");

        allies[id] = Ally({class: class_, level: level_, lvlProgress: lvlProgress_, modF: modF_, skillCredits: skillCredits_, details: details_});
    }

    function setMetadataHandler(address add) external {
        require(msg.sender == admin);
        metadaHandler = MetadataHandlerAllies(add);
    }

    function initMint(address to, uint256 start, uint256 end) external {
        require(msg.sender == admin);
        for (uint256 i = start; i < end; i++) {
            _mint( to, i);
        }
    }

    function setWorld(address worldAddress) external {
        require(msg.sender == admin);
        world = WorldLike(worldAddress);
    }

    function rogue(bytes22 details) public pure returns(Rogue memory rg) {
        uint8 body     = uint8(bytes1(details));
        uint8 face     = uint8(bytes1(details << 8));
        uint8 boots    = uint8(bytes1(details << 16));
        uint8 pants    = uint8(bytes1(details << 24));
        uint8 shirt    = uint8(bytes1(details << 32));
        uint8 hair     = uint8(bytes1(details << 40));
        uint8 armor    = uint8(bytes1(details << 48));
        uint8 mainhand = uint8(bytes1(details << 56));
        uint8 offhand  = uint8(bytes1(details << 64));

        rg.body     = body;
        rg.face     = face;
        rg.armor    = armor;
        rg.mainhand = mainhand;
        rg.offhand  = offhand;
        rg.boots    = boots;
        rg.pants    = pants;
        rg.shirt    = shirt;
        rg.hair     = hair;
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _shaman(bytes22 details) internal pure returns(Shaman memory sh) {
        uint8 body     = uint8(bytes1(details));
        uint8 featA    = uint8(bytes1(details << 8));
        uint8 featB    = uint8(bytes1(details << 16));
        uint8 helm     = uint8(bytes1(details << 24));
        uint8 mainhand = uint8(bytes1(details << 32));
        uint8 offhand  = uint8(bytes1(details << 40));

        sh.body     = body;
        sh.featA    = featA;
        sh.featB    = featB;
        sh.helm     = helm;
        sh.mainhand = mainhand;
        sh.offhand  = offhand;
    }

    function _ogre(bytes22 details) internal pure returns(Ogre memory og) {
        uint8 body     = uint8(bytes1(details));
        uint8 mouth    = uint8(bytes1(details << 8));
        uint8 nose     = uint8(bytes1(details << 16));
        uint8 eye      = uint8(bytes1(details << 24));
        uint8 armor    = uint8(bytes1(details << 32));
        uint8 mainhand = uint8(bytes1(details << 40));
        uint8 offhand  = uint8(bytes1(details << 48));

        og.body     = body;
        og.mouth    = mouth;
        og.nose     = nose;
        og.eyes     = eye;
        og.armor    = armor;
        og.mainhand = mainhand;
        og.offhand  = offhand;
    }

    function _equipShaman(Location memory loc, bytes22 details_, uint256 equipment, uint256 rdn) internal pure returns(bytes22 details) {
        uint8 item  = _getItemSh(loc, rdn);

        Shaman memory sh = _shaman(details_);

        if (equipment == 0) sh.helm = item;
        if (equipment == 1) sh.mainhand = item;
        if (equipment == 2) sh.offhand = item;

        details = bytes22(abi.encodePacked(sh.body, sh.featA, sh.featB, sh.helm, sh.mainhand, sh.offhand));
    }

    function _equipOgre(Location memory loc, bytes22 details_, uint256 equipment, uint256 rdn) internal pure returns(bytes22 details) {
        uint8 item  = _getItemOg(loc, rdn);

        Ogre memory og = _ogre(details_);

        if (equipment == 0) og.armor    = item;
        if (equipment == 1) og.mainhand = item;
        if (equipment == 2) og.offhand  = item;

        details = bytes22(abi.encodePacked(og.body, og.mouth, og.nose, og.eyes, og.armor, og.mainhand, og.offhand));
    }

    function _equipRogue(Location memory loc, bytes22 details_, uint256 equipment, uint256 rdn) internal pure returns(bytes22 details) {
        uint8 item  = _getItemRg(loc, rdn);

        Rogue memory rg = rogue(details_);

        if (equipment == 0) rg.armor    = item;
        if (equipment == 1) rg.mainhand = item;
        if (equipment == 2) rg.offhand  = item;

        details = bytes22(abi.encodePacked(rg.body, rg.face, rg.boots, rg.pants, rg.shirt, rg.hair, rg.armor, rg.mainhand, rg.offhand));
    }

    function _modFSh(bytes32 details_) internal pure returns (uint16 mod) {
        uint8 helm     = uint8(bytes1(details_ << 24));
        uint8 mainhand = uint8(bytes1(details_ << 32));
        uint8 offhand  = uint8(bytes1(details_ << 40));

        mod = _tierSh(helm) + _tierSh(mainhand) + _tierSh(offhand);
    }

    function _modFOg(bytes32 details_) internal pure returns (uint16 mod) {
        uint8 armor    = uint8(bytes1(details_ << 32));
        uint8 mainhand = uint8(bytes1(details_ << 40));
        uint8 offhand  = uint8(bytes1(details_ << 48));

        mod = _tierOg(armor) + _tierOg(mainhand) + _tierOg(offhand);
    }

    function _modFRg(bytes32 details_) internal pure returns (uint16 mod) {
        uint8 armor    = uint8(bytes1(details_ << 48));
        uint8 mainhand = uint8(bytes1(details_ << 56));
        uint8 offhand  = uint8(bytes1(details_ << 64));

        mod = _tierRg(armor) + _tierRg(mainhand) + _tierRg(offhand);
    }

    function _getItemSh(Location memory loc, uint256 rand) internal pure returns (uint8 item) {
        uint256 draw = uint256(rand % 100) + 1;

        uint8 tier = uint8(draw <= loc.tier_3Prob ? loc.tier_3 : draw <= loc.tier_2Prob + loc.tier_3Prob? loc.tier_2 : loc.tier_1);
        item = uint8(rand % _tierItemsSh(tier) + _startForTierSh(tier));
    }

    function _getItemOg(Location memory loc, uint256 rand) internal pure returns (uint8 item) {
        uint256 draw = uint256(rand % 100) + 1;

        uint8 tier = uint8(draw <= loc.tier_3Prob ? loc.tier_3 : draw <= loc.tier_2Prob + loc.tier_3Prob? loc.tier_2 : loc.tier_1);
        item = uint8(rand % _tierItemsOg(tier) + _startForTierOg(tier));
    }

    function _getItemRg(Location memory loc, uint256 rand) internal pure returns (uint8 item) {
        uint256 draw = uint256(rand % 100) + 1;

        uint8 tier = uint8(draw <= loc.tier_3Prob ? loc.tier_3 : draw <= loc.tier_2Prob + loc.tier_3Prob? loc.tier_2 : loc.tier_1);
        if (tier == 0) return 0;
        item = uint8(rand % _tierItemsRg(tier) + _startForTierRg(tier));
    }

    function _claimable(uint256, uint256) internal pure returns (uint256) {
        return 0;
    }

    function _tierSh(uint8 item) internal pure returns (uint8 tier) {
        if (item <= 7) return 0;
        if (item <= 12) return 1;
        if (item <= 18) return 2;
        if (item <= 25) return 3;
        if (item <= 32) return 4;
        if (item <= 38) return 5;
        if (item <= 44) return 6;
        return 7;
    } 

    function _tierItemsSh(uint256 tier_) internal pure returns (uint256 numItems) {
        if (tier_ == 0) return 7;
        if (tier_ == 1) return 5;
        if (tier_ == 2) return 6;
        if (tier_ == 3) return 7;
        if (tier_ == 4) return 7;
        if (tier_ == 5) return 6;
        if (tier_ == 6) return 6;
        return 6;
    }

    function _startForTierSh(uint256 tier_) internal pure returns (uint256 start) {
        if (tier_ == 0) return 1;
        if (tier_ == 1) return 8;
        if (tier_ == 2) return 13;
        if (tier_ == 3) return 19;
        if (tier_ == 4) return 26;
        if (tier_ == 5) return 33;
        if (tier_ == 6) return 39;
        return 45;
    }       

    function _tierOg(uint8 item) internal pure returns (uint8 tier) {
        if (item <= 6) return 0;
        if (item <= 9) return 1;
        if (item <= 14) return 2;
        if (item <= 20) return 3;
        if (item <= 26) return 4;
        if (item <= 31) return 5;
        return 6;
    } 

    function _tierItemsOg(uint256 tier_) internal pure returns (uint256 numItems) {
        if (tier_ == 0) return 6;
        if (tier_ == 1) return 3;
        if (tier_ == 2) return 5;
        if (tier_ == 3) return 6;
        if (tier_ == 4) return 6;
        if (tier_ == 5) return 5;
        if (tier_ == 6) return 4;
    }

    function _startForTierOg(uint256 tier_) internal pure returns (uint256 start) {
        if (tier_ == 0) return 1;
        if (tier_ == 1) return 7;
        if (tier_ == 2) return 10;
        if (tier_ == 3) return 15;
        if (tier_ == 4) return 21;
        if (tier_ == 5) return 27;
        if (tier_ == 6) return 32;
    }

    function _tierRg(uint8 item) internal pure returns (uint8 tier) {
        if (item == 0)  return 0;
        if (item <= 5)  return 2;
        if (item <= 15) return 3;
        if (item <= 21) return 4;
        if (item <= 28) return 5;
        if (item <= 35) return 6;
    } 

    function _tierItemsRg(uint256 tier_) internal pure returns (uint256 numItems) {
        if (tier_ == 0) return 0;
        if (tier_ == 1) return 0;
        if (tier_ == 2) return 5;
        if (tier_ == 3) return 10;
        if (tier_ == 4) return 6;
        if (tier_ == 5) return 7;
        if (tier_ == 6) return 7;
    }

    function _startForTierRg(uint256 tier_) internal pure returns (uint256 start) {
        if (tier_ == 0) return 0;
        if (tier_ == 1) return 0;
        if (tier_ == 2) return 1;
        if (tier_ == 3) return 6;
        if (tier_ == 4) return 16;
        if (tier_ == 5) return 22;
        if (tier_ == 6) return 29;
    }       
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation,
/// including the MetaData, and partially, Enumerable extensions.
contract PolyERC721 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    
    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);
    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/
    
    address        implementation_;
    address public admin; //Lame requirement from opensea
    
    /*///////////////////////////////////////////////////////////////
                             ERC-721 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;
    uint256 public oldSupply;
    uint256 public minted;
    
    mapping(address => uint256) public balanceOf;
    
    mapping(uint256 => address) public ownerOf;
        
    mapping(uint256 => address) public getApproved;
 
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             VIEW FUNCTION
    //////////////////////////////////////////////////////////////*/

    function owner() external view returns (address) {
        return admin;
    }
    
    /*///////////////////////////////////////////////////////////////
                              ERC-20-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/
    
    // function transfer(address to, uint256 tokenId) external {
    //     require(msg.sender == ownerOf[tokenId], "NOT_OWNER");
        
    //     _transfer(msg.sender, to, tokenId);
        
    // }
    
    /*///////////////////////////////////////////////////////////////
                              ERC-721 LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
        supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }
    
    // function approve(address spender, uint256 tokenId) external {
    //     address owner_ = ownerOf[tokenId];
        
    //     require(msg.sender == owner_ || isApprovedForAll[owner_][msg.sender], "NOT_APPROVED");
        
    //     getApproved[tokenId] = spender;
        
    //     emit Approval(owner_, spender, tokenId); 
    // }
    
    // function setApprovalForAll(address operator, bool approved) external {
    //     isApprovedForAll[msg.sender][operator] = approved;
        
    //     emit ApprovalForAll(msg.sender, operator, approved);
    // }

    // function transferFrom(address, address to, uint256 tokenId) public {
    //     address owner_ = ownerOf[tokenId];
        
    //     require(
    //         msg.sender == owner_ 
    //         || msg.sender == getApproved[tokenId]
    //         || isApprovedForAll[owner_][msg.sender], 
    //         "NOT_APPROVED"
    //     );
        
    //     _transfer(owner_, to, tokenId);
        
    // }
    
    // function safeTransferFrom(address, address to, uint256 tokenId) external {
    //     safeTransferFrom(address(0), to, tokenId, "");
    // }
    
    // function safeTransferFrom(address, address to, uint256 tokenId, bytes memory data) public {
    //     transferFrom(address(0), to, tokenId); 
        
    //     if (to.code.length != 0) {
    //         // selector = `onERC721Received(address,address,uint,bytes)`
    //         (, bytes memory returned) = to.staticcall(abi.encodeWithSelector(0x150b7a02,
    //             msg.sender, address(0), tokenId, data));
                
    //         bytes4 selector = abi.decode(returned, (bytes4));
            
    //         require(selector == 0x150b7a02, "NOT_ERC721_RECEIVER");
    //     }
    // }
    
    /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf[tokenId] == from, "not owner");

        balanceOf[from]--; 
        balanceOf[to]++;
        
        delete getApproved[tokenId];
        
        ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId); 

    }

    function _mint(address to, uint256 tokenId) internal { 
        require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");

        uint supply = oldSupply + minted;
        uint maxSupply = 5050;
        require(supply <= maxSupply, "MAX SUPPLY REACHED");
        totalSupply++;
                
        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to]++;
        }
        
        ownerOf[tokenId] = to;
                
        emit Transfer(address(0), to, tokenId); 
    }
    
    function _burn(uint256 tokenId) internal { 
        address owner_ = ownerOf[tokenId];
        
        require(ownerOf[tokenId] != address(0), "NOT_MINTED");
        
        totalSupply--;
        balanceOf[owner_]--;
        
        delete ownerOf[tokenId];
                
        emit Transfer(owner_, address(0), tokenId); 
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

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

interface WorldLike {
    function locationForStakedEntity(uint256 _tokenId) external view returns(uint8);

    function ownerForStakedEntity(uint256 _tokenId) external view returns(address);

    function balanceOf(address _owner) external view returns (uint256);

    function adminTransferEntityOutOfWorld(
        address _originalOwner,
        uint16 _tokenId)
    external;
}

// Do not use. Otherwise, anytime a new location was added, we would need to upgrade the old contracts with the new enum value.
// Instead, we'll look at the raw uint8.
//
// enum Location {
//     NOT_STAKED,
//     ACTIVE_FARMING
// }