//SPDX-License-Identifier: MIT
//Dungeons.sol
/**
    @title Dungeons
    @author Eman @SgtChiliPapi
    @notice: This contract keeps track of pending PVE battles and provides logic for completing them.
    Originally created for CHAINLINK HACKATHON FALL 2022
*/
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../periphery/libraries/structs/CharacterStructs.sol";
import "../../periphery/libraries/structs/EnemyStructs.sol";
import "../../periphery/libraries/structs/GlobalStructs.sol";
import "../../periphery/libraries/structs/EquipmentStructs.sol";
import "../../periphery/libraries/structs/DungeonStructs.sol";
import "../../periphery/libraries/characters/CharacterStatsCalculator.sol";
import "../../periphery/libraries/enemies/EnemyStatsCalculator.sol";
import "../../periphery/utils/BattleMath.sol";
import "../../periphery/utils/BreakdownUint256.sol";
import "../../periphery/libraries/materials/DungeonMaterials.sol";
import "../../periphery/libraries/characters/CharacterExperience.sol";

interface _RandomizationContract {
    function requestRandomWords(address user, uint32 numWords, bool experimental) external returns (uint256 requestId);
    function getRequestStatus(uint256 _requestId) external view returns(bool fulfilled, uint256[] memory randomWords);
}
interface _Characters{
    function isOwner(address _owner, uint256 _character) external view returns (bool);
    function character(uint256 _character_id) external view returns (character_properties memory);
    function updateCharacter(uint256 tokenId, character_properties memory updated_props) external;
}

interface _Equipments{
    function stats(uint256 _equipment_id) external view returns (battle_stats memory);
}

interface _EquipmentManager{
    function equippedWith(uint256 character_id) external view returns (character_equipments memory);
}

interface _MaterialToken{
    function mint(address to, uint256 amount) external;
}

interface _EnerLink{
    function burnFrom(address account, uint256 amount) external;
}

///@notice This contract keeps track of pending PVE battles and provides logic for completing them.
///A battle consists of two (2) steps/transactions from the player:
///1. Request a battle using `findBattle()` - Its main function is to request random numbers from the VRF.
///2. Fulfill the battle request using `startBattle()` - Its main function is to simulate the battle on-chain and to apply the 
///effects of the battle result.

