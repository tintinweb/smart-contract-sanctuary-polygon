/**
 *Submitted for verification at polygonscan.com on 2022-12-13
*/

//SPDX-License-Identifier: MIT License
pragma solidity ^0.8.0;

contract AccessControl {
    address public creatorAddress;

    modifier onlyCREATOR() {
        require(msg.sender == creatorAddress, 'You are not the creator');
        _;
    }

    // Constructor
    constructor() {
        creatorAddress = msg.sender;
    }

    function changeOwner(address payable _newOwner) public onlyCREATOR {
        creatorAddress = _newOwner;
    }
}

contract SafeMath {}

abstract contract IHalo {
    function transfer(address recipient, uint256 amount)
        external
        virtual
        returns (bool);

    function balanceOf(address owner) public virtual returns (uint256);
}

abstract contract IABToken is AccessControl {
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function getABToken(uint256 tokenId)
        public
        view
        virtual
        returns (
            uint8 cardSeriesId,
            uint16 power,
            uint16 auraRed,
            uint16 auraYellow,
            uint16 auraBlue,
            string memory name,
            uint16 experience,
            uint64 lastBattleTime,
            address owner,
            uint16 oldId
        );
}

abstract contract IABBattleSupport is AccessControl, SafeMath {
    function getInitialAngelHp(uint256 angelId, uint256 accessoryId)
        public
        view
        virtual
        returns (uint256);

    function getAuraDifferenceValue(uint16 aura1, uint16 aura2)
        public
        pure
        virtual
        returns (int16);

    function getAuraCode(uint256 angelId) public view virtual returns (uint8);
}

abstract contract IBattleMtnData is AccessControl {
    function addTeam(
        uint8 toSpot,
        uint256 angelId,
        uint256 petId,
        uint256 accessoryId
    ) public virtual;

    function switchTeams(
        uint8 fromSpot,
        uint8 toSpot,
        uint256 attacker,
        uint256 defender
    ) public virtual;

    function cardOnBattleMtn(uint256 Id) external view virtual returns (bool);

    function isValidMove(
        uint8 position,
        uint8 to,
        address battleMtnDataContract
    ) public view virtual returns (bool);

    function getTeamByPosition(uint8 _position)
        external
        view
        virtual
        returns (
            uint8 position,
            uint256 angelId,
            uint256 petId,
            uint256 accessoryId,
            string memory slogan
        );

    function getAction(uint8 position, uint8 actionNumber)
        public
        virtual
        returns (uint8);

    function getTurnResult(
        uint8 round,
        uint8 spotContested,
        uint8 desiredAction,
        uint16 power,
        uint8 aura,
        uint8 petAuraStatus
    )
        public
        view
        virtual
        returns (
            uint8 action,
            uint16 resultValue,
            uint8 newPetAuraStatus
        );

    function applyConditions(
        uint256 angelId,
        uint256 petId,
        uint256 accessoryId,
        bool attacker,
        uint8 toSpot
    )
        public
        view
        virtual
        returns (
            uint8 newPower,
            uint8 newSpeed,
            uint16 newRed,
            uint16 newYellow,
            uint16 newBlue
        );

    function applyAuraColorDifference(
        uint256 angelId,
        uint16 power,
        uint8 toSpot
    ) public view virtual returns (uint16 newPower);

    function checkBattleParameters(
        uint256 angelId,
        uint256 petId,
        uint256 accessoryId,
        uint8 fromSpot,
        address owner
    ) public view virtual;
}