contract Dungeons is Ownable{
    _RandomizationContract private vrf_contract;
    _Characters private characters;
    _Equipments private equipments;
    _EquipmentManager private equipment_manager;
    _EnerLink private enerlink;

    ///The beneficiary of the msg.value being sent to the contract for every battle request.
    address private vrf_refunder;

    ///The msg.value required to mint to prevent spam and deplete VRF funds
    ///Currently unset (0) for judging purposes as stated in the hackathon rules.
    uint256 private battle_fee;

    ///This value represents the rate of energy restoration for every character.
    ///In this implementation, it shall be set at 5 energy per minute.
    ///Each battle would consume 100 energy.
    uint256 private constant ENERGY_RES_RATE = 5;

    ///This maps the battle requests made to the senders who made them. Only one request per sender is allowed.
    ///Once the sender has an outstanding request, he/she should complete the battle before sending another request.
    mapping(address => battle_request) public battle_requests;

    ///This maps the energy balances of characters to their respective character_ids. Specifying the last updated balance and
    ///the time it was last updated.
    mapping(uint256 => last_energy_update) public energy_balances;

    ///Arrays of addresses for the materials and catalyst tokens
    address[4] private materials_addresses;

    ///Supply cap of each dungeon every 3 hours
    mapping(uint256 => uint256) public dungeon_loot_remaining;
    mapping(uint256 => uint256) public dungeon_loot_cap;

    ///The keepers compatible contract that replenishes the dungeon loot supply
    address dungeonKeeper;

    event BattleRequested(address indexed user, battle_request request);
    event BattleStarted(battle_request indexed request, character_properties char_pros, battle_stats character, enemy_properties enemy_props, battle_stats enemy);
    event Clashed(uint256 indexed battle_id, clash_event clash);
    event BattleEnded(uint256 indexed battle_id, uint256 battle_result);
    event DungeonsReplenished(uint256 dungeon1, uint256 dungeon2, uint256 dungeon3);

    constructor(
        address charactersNftAddress, 
        address equipmentNftAddress, 
        address equipmentManagerAddress,
        address[4] memory materials,
        address enerlinkAddress
    ){
        characters = _Characters(charactersNftAddress);
        equipments = _Equipments(equipmentNftAddress);
        equipment_manager = _EquipmentManager(equipmentManagerAddress);
        materials_addresses = materials;
        enerlink = _EnerLink(enerlinkAddress);
        vrf_refunder = msg.sender;
        dungeon_loot_remaining[0] = 844;
        dungeon_loot_remaining[1] = 844;
        dungeon_loot_remaining[2] = 844;
        dungeon_loot_cap[0] = 844;
        dungeon_loot_cap[1] = 844;
        dungeon_loot_cap[2] = 844;
    }

    ///@notice This function initiates a battle by requesting random numbers from the VRF and setting the battle parameters:
    ///The character that would be sent into the dungeon to fight, the dungeon and the specific tier in that dungeon.
    ///Once the request is sent, the sender would not be able to send another request until the request has been fulfilled AND
    ///the battle has been completed. That is the battle has been actually played out and its effects have been reflected in the contract's state.
    function findBattle(uint256 character_id, uint64 dungeon, uint64 tier) public payable{
        ///Ensure ownership of the character to be sent to battle
        require(characters.isOwner(msg.sender, character_id), "Dungeons: Character not owned");

        ///Ensure the proper parameters are sent
        require(dungeon < 3 && tier < 5, "Dungeons: Ivalid dungeon/tier");

        ///Ensure that enough value is being sent
        require(msg.value >= battle_fee, "Dungeons: Insufficient amount sent.");

        ///Ensure that the character's energy is enough
        uint256 character_energy = getCharacterEnergy(character_id);
        require(character_energy >= 100, "Dungeons: Not enough energy.");

        ///Update the character's current energy immediately
        energy_balances[character_id].energy = BattleMath.safeMinusUint256(character_energy, 100);
        energy_balances[character_id].time_last_updated = block.timestamp;

        ///Get the maximum amount currently available for the dungeon
        (,, uint256 max_amount) = DungeonMaterials.getDungeonMaterials(dungeon, tier);
        uint256 loot_remaining = dungeon_loot_remaining[dungeon];
        if(loot_remaining < max_amount){
            max_amount = loot_remaining;
        }
        ///Update the dungeon's remaining loot
        dungeon_loot_remaining[dungeon] = BattleMath.safeMinusUint256(loot_remaining, max_amount);

        ///Map the battle request parameters to the sender's address
        battle_requests[msg.sender] = battle_request({
            request_id: vrf_contract.requestRandomWords(msg.sender, uint32(11), false),
            dungeon_type: dungeon,
            tier: tier,
            result: 0,
            max_loot: uint64(max_amount),
            character_id: character_id,
            completed: false
        });

        emit BattleRequested(msg.sender, battle_requests[msg.sender]);
    }

    ///@notice This function calculates for the character's energy balance
    function getCharacterEnergy(uint256 character_id) public view returns (uint256 character_energy){
        uint256 time_elapsed = (BattleMath.safeMinusUint256(block.timestamp, energy_balances[character_id].time_last_updated)) / 60;
        character_energy = BattleMath.safeAddUint256(energy_balances[character_id].energy, (time_elapsed * ENERGY_RES_RATE), 1000);
    }

    ///@notice This function completes the battle and reflects its effects in the contract's state.
    function startBattle() public {
        ///Load the sender's previous request
        battle_request memory request = battle_requests[msg.sender];

        ///Get the status of the randomWords using the request's id
        (bool fulfilled, uint256[] memory random_words) = vrf_contract.getRequestStatus(request.request_id);
        require(fulfilled, "Dungeons: Not yet fulfilled.");

        ///Break 1 uint256 randomWord into 16 uint16 numbers for calculating battle contingencies.
        uint16[] memory random_set1 = BreakdownUint256.break256BitsIntegerIntoBytesArrayOf16Bits(random_words[0]);

        ///Get the properties of the character primarily to determine character class.
        ///Get the stats of the character using the request's character_id property value.
        (character_properties memory char_props, battle_stats memory char_stats) = getCharacter(request.character_id);

        ///Calculate the enemy's stats within the requests parameters and 2 random uint16s
        (enemy_properties memory enem_props, battle_stats memory enem_stats) = EnemyStatsCalculator.getEnemy(request.dungeon_type, request.tier, random_set1[0], random_set1[1]);

        ///Set the enemy's handicap to only 25% for players/characters that are just starting out (exp with less than 220)
        if(char_props.exp < 220 && request.tier == 0){enem_stats.hp = (enem_stats.hp * 25) / 100;}

        emit BattleStarted(request, char_props, char_stats, enem_props, enem_stats);

        ///Check if the battle has been completed
        require(!request.completed, "Dungeons: Battle already completed.");

        ///Set the request as completed
        battle_requests[msg.sender].completed = true;

        ///Simulate the actual battle
        uint64 battle_result = simulateBattle(request.request_id, char_props, char_stats, enem_props, enem_stats, random_words);

        battle_requests[msg.sender].result = battle_result;

        ///The character only gets experience and attribute gains if he/she wins (1) or gets a draw (2).
        if(battle_result == 1 || battle_result == 2){
            ///@dev EXTCALL: Write to Character NFT contract the character's gain in experience and attributes from the battle if any.
            applyCharacterEffects(request, char_props);
        }

        ///The loot drops only if the character wins (1)
        if(battle_result == 1){
            getAndTransferLoot(request, random_set1[2], random_set1[3], random_set1[4], msg.sender);
        }

        restoreEnergy(request.character_id, char_stats.energy_restoration);

        emit BattleEnded(request.request_id, battle_result);
    }

    ///@notice This function fetches the character properties, stats and equipment and returns only the stats for use in battle.
    function getCharacter(uint256 character_id) internal view returns (character_properties memory char_props, battle_stats memory char_stats){
        ///Get the character properties from the Characters NFT contract
        char_props = characters.character(character_id);

        ///Calculate the stats of the character using its properties
        char_stats = CharacterStatsCalculator.getCharacter(char_props);

        ///Calculate the sum of all stats of the character's current equipments.
        battle_stats memory sum_eqpt_stats = getEquipmentsEffects(character_id);

        ///Mutate `char_stats` directly to combine the bare character stats and the sum of all equipment stats.
        combineStatEffects(char_stats, sum_eqpt_stats);
    }

    ///@notice This function sums up all of the equipment's stat effects.
    function getEquipmentsEffects(uint256 character_id) internal view returns (battle_stats memory sum_eqpt_stats){
        character_equipments memory char_eqpts = equipment_manager.equippedWith(character_id);
        combineEqptEffects(sum_eqpt_stats, equipments.stats(char_eqpts.headgear));
        combineEqptEffects(sum_eqpt_stats, equipments.stats(char_eqpts.armor));
        combineEqptEffects(sum_eqpt_stats, equipments.stats(char_eqpts.weapon));
        combineEqptEffects(sum_eqpt_stats, equipments.stats(char_eqpts.accessory));
    }

    ///@notice This function combines the stat effects of 2 set of equipment stats by directly mutating the first set.
    function combineEqptEffects(battle_stats memory stats1, battle_stats memory stats2) internal pure{
        stats1.atk += stats2.atk;
        stats1.def += stats2.def;
        stats1.eva += stats2.eva;
        stats1.hp += stats2.hp;
        stats1.pen += stats2.pen;
        stats1.crit += stats2.crit;
        stats1.luck += stats2.luck;
        stats1.energy_restoration += stats2.energy_restoration;
    }

    ///@notice This function combines the stat effects of 2 set of stats by directly mutating the first set.
    function combineStatEffects(battle_stats memory stats1, battle_stats memory stats2) internal pure{
        stats1.atk += stats2.atk;
        stats1.def += stats2.def;
        stats1.eva += stats2.eva;
        stats1.hp += stats2.hp;
        stats1.pen += stats2.pen;
        stats1.crit += stats2.crit;
        stats1.luck += stats2.luck;
        stats1.energy_restoration += stats2.energy_restoration;
    }

    ///@notice Simulate the actual battle using the character and enemy stats.
    function simulateBattle(
        uint256 battle_id,
        character_properties memory char_props,
        battle_stats memory char_stats,
        enemy_properties memory enem_props,
        battle_stats memory enem_stats,
        uint256[] memory random_nums
        ) internal returns (uint64 battle_result){
        ///Initiate a variable to serve as counter for how many back and forth attacks happened (character attacks -> enemy & enemy attacks -> character)
        uint256 clashCount;

        ///Loop through the uint256[] random_nums to be consumed all throughout the series of clashes
        for(uint256 i = 1; i < 11; i++){
            ///Every main loop iteration, break the current random_num into uint16s using the loop's index.
            uint16[] memory rnums = BreakdownUint256.break256BitsIntegerIntoBytesArrayOf16Bits(random_nums[i]);

            ///For every main loop iteration, consume all 16 uint16s within two (2) sub-loops.
            ///These sub-loops will consume 8 uint16s per iteration (4 uint16s per attack from either battling party).
            for(uint256 c = 0; c < 16; c+=8){
                ///Increment the clash counter
                clashCount++;
                ///Check if the battle hasn't ended yet.
                if(char_stats.hp > 0 && enem_stats.hp > 0 && clashCount <= 20){
                    clash_event memory clashed;
                    ///Apply character's damage to enemy's defense & hp effectively consuming 4 uint16 random numbers.
                    ///The first random number would be used to determine whether the attack would be evaded.
                    ///The second random number would be used to determine the actual attack damage within the character's damage range (min and max damage).
                    ///The third random number would be used to determine whether the attack would penetrate (slice through defense).
                    ///The fourth random number would be used to determine whether the attack would deal critical damage.
                    clashed.attack1 = attack(char_props.character_class, char_stats, enem_stats, [rnums[c], rnums[c+1], rnums[c+2], rnums[c+3]]);
                    ///Apply enemy's damage to character's defense & hp effectively consuming 4 uint16 random numbers.
                    clashed.attack2 = attack(enem_props._type, enem_stats, char_stats, [rnums[c+4], rnums[c+5], rnums[c+6], rnums[c+7]]);
                    emit Clashed(battle_id, clashed);
                }else{
                    ///In case the number of clash instances reached 20 times and both still have remaining hp left, the battle comes to a draw.
                    if(char_stats.hp > 0 && enem_stats.hp > 0 && clashCount > 20){battle_result = 2;}

                    ///In case the battlers get both hp to 0 within the same clash instance, the battle also comes to a draw.
                    if(char_stats.hp ==0 && enem_stats.hp == 0){battle_result = 2;}

                    ///Case where the character wins.
                    if(char_stats.hp > 0 && enem_stats.hp == 0){battle_result = 1;}

                    ///Case were the character loses.
                    if(char_stats.hp == 0 && enem_stats.hp > 0){battle_result = 0;}
                }
            }
        }
    }

    ///@notice Calculate the damage dealt and taken by the battlers in each attack.
    function attack(uint256 attacker_class, battle_stats memory attacker, battle_stats memory defender, uint16[4] memory random_numbers) internal pure returns(attack_event memory atk_ev){
        ///Initiate the following variables without values since we wont have to set these anyway if it turns out that the attack has been evaded.
        uint256 damage;
        bool penetrated;
        bool critical_hit;

        ///Determine whether the attack will be evaded by the defender.
        bool evaded = rollEvade(random_numbers[0], defender);

        ///Calculate the damage if the attack is not evaded.
        if(!evaded){
            ///Calculate the damage using a random num and the attacker's class/type
            damage = rollDamage(random_numbers[1], attacker, attacker_class);

            ///Determine whether the attack penetrates the defender's armor
            penetrated = rollPenetrate(random_numbers[2], attacker);

            ///Determine whether the attack does a critical hit/double damage
            critical_hit = rollCriticalHit(random_numbers[3], attacker);

            ///If the attack penetrates the armor, apply the damage (doesn't stack with critical hit) from the defender's HP
            if(penetrated){defender.hp = BattleMath.safeMinusUint256(defender.hp, damage);}

            ///If the attack does a critical hit, the damage is doubled.
            if(critical_hit){damage *= 2;}
            
            ///If the attack damage is greater than the defender's DEF, the excess shall be applied to the defender's HP but with half the amount only.
            ///This is the armor break effect. Even if the DEF has only a value of 1, it still has the armor break effect.
            if(damage > defender.def){
                defender.hp = BattleMath.safeMinusUint256(defender.hp, ((damage - defender.def) / 2));
                defender.def = 0;
            }else{
                defender.def = BattleMath.safeMinusUint256(defender.def, damage);
            }

            atk_ev = attack_event({
                evaded : evaded,
                penetrated: penetrated,
                critical_hit: critical_hit,
                damage: damage
            });
        }
    }

    ///@notice Determine if the attack would be evaded
    function rollEvade(uint16 random_num_evade, battle_stats memory defender) internal pure returns (bool evaded){
        uint256 evade_roll = random_num_evade % 1000;
        if(evade_roll <= defender.eva){evaded = true;}
    }

    ///@notice Determine the actual attack damage within the attacker's damage range
    function rollDamage(uint16 random_num_damage, battle_stats memory attacker, uint256 attacker_class) internal pure returns (uint256 damage){
        (uint256 minMultiplier, uint256 maxMultiplier) = getMinMaxDmg(attacker_class);
        uint256 minDamage = (minMultiplier * attacker.atk) / 1000;
        uint256 maxDamage = (maxMultiplier * attacker.atk) / 1000;
        uint256 damageSpread = maxDamage - minDamage;
        uint256 damage_roll = random_num_damage % 1000;
        uint256 damageOverMin = (damageSpread * damage_roll) / 1000;
        damage = BattleMath.safeAddUint256(minDamage, damageOverMin, maxDamage);
    }

    ///@notice Determine minimum and maximum attack damage of a specified character/enemy class/type.
    function getMinMaxDmg(uint256 attacker_class) internal pure returns (uint256 min, uint256 max){
        if(attacker_class == 0){min = 650; max = 1350;} ///Viking
        if(attacker_class == 1){min = 700; max = 1250;} ///Woodcutter
        if(attacker_class == 2){min = 750; max = 1100;} ///Troll
        if(attacker_class == 3){min = 800; max = 1050;} ///Mechanic
        if(attacker_class == 4){min = 850; max = 1000;} ///Amphibian
        if(attacker_class == 5){min = 900; max = 950;} ///Graverobber
    }

    ///@notice Determine if the attack penetrated the defender's armor
    ///When it penetrates, the Defender's HP will get reduced even if he still has remaining DEF.
    function rollPenetrate(uint16 random_num_penetrate, battle_stats memory attacker) internal pure returns (bool penetrated){
        uint256 penetrate_roll = random_num_penetrate % 1000;
        if(penetrate_roll <= attacker.pen){penetrated = true;}
    }

    ///@notice Determine if the attack did a critical hit
    ///When it does, the Attacker's damage would deal double damage but it does not stack with the penetrated damage
    ///When it does a critical hit and penetrated armor at the same time, the damage to the HP resulting from the armor penetration
    ///will deal only 1x damage.
    function rollCriticalHit(uint16 random_num_critical, battle_stats memory attacker) internal pure returns (bool critical_hit){
        uint256 critical_hit_roll = random_num_critical % 1000;
        if(critical_hit_roll <= attacker.crit){critical_hit = true;}
    }

    ///@notice This function restores the character's energy in the amount of his/her energy_restoration stats including that of the
    ///equipments currently equipped.
    function restoreEnergy(uint256 character_id, uint256 energy_restoration) internal {
        energy_balances[character_id].energy = BattleMath.safeAddUint256(energy_balances[character_id].energy, energy_restoration, 1000);
    }

    ///@notice Update the character properties in the Character NFT contract.
    function applyCharacterEffects(battle_request memory request, character_properties memory char_props) internal {
        ///Get the experience gained and attribute amount gained based on the enemy's tier level.
        (uint32 experience_gained, uint32 stat_amount_gained) = CharacterExperience.getExpAndAttributeGains(request.tier);

        ///Get the attribute affected by the specified dungeon in the battle.
        ///For dungeon 0, the character's STR is increased.
        ///For dungeon 1, the character's VIT is increased.
        ///For dungeon 2, the character's DEX is increased.
        uint256 specific_stat = CharacterExperience.getAttributeAffected(request.dungeon_type);

        ///If the character already has reached the maximum exp of 10,000. He/she shall no longer gain any exp and attribute points from dungeon
        ///battles. Take note that the higher the enemy tier, the higher the attribute point to exp ratio gained. This being said, the character
        ///who do battles mostly on the highest tier will earn more attribute points than a character who do battles mostly on lower tiers when
        ///they both reach 10,000 exp.
        if(char_props.exp < 10000){
            ///Increase the character's exp with a ceiling of 10,000
            char_props.exp = uint32(BattleMath.safeAddUint256(char_props.exp, experience_gained, 10000));

            ///Increase the corresponding attribute by the amount based on the enemy tier.
            if(specific_stat == 0){char_props.str += stat_amount_gained;}
            if(specific_stat == 1){char_props.vit += stat_amount_gained;}
            if(specific_stat == 2){char_props.dex += stat_amount_gained;}

            ///EXTCALL: update the character in the Characters NFT contract.
            characters.updateCharacter(request.character_id, char_props);
        }
    }

    ///@notice Determine the loot amount and transfer it to the character's owner
    function getAndTransferLoot(
        battle_request memory request, 
        uint256 random_num_loot, 
        uint256 random_num_snap, 
        uint256 random_num_snap_amount, 
        address sender
    ) internal {
        ///Get the material type and the minimum and maximum amount for the specific tier
        (uint256 material, uint256 min_amount, uint256 max_amount) = DungeonMaterials.getDungeonMaterials(request.dungeon_type, request.tier);

        ///Get the actual amount of loot by consuming a random number and the material's min and max amount
        uint256 actual_amount = getActualLootAmount(random_num_loot, min_amount, request.max_loot);

        ///Instantiate a token contract instance with the corresponding address of the loot material
        _MaterialToken material_token = _MaterialToken(materials_addresses[material]);

        ///EXTCALL: mint the actual tokens
        material_token.mint(sender, actual_amount * 1 ether);

        ///Determine whether there will be a snaplink loot drop
        bool snap_loot = rollSnapLink(random_num_snap);

        ///If there is, calculate the loot amount using the same min and max
        if(snap_loot){
            uint256 snap_amount = getActualLootAmount(random_num_snap_amount, min_amount, max_amount);
            _MaterialToken snap_link = _MaterialToken(materials_addresses[3]);
            snap_link.mint(sender, snap_amount * 1 ether);
        }
    }

    ///@notice Determine the actual loot amount
    function getActualLootAmount(uint256 random_num, uint256 min_amount, uint256 max_amount) internal pure returns (uint256 loot_amount){
        if(max_amount > min_amount){
            uint256 roll_amount = random_num % 1000;
            uint256 amount_spread = BattleMath.safeMinusUint256(max_amount, min_amount);
            loot_amount = BattleMath.safeAddUint256(min_amount, ((amount_spread * roll_amount) / 1000), max_amount);
        }
        if(max_amount <= min_amount){
            loot_amount = max_amount;
        }
    }

    ///@notice Determine whether there will be snaplink loot
    function rollSnapLink(uint256 random_num_snap) internal pure returns (bool isSnap){
        uint256 roll_snap = random_num_snap % 1000;
        if(roll_snap <= 250){isSnap = true;}
    }

    ///@notice Consume enerlink to restore character's energy to full. Costs 1 $eLINK
    function consumeEnerLink(uint256 character_id) public returns (bool restored){
        require(getCharacterEnergy(character_id) < 1000, "Dungeons: character already at full hp");
        enerlink.burnFrom(msg.sender, 1 ether);
        energy_balances[character_id] = last_energy_update({
            energy: 1000,
            time_last_updated: block.timestamp
        });
        restored = true;
    }

    ///@notice The following are ADMIN functions.

    function setRandomizationContract(address _vrf_contract_address) public onlyOwner {
        vrf_contract = _RandomizationContract(_vrf_contract_address);
    }

    function setBattleFee(uint256 amount) public onlyOwner {
        battle_fee = amount * 1 gwei;
    }

    function replenishDungeonLoot() public onlyDungeonKeeper {
        dungeon_loot_remaining[0] = dungeon_loot_cap[0];
        dungeon_loot_remaining[1] = dungeon_loot_cap[1];
        dungeon_loot_remaining[2] = dungeon_loot_cap[2];
        emit DungeonsReplenished(dungeon_loot_remaining[0], dungeon_loot_remaining[1], dungeon_loot_remaining[2]);
    }

    function setDungeonKeeper(address keeperAddress) public onlyOwner {
        dungeonKeeper = keeperAddress;
    }

    modifier onlyDungeonKeeper(){
        require(msg.sender == dungeonKeeper, "Dungeons: only replenisher contract");
        _;
    }

    function setDungeonLootCap(uint256 dungeon, uint256 amount) public onlyOwner {
        dungeon_loot_cap[dungeon] = amount;
    }

    function withdraw() public onlyOwner{
        (bool succeed, ) = vrf_refunder.call{value: address(this).balance}("");
        require(succeed, "Failed to withdraw matics.");
    }
}