contract VSBattle is AccessControl {
    //Data Structures

    struct AngelTeam {
        uint256 angelId;
        uint256 petId;
        uint256 accessoryId;
        uint16 power;
        uint8 aura;
        uint16 auraRed;
        uint16 auraBlue;
        uint16 auraYellow;
        uint16 speed;
        uint16 hp;
        uint8 petAuraStatus; //00- neither released, 10- pet summoned, aura not yet, 01 - pet not yet, aura released, 11- both released.
        uint8 action;
        uint16 resultValue;
        uint16 defenseBuff;
    }

    //Store all the information about a particular battle.
    struct Battle {
        uint64 id; //id of the Battle
        bool attackerFirst;
        AngelTeam attacker;
        AngelTeam defender;
        //later we can make this an array to have multiple teams or monsters in a battle.
        uint8 round;
        uint8 spotContested;
        uint8 attackFrom;
    }

    Battle[] Battles;

    uint16 public totalBattles = 0;
    //Starts at one so that battle 0 means no current battle for the address mapping.

    //Figure out which battle each address is in
    mapping(address => uint64) addressBattleId;

    uint8 smallAuraEffect = 15;
    uint8 bigAuraEffect = 30;
    uint8 lureEffect = 20;

    address public ABTokenDataContract = address(0);
    address public ABBattleSupportContract = address(0);
    address public BattleMtnDataContract = address(0);
    address public HaloTokenContract = address(0);

    uint256 rewardDivisor = 100;

    function getRandomNumber(
        uint16 maxRandom,
        uint16 min,
        address privateAddress
    ) public view returns (uint8) {
        uint256 genNum = uint256(
            keccak256(abi.encodePacked(block.timestamp, privateAddress))
        );
        return uint8((genNum % (maxRandom - min + 1)) + min);
    }

    function setParameters(
        address _ABTokenDataContract,
        address _ABBattleSupportContract,
        address _BattleMtnDataContract,
        address _HaloTokenContract,
        uint8 _smallAuraEffect,
        uint8 _bigAuraEffect,
        uint8 _lureEffect,
        uint256 _rewardDivisor
    ) public onlyCREATOR {
        ABTokenDataContract = _ABTokenDataContract;
        ABBattleSupportContract = _ABBattleSupportContract;
        BattleMtnDataContract = _BattleMtnDataContract;
        HaloTokenContract = _HaloTokenContract;
        smallAuraEffect = _smallAuraEffect;
        bigAuraEffect = _bigAuraEffect;
        lureEffect = _lureEffect;
        rewardDivisor = _rewardDivisor;
    }

    //Function that anyone can call (under the proper parameters) to begin a battle.
    function attackSpot(
        uint8 fromSpot,
        uint8 toSpot,
        uint256 angelId,
        uint256 petId,
        uint256 accessoryId
    ) public {
        //if fromSpot ==99, then they are attacking a gate and angelId, etc will be used.
        //if fromSpot !=99, then these parameters will be ignored.

        Battle memory battle;
        AngelTeam memory attacker;
        AngelTeam memory defender;
        IABBattleSupport ABBattleSupportData = IABBattleSupport(
            ABBattleSupportContract
        );
        IBattleMtnData BattleMtnData = IBattleMtnData(BattleMtnDataContract);

        require(
            BattleMtnData.isValidMove(fromSpot, toSpot, BattleMtnDataContract),
            'This is not a valid move'
        );

        //make sure caller is the owner of angel in fromSpot and not in any other battles.

        //Add attacking team to battle
        if (fromSpot != 99) {
            (, angelId, petId, accessoryId, ) = BattleMtnData.getTeamByPosition(
                fromSpot
            );
        }

        BattleMtnData.checkBattleParameters(
            angelId,
            petId,
            accessoryId,
            fromSpot,
            msg.sender
        );
        //Initialize the angelTeam in the battle.
        attacker.angelId = angelId;
        attacker.petId = petId;
        attacker.accessoryId = accessoryId;
        attacker.hp = uint16(
            ABBattleSupportData.getInitialAngelHp(angelId, accessoryId)
        );
        attacker.petAuraStatus = 0;
        attacker.action = 0; //Action 0 means no action yet.
        attacker.resultValue = 0;
        attacker.defenseBuff = 0;
        attacker.aura = ABBattleSupportData.getAuraCode(angelId);

        // Apply mountain conditions
        (
            attacker.power,
            attacker.speed,
            attacker.auraRed,
            attacker.auraYellow,
            attacker.auraBlue
        ) = BattleMtnData.applyConditions(
            attacker.angelId,
            attacker.petId,
            attacker.accessoryId,
            true,
            toSpot
        );

        (attacker.power) = BattleMtnData.applyAuraColorDifference(
            attacker.angelId,
            attacker.power,
            toSpot
        );

        attacker.power += getPower(angelId);
        attacker.speed += uint8(getPower(petId));

        //blue
        if (attacker.aura == 0) {
            attacker.defenseBuff = 10;
        }
        // orange
        else if (attacker.aura == 3) {
            attacker.hp += 50;
        }
        // red
        else if (attacker.aura == 4) {
            attacker.power += 10;
        }
        // green
        else if (attacker.aura == 5) {
            attacker.speed += 5;
        }

        //Now add defender

        (, angelId, petId, accessoryId, ) = BattleMtnData.getTeamByPosition(
            toSpot
        );

        //Initialize the angelTeam defending in the battle.
        defender.angelId = angelId;
        defender.petId = petId;
        defender.accessoryId = accessoryId;
        defender.hp = uint16(
            ABBattleSupportData.getInitialAngelHp(angelId, accessoryId)
        );
        defender.petAuraStatus = 0;
        defender.action = 0; //Action 0 means no action yet.
        defender.resultValue = 0;
        defender.defenseBuff = 0;
        defender.aura = ABBattleSupportData.getAuraCode(angelId);

        // Apply mountain conditions
        (
            defender.power,
            defender.speed,
            defender.auraRed,
            defender.auraYellow,
            defender.auraBlue
        ) = BattleMtnData.applyConditions(
            defender.angelId,
            defender.petId,
            defender.accessoryId,
            false,
            fromSpot
        );

        defender.power += getPower(angelId);
        defender.speed = uint8(getPower(petId));

        //blue
        if (defender.aura == 0) {
            defender.defenseBuff = 10;
        }
        // orange
        else if (defender.aura == 3) {
            defender.hp += 50;
        }
        // red
        else if (defender.aura == 4) {
            defender.power += 10;
        }
        // green
        else if (defender.aura == 5) {
            defender.speed += 5;
        }

        battle.attacker = attacker;
        battle.defender = defender;
        battle.spotContested = toSpot;
        battle.attackFrom = fromSpot;
        battle.id = totalBattles;
        battle.round = 0; //regular live battle
        Battles.push(battle);

        //apply initial aura effects.
        updateAuras(totalBattles);
        applyAuraDifferences(totalBattles);
        addressBattleId[msg.sender] = totalBattles;
        totalBattles++;
    }

    function getPower(uint256 tokenId) public view returns (uint16 power) {
        IABToken ABTokenData = IABToken(ABTokenDataContract);
        (, power, , , , , , , , ) = ABTokenData.getABToken(tokenId);
        return power;
    }

    //A function that adjusts parameters based on differences in Auras as well as accessory effects.
    function updateAuras(uint64 battleId) internal {
        IABToken ABTokenData = IABToken(ABTokenDataContract);

        uint8 accSeriesId;

        //Adjust the attacker's stats first
        (accSeriesId, , , , , , , , , ) = ABTokenData.getABToken(
            Battles[battleId].attacker.accessoryId
        );

        Battles[battleId].attacker.speed += applyPetAccessory(
            accSeriesId,
            Battles[battleId].attacker.petId
        );

        Battles[battleId].attacker.power += applyPetAccessory(
            accSeriesId,
            Battles[battleId].attacker.petId
        );

        if (accSeriesId == 43) {
            Battles[battleId].attacker.power += smallAuraEffect;
        }
        if (accSeriesId == 44) {
            Battles[battleId].attacker.power += bigAuraEffect;
        }

        if (accSeriesId == 47) {
            Battles[battleId].attacker.speed += smallAuraEffect;
        }
        if (accSeriesId == 48) {
            Battles[battleId].attacker.speed += bigAuraEffect;
        }

        //Account for colored accessories here.
        if (accSeriesId == 49) {
            Battles[battleId].attacker.auraRed += smallAuraEffect;
        }
        if (accSeriesId == 50) {
            Battles[battleId].attacker.auraRed += bigAuraEffect;
        }

        if (accSeriesId == 51) {
            Battles[battleId].attacker.auraYellow += smallAuraEffect;
        }
        if (accSeriesId == 52) {
            Battles[battleId].attacker.auraYellow += bigAuraEffect;
        }

        if (accSeriesId == 53) {
            Battles[battleId].attacker.auraBlue += smallAuraEffect;
        }
        if (accSeriesId == 54) {
            Battles[battleId].attacker.auraBlue += bigAuraEffect;
        }

        //Now adjust the defender's stats

        (accSeriesId, , , , , , , , , ) = ABTokenData.getABToken(
            Battles[battleId].defender.accessoryId
        );

        Battles[battleId].defender.speed += applyPetAccessory(
            accSeriesId,
            Battles[battleId].defender.petId
        );

        Battles[battleId].defender.power += applyPetAccessory(
            accSeriesId,
            Battles[battleId].defender.petId
        );

        if (accSeriesId == 43) {
            Battles[battleId].defender.power += smallAuraEffect;
        }
        if (accSeriesId == 44) {
            Battles[battleId].defender.power += bigAuraEffect;
        }

        if (accSeriesId == 47) {
            Battles[battleId].defender.speed += smallAuraEffect;
        }
        if (accSeriesId == 48) {
            Battles[battleId].defender.speed += bigAuraEffect;
        }

        //Account for colored accessories here.
        if (accSeriesId == 49) {
            Battles[battleId].defender.auraRed += smallAuraEffect;
        }
        if (accSeriesId == 50) {
            Battles[battleId].defender.auraRed += bigAuraEffect;
        }

        if (accSeriesId == 51) {
            Battles[battleId].defender.auraYellow += smallAuraEffect;
        }
        if (accSeriesId == 52) {
            Battles[battleId].defender.auraYellow += bigAuraEffect;
        }

        if (accSeriesId == 53) {
            Battles[battleId].defender.auraBlue += smallAuraEffect;
        }
        if (accSeriesId == 54) {
            Battles[battleId].defender.auraBlue += bigAuraEffect;
        }
    }

    function applyPetAccessory(uint8 accessorySeriesId, uint256 petId)
        public
        view
        returns (uint8)
    {
        IABToken ABTokenData = IABToken(ABTokenDataContract);

        uint8 petSeriesId;
        (petSeriesId, , , , , , , , , ) = ABTokenData.getABToken(petId);

        // Double bonus for lightning rod
        if (
            (petSeriesId == 40 || petSeriesId == 41 || petSeriesId == 42) &&
            accessorySeriesId == 59
        ) {
            return 2 * lureEffect;
        }

        if (
            (petSeriesId % 4 == 0 && accessorySeriesId == 56) || // Reptile bonus
            (petSeriesId % 4 == 1 && accessorySeriesId == 57) || // Avian bonus
            (petSeriesId % 4 == 2 && accessorySeriesId == 58) || // Feline Bonus
            (petSeriesId % 4 == 3 && accessorySeriesId == 55) // Equine Bonus
        ) {
            return lureEffect;
        }

        return 0;
    }

    function applyAuraDifferences(uint64 battleId) private {
        int16 diff;
        IABBattleSupport ABBattleSupportData = IABBattleSupport(
            ABBattleSupportContract
        );

        /////////////////////////// Red Aura Difference increases attack.
        diff = ABBattleSupportData.getAuraDifferenceValue(
            Battles[battleId].attacker.auraRed,
            Battles[battleId].defender.auraRed
        );
        if (diff > 0) {
            Battles[battleId].attacker.power += uint16(diff);
        } else {
            Battles[battleId].defender.power += uint16(diff * -1);
        }

        /////////////////////////// Blue Aura Difference increases defense.
        diff = ABBattleSupportData.getAuraDifferenceValue(
            Battles[battleId].attacker.auraBlue,
            Battles[battleId].defender.auraBlue
        );
        if (diff > 0) {
            Battles[battleId].attacker.defenseBuff += uint16(diff);
        } else {
            Battles[battleId].defender.defenseBuff += uint16(diff * -1);
        }

        /////////////////////////// Yellow Aura Difference increases speed/luck.

        diff = ABBattleSupportData.getAuraDifferenceValue(
            Battles[battleId].attacker.auraYellow,
            Battles[battleId].defender.auraYellow
        );
        if (diff > 0) {
            Battles[battleId].attacker.speed += uint16(diff);
        } else {
            Battles[battleId].defender.speed += uint16(diff * -1);
        }
    }

    //apply the passive aura effect

    function auraPassive(uint64 battleId) internal returns (bool) {
        //Red + 10 bp applied to beginning of battle
        //Orange + 50 beginning hp as well
        //Blue + 10 defense
        uint8 chance = getRandomNumber(100, 0, msg.sender);
        //Yellow
        if (Battles[battleId].attacker.aura == 1) {
            Battles[battleId].attacker.hp += 20;
        }

        if ((Battles[battleId].attacker.aura == 2) && (chance > 98)) {
            Battles[battleId].defender.hp = 0;
            Battles[battleId].attacker.action = 3;
            endBattle(battleId);
            return true;
        }
        chance = getRandomNumber(99, 0, msg.sender) + 1;
        if (Battles[battleId].defender.aura == 1) {
            Battles[battleId].defender.hp += 20;
        }

        if ((Battles[battleId].defender.aura == 2) && (chance > 98)) {
            Battles[battleId].attacker.hp = 0;
            Battles[battleId].defender.action = 3;
            endBattle(battleId);
            return true;
        }
        return false;
    }

    //Function that is called before each action. Check the battle parameters and apply the aura passives.
    function beforeRound(uint64 battleId) internal returns (bool) {
        //must check that msg.sender is the owner of the angel in the battle.
        require(
            addressBattleId[msg.sender] == battleId,
            "You aren't in this battle"
        );
        require(Battles[battleId].round < 100, 'This battle is already over. ');
        Battles[battleId].round += 1;
        // if the battle has been ended early due to purple aura sudden kill
        bool purpleKilled = auraPassive(battleId);
        return purpleKilled;
    }

    function battleRound(uint8 _action) public {
        uint64 battleId = addressBattleId[msg.sender];
        // end early if the purple angel got a sudden kill
        if (beforeRound(battleId)) {
            return;
        }
        if (getOrder(battleId) == true) {
            attackerTurn(battleId, _action);
            if (Battles[battleId].round < 100) {
                defenderTurn(battleId);
            }
        } else {
            defenderTurn(battleId);
            if (Battles[battleId].round < 100) {
                attackerTurn(battleId, _action);
            }
        }
    }

    function attackerTurn(uint64 battleId, uint8 _action) internal {
        IBattleMtnData BattleMtnData = IBattleMtnData(BattleMtnDataContract);

        // petAuraStatus represents pet summon and aura release
        // 00- neither released
        // 10- pet summoned, aura not yet
        // 01 - pet not yet, aura released
        // 11- both released.

        // Actions
        // 1 = Attack
        // 2 = Defend
        // 3 = Aura Release
        // 4 = Pet Summon

        // Check if aura already released
        if (
            _action == 3 &&
            (Battles[battleId].attacker.petAuraStatus == 1 ||
                Battles[battleId].attacker.petAuraStatus == 11)
        ) {
            _action = 1;
        }

        // Check if pet summoned
        if (
            _action == 4 &&
            (Battles[battleId].attacker.petAuraStatus == 10 ||
                Battles[battleId].attacker.petAuraStatus == 11)
        ) {
            _action = 1;
        }

        (
            Battles[battleId].attacker.action,
            Battles[battleId].attacker.resultValue,
            Battles[battleId].attacker.petAuraStatus
        ) = BattleMtnData.getTurnResult(
            0,
            100,
            _action,
            Battles[battleId].attacker.power,
            Battles[battleId].attacker.aura,
            Battles[battleId].attacker.petAuraStatus
        );

        if (
            (Battles[battleId].attacker.action == 1) ||
            (Battles[battleId].attacker.action >= 14)
        ) {
            //apply apply damage from pet or aura or attack.
            if (Battles[battleId].attacker.action == 17) {
                Battles[battleId].attacker.resultValue = getRandomNumber(
                    Battles[battleId].attacker.speed * 10,
                    Battles[battleId].attacker.speed * 5,
                    msg.sender
                );
            }
            applyDamage(battleId, true, Battles[battleId].attacker.resultValue);
        }

        if (_action == 2) {
            Battles[battleId].attacker.defenseBuff += Battles[battleId]
                .attacker
                .resultValue;
        } //apply defense buff

        if (Battles[battleId].attacker.action == 12) {
            Battles[battleId].defender.defenseBuff = 0;
        }
        if (Battles[battleId].attacker.action == 10) {
            Battles[battleId].defender.hp = 0;
            endBattle(battleId);
        }
        if (Battles[battleId].attacker.action == 13) {
            Battles[battleId].attacker.defenseBuff += 75;
        }

        if (Battles[battleId].attacker.action == 18) {
            Battles[battleId].attacker.hp += getRandomNumber(
                Battles[battleId].attacker.speed * 4,
                Battles[battleId].attacker.speed,
                msg.sender
            );
            Battles[battleId].attacker.speed += Battles[battleId]
                .attacker
                .speed;
        }
    }

    //Function that returns true if the attacker moves first, false if the defender does
    // There is a base 50% chance for the attacker to move first, adjusted by the attacker's speed
    // minus the defender's speed. For instance, if the attacker's speed is 11 higher than the defender
    // the attacker will have a 61% chance to move first

    function getOrder(uint64 battleId) public returns (bool) {
        int16 chance = int16(int8(getRandomNumber(100, 0, msg.sender)));

        int16 speedDifference = int16(
            Battles[battleId].attacker.speed - Battles[battleId].defender.speed
        );

        if (chance <= (50 + speedDifference)) {
            Battles[battleId].attackerFirst = true;
            return true;
        }
        Battles[battleId].attackerFirst = false;
        return false;
    }

    function applyDamage(
        uint64 battleId,
        bool fromAngel,
        uint16 damage
    ) internal {
        //Function that updates the hp values and checks if the battle needs to be ended.
        //if fromAngel is false, then the damage is to be applied to the angel.

        if (fromAngel == true) {
            //If the attacker is dealing damage, see if defender can absorb hit
            if (Battles[battleId].defender.hp > damage) {
                Battles[battleId].defender.hp =
                    Battles[battleId].defender.hp -
                    damage;
            } else {
                Battles[battleId].defender.hp = 0;
                endBattle(battleId);
            }
        }
        if (fromAngel == false) {
            if (Battles[battleId].attacker.hp > damage) {
                Battles[battleId].attacker.hp =
                    Battles[battleId].attacker.hp -
                    damage;
            } else {
                Battles[battleId].attacker.hp = 0;
                endBattle(battleId);
            }
        }
    }

    //don't need to set address back to 0, just check each action whether a battle is live.
    function endBattle(uint64 battleId) internal {
        IBattleMtnData BattleMtnData = IBattleMtnData(BattleMtnDataContract);
        //  addressBattleId[msg.sender] = 0;

        if (Battles[battleId].defender.hp == 0) {
            Battles[battleId].round = 101;
        }
        if (Battles[battleId].attacker.hp == 0) {
            Battles[battleId].round = 102;
        }

        //attacker won
        if (Battles[battleId].defender.hp == 0) {
            awardHalo(Battles[battleId].attacker.angelId);
            Battles[battleId].round = 101;
            if (Battles[battleId].attackerFirst) {
                Battles[battleId].defender.action = 19;
            }
            //Battle was an attack gate, need to add team to mountain.
            if (Battles[battleId].attackFrom == 99) {
                BattleMtnData.addTeam(
                    Battles[battleId].spotContested,
                    Battles[battleId].attacker.angelId,
                    Battles[battleId].attacker.petId,
                    Battles[battleId].attacker.accessoryId
                );
            }
            if (Battles[battleId].attackFrom != 99) {
                BattleMtnData.switchTeams(
                    Battles[battleId].attackFrom,
                    Battles[battleId].spotContested,
                    Battles[battleId].attacker.angelId,
                    Battles[battleId].defender.angelId
                ); //switchTeam
            }
        }

        //defender won - no one moves spots.
        if (Battles[battleId].attacker.hp == 0) {
            Battles[battleId].round = 102;
            if (!Battles[battleId].attackerFirst) {
                Battles[battleId].attacker.action = 19;
            }
        }
    }

    function defenderTurn(uint64 battleId) internal {
        IBattleMtnData BattleMtnData = IBattleMtnData(BattleMtnDataContract);

        uint8 round = Battles[battleId].round;
        if (round > 6) {
            round = round % 6;
        }
        uint8 action = BattleMtnData.getAction(
            Battles[battleId].spotContested,
            Battles[battleId].round
        );
        //00- neither released, 10- pet summoned, aura not yet, 01 - pet not yet, aura released, 11- both released.
        if (
            action == 3 &&
            (Battles[battleId].defender.petAuraStatus == 1 ||
                Battles[battleId].defender.petAuraStatus == 11)
        ) {
            action = 1;
        }
        if (
            action == 4 &&
            (Battles[battleId].defender.petAuraStatus == 10 ||
                Battles[battleId].defender.petAuraStatus == 11)
        ) {
            action = 1;
        }

        (
            Battles[battleId].defender.action,
            Battles[battleId].defender.resultValue,
            Battles[battleId].defender.petAuraStatus
        ) = BattleMtnData.getTurnResult(
            round,
            Battles[battleId].spotContested,
            1,
            Battles[battleId].defender.power,
            Battles[battleId].defender.aura,
            Battles[battleId].defender.petAuraStatus
        );

        if (
            (Battles[battleId].defender.action == 1) ||
            (Battles[battleId].defender.action >= 14)
        ) {
            //apply apply damage from pet or aura or attack.
            if (Battles[battleId].defender.action == 17) {
                Battles[battleId].defender.resultValue = getRandomNumber(
                    Battles[battleId].defender.speed * 10,
                    Battles[battleId].defender.speed * 5,
                    msg.sender
                );
            }
            applyDamage(
                battleId,
                false,
                Battles[battleId].defender.resultValue
            );
        }

        if (Battles[battleId].defender.action == 2) {
            Battles[battleId].defender.defenseBuff += Battles[battleId]
                .defender
                .resultValue;
        } //apply defense buff

        if (Battles[battleId].defender.action == 12) {
            Battles[battleId].attacker.defenseBuff = 20;
        }
        if (Battles[battleId].defender.action == 10) {
            Battles[battleId].attacker.hp = 0;
            endBattle(battleId);
        }
        if (Battles[battleId].defender.action == 13) {
            Battles[battleId].defender.defenseBuff += 75;
        }

        if (Battles[battleId].defender.action == 18) {
            Battles[battleId].defender.hp += getRandomNumber(
                Battles[battleId].defender.speed * 4,
                Battles[battleId].defender.speed,
                msg.sender
            );
            Battles[battleId].defender.speed += Battles[battleId]
                .defender
                .speed;
        }
    }

    function awardHalo(uint256 angelId) internal {
        // Make sure angel is not berakiel
        IABToken ABTokenData = IABToken(ABTokenDataContract);
        uint8 cardSeriesId;
        (cardSeriesId, , , , , , , , , ) = ABTokenData.getABToken(angelId);
        if (cardSeriesId == 0) {
            return;
        }

        // see how many Halo tokens the arena battles contract has
        // players can claim streams to add tokens up to 5 years
        IHalo Halo = IHalo(HaloTokenContract);
        uint256 myBalance = Halo.balanceOf(address(this));

        // send the tokens to the owner of the angel

        Halo.transfer(ABTokenData.ownerOf(angelId), myBalance / rewardDivisor);
    }

    //Read Functions

    //Function that returns all battle info for the address calling.
    // Call getBattleIdForAddress for the id.
    function getBattleResultsForCaller(address resultsFor)
        external
        view
        returns (
            uint64 id,
            uint8 round,
            uint16 defenderHp,
            uint8 defenderAction,
            uint16 defenderResultValue,
            uint16 defenderDefenseBuff,
            uint16 attackerHp,
            uint8 attackerAction,
            uint16 attackerResultValue,
            uint8 attackerPetAuraStatus,
            uint8 defenderPetAuraStatus,
            uint16 attackerDefenseBuff,
            bool attackerFirst
        )
    {
        //About the Battle
        id = addressBattleId[resultsFor];

        round = Battles[id].round;

        //About the defender
        defenderHp = Battles[id].defender.hp;
        defenderAction = Battles[id].defender.action;
        defenderResultValue = Battles[id].defender.resultValue;
        defenderDefenseBuff = Battles[id].defender.defenseBuff;
        defenderPetAuraStatus = Battles[id].defender.petAuraStatus;

        //About the angelTeam
        attackerHp = Battles[id].attacker.hp;
        attackerAction = Battles[id].attacker.action;
        attackerResultValue = Battles[id].attacker.resultValue;
        attackerDefenseBuff = Battles[id].attacker.defenseBuff;
        attackerPetAuraStatus = Battles[id].attacker.petAuraStatus;

        attackerFirst = Battles[id].attackerFirst;
    }

    //Get the monster stats on a battle that the caller is in. Must be separated from getBattleResultsForCaller due to stack too deep error.
    function getStaticOpponentStatsForCaller(address resultsFor)
        public
        view
        returns (
            uint256 angelId,
            uint256 petId,
            uint256 accessoryId,
            uint16 power,
            uint16 speed,
            uint16 auraRed,
            uint16 auraYellow,
            uint16 auraBlue,
            uint8 attackerAura,
            uint8 defenderAura
        )
    {
        uint64 id = addressBattleId[resultsFor];
        angelId = Battles[id].defender.angelId;
        petId = Battles[id].defender.petId;
        accessoryId = Battles[id].defender.accessoryId;
        power = Battles[id].defender.power;
        speed = Battles[id].defender.speed;
        auraRed = Battles[id].defender.auraRed;
        auraYellow = Battles[id].defender.auraYellow;
        auraBlue = Battles[id].defender.auraBlue;
        attackerAura = Battles[id].attacker.aura;
        defenderAura = Battles[id].defender.aura;
    }

    function getStaticAttackerStatsForCaller(address resultsFor)
        public
        view
        returns (
            uint16 power,
            uint16 speed,
            uint16 auraRed,
            uint16 auraYellow,
            uint16 auraBlue
        )
    {
        uint64 id = addressBattleId[resultsFor];
        power = Battles[id].attacker.power;
        speed = Battles[id].attacker.speed;
        auraRed = Battles[id].attacker.auraRed;
        auraYellow = Battles[id].attacker.auraYellow;
        auraBlue = Battles[id].attacker.auraBlue;
    }

    //Expose which battle a given address is currently fighting
    function getBattleIdForAddress(address _address)
        public
        view
        returns (uint64 id)
    {
        return addressBattleId[_address];
    }
}