//SPDX-License-Identifier: MIT
///@author https://ethereum.stackexchange.com/users/102976/jeremy-then
///@notice This is a modified code snippet from his stack overflow answer here: https://ethereum.stackexchange.com/a/133983

pragma solidity ^0.8.7;

library BreakdownUint256 {
    function break256BitsIntegerIntoBytesArrayOf8Bits(uint256 n) internal pure returns(uint8[] memory) {

        uint8[] memory _8BitNumbers = new uint8[](32);

        uint256 mask = 0x00000000000000000000000000000000000000000000000000000000000000ff;
        uint256 shiftBy = 0;

        for(int256 i = 31; i >= 0; i--) { 
            uint256 v = n & mask;
            mask <<= 8;
            v >>= shiftBy;
            _8BitNumbers[uint(i)] = uint8(v);
            shiftBy += 8;
        }
        return _8BitNumbers;
    }

    function break256BitsIntegerIntoBytesArrayOf16Bits(uint256 n) internal pure returns(uint16[] memory) {

        uint16[] memory _16BitNumbers = new uint16[](16);

        uint256 mask = 0x000000000000000000000000000000000000000000000000000000000000ffff;
        uint256 shiftBy = 0;

        for(int256 i = 15; i >= 0; i--) { 
            uint256 v = n & mask;
            mask <<= 16;
            v >>= shiftBy;
            _16BitNumbers[uint(i)] = uint16(v);
            shiftBy += 16;
        }
        return _16BitNumbers;
    }

    function break256BitsIntegerIntoBytesArrayOf32Bits(uint256 n) internal pure returns(uint32[] memory) {

        uint32[] memory _32BitNumbers = new uint32[](8);

        uint256 mask = 0x00000000000000000000000000000000000000000000000000000000ffffffff;
        uint256 shiftBy = 0;

        for(int256 i = 7; i >= 0; i--) { 
            uint256 v = n & mask;
            mask <<= 32;
            v >>= shiftBy;
            _32BitNumbers[uint(i)] = uint32(v);
            shiftBy += 32;
        }
        return _32BitNumbers;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library BattleMath {
    function safeMinusUint256(uint256 subtrahend, uint256 subtractor)
        internal
        pure
        returns (uint256 diff)
    {
        diff = (subtractor > subtrahend) ? 0 : (subtrahend - subtractor);
    }

    function safeAddUint256(
        uint256 addend1,
        uint256 addend2,
        uint256 max
    ) internal pure returns (uint256 sum) {
        sum = (addend1 + addend2) > max ? max : addend1 + addend2;
    }
    
}

///SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

struct enemy_properties {
    uint256 dungeon;
    uint256 tier;
    uint256 _type;
    uint256 attr_sum;
    uint256 attr_alloc;
}

struct enemy_attributes {
    uint256 str;
    uint256 vit;
    uint256 dex;
}

///SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

struct equipment_details {
    bytes name;
    bytes image;
    bytes type_tag;
    bytes rarity_tag;
    bytes dominant_stat_tag;
    bytes extremity_tag;
}

struct equipment_properties { //SSTORED
    uint64 equipment_type; //0-3
    uint64 rarity;
    uint64 dominant_stat;
    uint64 extremity;
}

struct item_recipe {
    uint256 main_material;
    uint256 indirect_material;
    uint256 catalyst;
    uint256 main_material_amount;
    uint256 indirect_material_amount;
    uint256 catalyst_amount;
}

struct equipment_request { //SSTORED
    uint256 request_id;
    uint64 equipment_type;
    uint32 number_of_items;
    uint256 time_requested;
    bool free;
}

struct character_equipments {
    uint64 headgear;
    uint64 armor;
    uint64 weapon;
    uint64 accessory;
}

//SPDX-License-Identifier: MIT
/**
    @title Character Experience
    @author Eman @SgtChiliPapi
    @notice: Reference for character experience and attribute gains in dungeons.
            A simple library. Might prove useful when the experience and leveling system is further improved in complexity.
    Originally created for CHAINLINK HACKATHON FALL 2022
*/
pragma solidity ^0.8.7;

library CharacterExperience {
    
    function getExpAndAttributeGains(uint256 tier) internal pure returns (uint32 experience, uint32 stat_gain){
        if(tier == 0){experience = 20; stat_gain = 1;}
        if(tier == 1){experience = 40; stat_gain = 3;}
        if(tier == 2){experience = 60; stat_gain = 6;}
        if(tier == 3){experience = 80; stat_gain = 10;}
        if(tier == 4){experience = 100; stat_gain = 15;}
    }

    function getAttributeAffected(uint256 dungeon) internal pure returns (uint32 stat){
        if(dungeon == 0){stat = 2;}
        if(dungeon == 1){stat = 0;}
        if(dungeon == 2){stat = 1;}
    }
}

///SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

struct character_properties { //SSTORED
    uint32 character_class;
    uint32 element;
    uint32 str;
    uint32 vit;
    uint32 dex;
    uint32 talent;
    uint32 mood;
    uint32 exp;
}

struct character_uri_details {
    string name;
    string image;
    string mood;
    string bonus;
    string bonus_value;
    string talent_value;
}

struct character_request { //SSTORED
    uint256 request_id;
    uint32 character_class;
    string _name;
    uint256 time_requested;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
    @title Character Stats Calculator
    @author Eman @SgtChiliPapi
*/

import "../../libraries/structs/CharacterStructs.sol";
import "../../libraries/structs/GlobalStructs.sol";

library CharacterStatsCalculator{
    function getCharacter(character_properties memory properties) internal pure returns (battle_stats memory character){
        character = battle_stats({
            atk: getAttackPower(properties),
            def: getDefense(properties),
            eva: getEvasionChance(properties),
            hp: getHP(properties),
            pen: getPenetrationChance(properties),
            crit: getCriticalChance(properties),
            luck: getLuck(properties),
            energy_restoration: getEnergyRegen(properties)
        });
    }

    function getAttackPower(character_properties memory properties) internal pure returns (uint256 attack_power){
        attack_power = (((properties.str * 6) + (properties.dex * 4)) / 10) / 4;
        uint256 attack_bonus;
        if(properties.character_class == 0){attack_bonus = 5;} //Viking
        if(properties.talent == 0){attack_bonus += 5;} //Combat Psycho
        attack_power += (attack_power * attack_bonus) / 100;
    }

    function getPenetrationChance(character_properties memory properties) internal pure returns (uint256 penetration_chance){
        penetration_chance = (properties.str / 2);
        uint256 penetration_bonus;
        if(properties.character_class == 1){penetration_bonus = 10;} //Woodcutter
        if(properties.talent == 1){penetration_bonus += 10;} //Woodcutter
        penetration_chance += (penetration_chance * penetration_bonus) / 100;
    }

    function getHP(character_properties memory properties) internal pure returns (uint256 hp){
        hp = (properties.vit * 5);
        uint256 hp_bonus;
        if(properties.character_class == 2){hp_bonus = 3;} //Troll
        if(properties.talent == 2){hp_bonus += 3;} //Body Builder
        hp += (hp * hp_bonus) / 100;
    }

    function getDefense(character_properties memory properties) internal pure returns (uint256 defense){
        defense = (((properties.vit * 6) + (properties.str * 4)) / 10) / 2;
        uint256 defense_bonus;
        if(properties.character_class == 3){defense_bonus = 10;} //Troll
        if(properties.talent == 3){defense_bonus += 10;} //Iron Skin
        defense += (defense * defense_bonus) / 100;
    }

    function getCriticalChance(character_properties memory properties) internal pure returns (uint256 critical_chance){
        critical_chance = (properties.dex / 2);
        uint256 critical_bonus;
        if(properties.character_class == 4){critical_bonus = 10;} //Zooka
        if(properties.talent == 4){critical_bonus += 10;} //Sniper
        critical_chance += (critical_chance * critical_bonus) / 100;
    }
    function getEvasionChance(character_properties memory properties) internal pure returns (uint256 evasion_chance){
        evasion_chance = (((properties.dex * 6) + (properties.vit * 4)) / 10) / 2;
        uint256 evasion_bonus;
        if(properties.character_class == 5){evasion_bonus = 10;} //Graverobber
        if(properties.talent == 5){evasion_bonus += 10;} //Ninja
        evasion_chance += (evasion_chance * evasion_bonus) / 100;
    }

    function getLuck(character_properties memory properties) internal pure returns (uint256 luck){
        luck = properties.dex / 10;
    }

    function getEnergyRegen(character_properties memory properties) internal pure returns (uint256 energy_restoration){
        energy_restoration = ((properties.vit + properties.str) / 2 ) / 10;
    }
}

//SPDX-License-Identifier: MIT

/**
    @title Enemy Stats Calculator
    @author Eman @SgtChiliPapi
*/

pragma solidity ^0.8.7;

import "../../libraries/structs/EnemyStructs.sol";
import "../../libraries/structs/GlobalStructs.sol";

library EnemyStatsCalculator {

    function getEnemy(uint256 dungeon_type, uint256 tier, uint16 rnum_enemy_type, uint16 rnum_attr_alloc) internal pure returns (enemy_properties memory enemy_props, battle_stats memory enemy){
        enemy_props = enemy_properties({
            dungeon: dungeon_type,
            tier: tier,
            _type: getEnemyType(rnum_enemy_type),
            attr_sum: getAttributeSum(tier),
            attr_alloc: getAttributesAllocation(rnum_attr_alloc)
        });
        enemy_attributes memory enemy_attr = getEnemyAttributes(enemy_props);
        enemy = getStats(enemy_attr, enemy_props);
    }

    function getAttributeSum(uint256 tier) internal pure returns (uint256 attr_sum){
        if(tier == 0){attr_sum = 600;}
        if(tier == 1){attr_sum = 900;}
        if(tier == 2){attr_sum = 1300;}
        if(tier == 3){attr_sum = 1800;}
        if(tier == 4){attr_sum = 2400;}
    }

    function getEnemyType(uint256 random_num) internal pure returns (uint256 enemy_type){
        enemy_type = random_num % 6;
    }

    function getAttributesAllocation(uint256 random_num) internal pure returns (uint256 attr_alloc){
        attr_alloc = random_num % 400;
    }

    function getEnemyAttributes(enemy_properties memory enemy_props) internal pure returns (enemy_attributes memory enemy_attr){
        if(enemy_props.dungeon == 0){
            enemy_attr.str = (600 * enemy_props.attr_sum) / 1000;
            enemy_attr.vit = (enemy_props.attr_alloc * enemy_props.attr_sum) / 1000;
            enemy_attr.dex = ((400 - enemy_props.attr_alloc) * enemy_props.attr_sum) / 1000;
        }
        if(enemy_props.dungeon == 1){
            enemy_attr.str = (enemy_props.attr_alloc * enemy_props.attr_sum) / 1000;
            enemy_attr.vit = (600 * enemy_props.attr_sum) / 1000;
            enemy_attr.dex = ((400 - enemy_props.attr_alloc) * enemy_props.attr_sum) / 1000;
        }
        if(enemy_props.dungeon == 2){
            enemy_attr.str = (enemy_props.attr_alloc * enemy_props.attr_sum) / 1000;
            enemy_attr.vit = ((400 - enemy_props.attr_alloc) * enemy_props.attr_sum) / 1000;
            enemy_attr.dex = (600 * enemy_props.attr_sum) / 1000;
        }
    }

    function getStats(enemy_attributes memory enemy_attr, enemy_properties memory enemy_props) internal pure returns (battle_stats memory stats){
        stats = battle_stats({
            atk: getAttackPower(enemy_attr, enemy_props),
            def: getDefense(enemy_attr, enemy_props),
            eva: getEvasionChance(enemy_attr, enemy_props),
            hp: getHP(enemy_attr, enemy_props),
            pen: getPenetrationChance(enemy_attr, enemy_props),
            crit: getCriticalChance(enemy_attr, enemy_props),
            luck: 0,
            energy_restoration: 0
        });
    }

    function getAttackPower(enemy_attributes memory enemy_attr, enemy_properties memory enemy_props) internal pure returns (uint256 attack_power){
        attack_power = (((enemy_attr.str * 6) + (enemy_attr.dex * 4)) / 10) / 2;
        uint256 attack_bonus;
        if(enemy_props._type == 0){attack_bonus = 5;}
        attack_power += (attack_power * attack_bonus) / 100;
    }

    function getDefense(enemy_attributes memory enemy_attr, enemy_properties memory enemy_props) internal pure returns (uint256 defense){
        defense = (((enemy_attr.vit * 6) + (enemy_attr.str * 4)) / 10) / 2;
        uint256 defense_bonus;
        if(enemy_props._type == 3){defense_bonus = 10;}
        defense += (defense * defense_bonus) / 100;
    }

    function getEvasionChance(enemy_attributes memory enemy_attr, enemy_properties memory enemy_props) internal pure returns (uint256 evasion_chance){
        evasion_chance = (((enemy_attr.dex * 6) + (enemy_attr.vit * 4)) / 10) / 2;
        uint256 evasion_bonus;
        if(enemy_props._type == 5){evasion_bonus = 10;}
        evasion_chance += (evasion_chance * evasion_bonus) / 100;
    }

    function getHP(enemy_attributes memory enemy_attr, enemy_properties memory enemy_props) internal pure returns (uint256 hp){
        hp = (enemy_attr.vit * 5);
        uint256 hp_bonus;
        if(enemy_props._type == 2){hp_bonus = 3;}
        hp += (hp * hp_bonus) / 100;
    }

    function getPenetrationChance(enemy_attributes memory enemy_attr, enemy_properties memory enemy_props) internal pure returns (uint256 penetration_chance){
        penetration_chance = (enemy_attr.str / 2);
        uint256 penetration_bonus;
        if(enemy_props._type == 1){penetration_bonus = 10;}
        penetration_chance += (penetration_chance * penetration_bonus) / 100;
    }

    function getCriticalChance(enemy_attributes memory enemy_attr, enemy_properties memory enemy_props) internal pure returns (uint256 critical_chance){
        critical_chance = (enemy_attr.dex / 2);
        uint256 critical_bonus;
        if(enemy_props._type == 4){critical_bonus = 10;}
        critical_chance += (critical_chance * critical_bonus) / 100;
    }

}

//SPDX-License-Identifier: MIT
/**
    @title Struct Library
    @author Eman @SgtChiliPapi
    @notice: Reference for global structs across contracts. 
    Originally created for CHAINLINK HACKATHON FALL 2022
*/

pragma solidity =0.8.17;

struct battle_stats {
    uint256 atk;
    uint256 def;
    uint256 eva;
    uint256 hp;
    uint256 pen;
    uint256 crit;
    uint256 luck;
    uint256 energy_restoration;
}







// struct attack_event {
//     uint256 attack_index;
//     uint256 challenger_hp;
//     uint256 defender_hp;
//     uint256 evaded;
//     uint256 critical_hit;
//     uint256 penetrated;
//     uint256 damage_to_challenger;
//     uint256 damage_to_defender;  
// }

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

struct battle_request {
    uint256 request_id;
    uint64 dungeon_type;
    uint64 tier;
    uint64 result;
    uint64 max_loot;
    uint256 character_id;
    bool completed;
}

struct last_energy_update {
    uint256 energy;
    uint256 time_last_updated;
}

struct attack_event {
    bool evaded;
    bool penetrated;
    bool critical_hit;
    uint256 damage;
}

struct clash_event {
    attack_event attack1;
    attack_event attack2;
}

///SPDX-License-Identifier: MIT

/**
    @title DungeonMaterials
    @author Eman @SgtChiliPapi
    @notice This library specifies the specific material rewards for each dungeon.
            Originally made for a submission to CHAINLINK HACKATHON 2022.
 */

 pragma solidity ^0.8.7;

 library DungeonMaterials {

    function getDungeonMaterials(uint256 dungeon, uint256 tier) internal pure returns (uint256 material, uint256 min_amount, uint256 max_amount){
        if(dungeon == 0){material = 0;}
        if(dungeon == 1){material = 1;}
        if(dungeon == 2){material = 2;}
        (min_amount, max_amount) = getAmount(tier);
    }

    function getAmount(uint256 tier) internal pure returns (uint256 min_amount, uint256 max_amount){
        if(tier == 0){min_amount = 1; max_amount = 3;}
        if(tier == 1){min_amount = 2; max_amount = 6;}
        if(tier == 2){min_amount = 3; max_amount = 9;}
        if(tier == 3){min_amount = 4; max_amount = 12;}
        if(tier == 4){min_amount = 5; max_amount = 15;}
    }
 }

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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