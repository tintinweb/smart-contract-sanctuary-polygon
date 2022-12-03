/**
 *Submitted for verification at polygonscan.com on 2022-12-03
*/

//SPDX-License-Identifier: MIT License
pragma solidity ^0.8.0;

contract AccessControl {
    address public creatorAddress;

    modifier onlyCREATOR() {
        require(
            msg.sender == creatorAddress,
            'You are not the creator of this contract'
        );
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
            address owner
        );

    function setExperience(uint256 tokenId, uint16 _experience)
        external
        virtual;

    function setLastBattleTime(uint256 tokenId) external virtual;
}

abstract contract IABBattleSupport is AccessControl {
    function pickMonster(uint8 difficulty)
        public
        view
        virtual
        returns (
            uint8 monsterType,
            uint16 hp,
            uint16 power,
            uint16 auraRed,
            uint16 auraYellow,
            uint16 auraBlue,
            uint8 action,
            uint16 resultValue,
            uint16 defenseBuff
        );

    function buffLiquidMetalCornu(address winner) public virtual;

    function getInitialAngelHp(uint256 angelId, uint256 accessoryId)
        public
        view
        virtual
        returns (uint256);

    function getAuraCode(uint256 angelId) public view virtual returns (uint8);

    function getMonsterAttack(
        uint16 angelDefenseBuff,
        uint16 monsterPower,
        uint8 monsterType
    ) public virtual returns (uint8 action, uint16 resultValue);

    function getAuraEffects(
        uint256 petId,
        uint256 accSeriesId,
        uint16 monsterRed,
        uint16 monsterBlue,
        uint16 monsterYellow,
        uint16 power,
        uint16 defenseBuff
    )
        public
        view
        virtual
        returns (
            uint16 newPower,
            uint16 newSpeed,
            uint16 newDefenseBuff
        );
}

abstract contract IHalo {
    function transfer(address recipient, uint256 amount)
        external
        virtual
        returns (bool);

    function balanceOf(address owner) public virtual returns (uint256);
}

contract ABArenaBattles is AccessControl {
    //Data Structures
    struct Monster {
        uint8 monsterType;
        uint16 hp;
        uint16 power;
        uint16 auraRed;
        uint16 auraYellow;
        uint16 auraBlue;
        uint8 action;
        uint16 resultValue;
        //Mapping to an action and result for instance [1,34] == attack with 34 damage.
        uint16 defenseBuff;
    }

    struct AngelTeam {
        uint256 angelId;
        uint256 petId;
        uint256 accessoryId;
        uint16 power;
        uint8 aura;
        uint16 speed;
        uint16 hp;
        uint8 petAuraStatus;
        //00- neither released, 10- pet summoned, aura not yet, 01 - pet not yet, aura released, 11- both released.
        uint8 action;
        uint16 resultValue;
        uint16 defenseBuff;
    }

    //Store all the information about a particular battle.
    struct Battle {
        uint64 id; //id of the Battle
        bool angelFirst;
        uint8 status;
        AngelTeam angelTeam;
        Monster monster;
    }

    Battle[] Battles;

    // Next battle id (id 0 reserved for no battle found case)
    uint64 public totalBattles = 1;

    //Each card can only be in one battle at a time.
    mapping(uint256 => bool) cardsInBattle;

    //Figure out which battle each address is in
    mapping(address => uint64) addressBattleId;

    uint64 public bestAngel = 301; //experience of the top angel in the game.
    uint64 public petBattleDelay = 86400; // pets can battle once per day
    uint64 public angelBaseBattleDelay = 3600; //number of seconds for the shortest delay.
    uint16 public baseDefenseBuff = 20;

    uint256 rewardDivisor = 100; // 1% payout per battle

    address public ABTokenDataContract = address(0);
    address public ABBattleSupportContract = address(0);
    address public HaloTokenContract = address(0);

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

    //Write Functions

    constructor() {
        // First battle is special case reference battle where a player does not have any battles
        Battle memory battle;
        Battles.push(battle);
    }

    function setParameters(
        address _ABTokenDataContract,
        address _ABBattleSupportContract,
        address _HaloTokenContract,
        uint64 _bestAngel,
        uint64 _petBattleDelay,
        uint64 _angelBaseBattleDelay,
        uint256 _rewardDivisor,
        uint16 _baseDefenseBuff
    ) public onlyCREATOR {
        ABTokenDataContract = _ABTokenDataContract;
        ABBattleSupportContract = _ABBattleSupportContract;
        HaloTokenContract = _HaloTokenContract;
        bestAngel = _bestAngel; //experience of the top angel in the game.
        petBattleDelay = _petBattleDelay;
        angelBaseBattleDelay = _angelBaseBattleDelay; //number of seconds for the shortest delay.
        rewardDivisor = _rewardDivisor;
        baseDefenseBuff = _baseDefenseBuff;
    }

    //Function that anyone can call (under the proper parameters) to begin a battle.
    function startBattle(
        uint256 angelId,
        uint256 petId,
        uint256 accessoryId,
        uint8 difficulty
    ) public {
        Battle memory battle;
        AngelTeam memory angelTeam;
        IABBattleSupport ABBattleSupportData = IABBattleSupport(
            ABBattleSupportContract
        );

        checkBattleParameters(angelId, petId, accessoryId);

        //Initialize the angelTeam in the battle.
        angelTeam.angelId = angelId;
        angelTeam.petId = petId;
        angelTeam.accessoryId = accessoryId;
        angelTeam.hp = uint16(
            ABBattleSupportData.getInitialAngelHp(angelId, accessoryId)
        );
        angelTeam.petAuraStatus = 0;

        angelTeam.action = 0; //Action 0 means no action yet.
        angelTeam.resultValue = 0;
        angelTeam.defenseBuff = 0;
        angelTeam.power = getPower(angelId);
        angelTeam.speed = uint8(getPower(petId));
        angelTeam.aura = ABBattleSupportData.getAuraCode(angelId);

        // Aura bonuses
        if (angelTeam.aura == 0) {
            //blue
            angelTeam.defenseBuff = 10;
        } else if (angelTeam.aura == 3) {
            //orange
            angelTeam.hp += 50;
        } else if (angelTeam.aura == 4) {
            //red
            angelTeam.power += 10;
        } else if (angelTeam.aura == 5) {
            //green
            angelTeam.speed += 5;
        }

        //add cards to the in battle mapping
        cardsInBattle[angelId] = true;
        cardsInBattle[petId] = true;
        cardsInBattle[accessoryId] = true;

        battle.angelTeam = angelTeam;

        battle.id = totalBattles;
        battle.status = 1; //regular live battle
        Battles.push(battle);

        // Add a monster to the battle
        getMonster(difficulty, totalBattles);

        //apply initial aura effects.
        getAuraEffects(totalBattles);

        // Update current battle id for sender
        addressBattleId[msg.sender] = totalBattles;

        // Prepare id for next battle
        totalBattles++;
    }

    function getPower(uint256 tokenId) public view returns (uint16 power) {
        IABToken ABTokenData = IABToken(ABTokenDataContract);
        (, power, , , , , , ,) = ABTokenData.getABToken(tokenId);
        return power;
    }

    // Assign random monster to a battle
    // Difficulty is the arena number
    function getMonster(uint8 difficulty, uint64 battleId) internal {
        Monster memory monster;
        IABBattleSupport ABBattleSupportData = IABBattleSupport(
            ABBattleSupportContract
        );

        //initialize the monster team.
        (
            monster.monsterType,
            monster.hp,
            monster.power,
            monster.auraRed,
            monster.auraYellow,
            monster.auraBlue,
            ,
            ,
            monster.defenseBuff
        ) = ABBattleSupportData.pickMonster(difficulty);
        Battles[battleId].monster = monster;
    }

    //A function that adjusts parameters based on differences in Auras as well as accessory effects.
    function getAuraEffects(uint64 battleId) internal {
        uint16 power;
        uint16 speed;
        uint16 defenseBuff;
        uint8 accSeriesId;
        IABToken ABTokenData = IABToken(ABTokenDataContract);
        IABBattleSupport ABBattleSupportData = IABBattleSupport(
            ABBattleSupportContract
        );

        (accSeriesId, , , , , , , ,) = ABTokenData.getABToken(
            Battles[battleId].angelTeam.accessoryId
        );
        (power, speed, defenseBuff) = ABBattleSupportData.getAuraEffects(
            Battles[battleId].angelTeam.petId,
            accSeriesId,
            Battles[battleId].monster.auraRed,
            Battles[battleId].monster.auraBlue,
            Battles[battleId].monster.auraYellow,
            Battles[battleId].angelTeam.power,
            Battles[battleId].angelTeam.defenseBuff
        );
        Battles[battleId].angelTeam.power = power;
        Battles[battleId].angelTeam.speed = speed;
        Battles[battleId].angelTeam.defenseBuff = defenseBuff;
    }

    //apply the passive aura effect
    function auraPassive(uint64 battleId) internal returns (bool) {
        //Red + 10 bp applied to beginning of battle
        //Orange + 50 beginning hp
        //Blue + 10 beginning defense
        //Green + 5 beginning speed/luck
        bool purpleKilled = false;
        // yellow and purple apply every round
        uint8 chance = getRandomNumber(100, 0, msg.sender);
        //Yellow
        if (Battles[battleId].angelTeam.aura == 1) {
            Battles[battleId].angelTeam.hp += 20;
        }

        // Purple sudden kill chance
        if ((Battles[battleId].angelTeam.aura == 2) && (chance > 98)) {
            Battles[battleId].monster.hp = 0;
            Battles[battleId].angelTeam.action = 3;
            endBattle(battleId);
            purpleKilled = true;
        }
        return purpleKilled;
    }

    //Function that is called before each action. Check the battle parameters and apply the aura passives.
    function beforeRound(uint64 battleId) internal returns (bool) {
        //must check that msg.sender is the owner of the angel in the battle.
        require(
            addressBattleId[msg.sender] == battleId,
            "You aren't in this battle"
        );
        require(
            Battles[battleId].status < 100,
            'This battle is already over. '
        );
        //Update the battle round
        Battles[battleId].status++;

        // if the battle has been ended early due to purple aura sudden kill
        bool purpleKilled = auraPassive(battleId);
        return purpleKilled;
    }

    function attack(uint64 battleId) public {
        // Do not do the attack if purple aura release ended the 
        // battle early
        if (beforeRound(battleId)) {
            return;
        }

        uint16 attackDamage;
        if (Battles[battleId].angelTeam.power <= 120) {
            attackDamage = getRandomNumber(
                Battles[battleId].angelTeam.power,
                0,
                msg.sender
            );
        } else {
            attackDamage = getRandomNumber(
                Battles[battleId].angelTeam.power,
                uint8(Battles[battleId].angelTeam.power - 120),
                msg.sender
            );
        }
        Battles[battleId].angelTeam.action = 1;

        if (getOrder(battleId) == true) {
            Battles[battleId].angelTeam.resultValue = attackDamage;
            applyDamage(battleId, true, attackDamage);
            getMonsterAttack(battleId);
        } else {
            // Monster attacked first
            getMonsterAttack(battleId);
            Battles[battleId].angelTeam.resultValue = attackDamage;
            applyDamage(battleId, true, attackDamage);
        }
    }

    function defend(uint64 id) public {
        // Do not do the attack if purple aura release ended the 
        // battle early
        if (beforeRound(id)) {
            return;
        }

        uint8 extraDefense = getRandomNumber(
            2 * baseDefenseBuff,
            baseDefenseBuff,
            msg.sender
        );

        Battles[id].angelTeam.action = 4;
        Battles[id].angelTeam.resultValue = extraDefense;

        if (getOrder(id) == true) {
            Battles[id].angelTeam.defenseBuff += extraDefense;
            getMonsterAttack(id);
        } else {
            getMonsterAttack(id);
            Battles[id].angelTeam.defenseBuff += extraDefense;
        }
    }

    function auraBurst(uint64 id) public {
        require(
            (Battles[id].angelTeam.petAuraStatus != 1) &&
                (Battles[id].angelTeam.petAuraStatus != 11),
            'You have already released your aura'
        );
        if (beforeRound(id)) {
            return;
        }
        //00- neither released, 10- pet summoned, aura not yet, 01 - pet not yet, aura released, 11- both released.
        uint8 chance = getRandomNumber(100, 0, msg.sender);

        //blue
        if (Battles[id].angelTeam.aura == 0) {
            Battles[id].angelTeam.action = 8;
            Battles[id].angelTeam.petAuraStatus = 1;
        }
        //yellow
        if (Battles[id].angelTeam.aura == 1) {
            Battles[id].angelTeam.action = 12;
            Battles[id].monster.defenseBuff = 0;
        }
        //purple
        if (Battles[id].angelTeam.aura == 2) {
            if (chance >= 92) {
                Battles[id].monster.hp = 0;
                Battles[id].angelTeam.action = 10;
                endBattle(id);
            } else {
                Battles[id].angelTeam.action = 9;
            }
        }
        //orange
        if (Battles[id].angelTeam.aura == 3) {
            Battles[id].angelTeam.action = 13;
            Battles[id].angelTeam.defenseBuff += 25;
        }
        //red
        if (Battles[id].angelTeam.aura == 4) {
            Battles[id].angelTeam.action = 14;
            Battles[id].angelTeam.resultValue = getRandomNumber(
                Battles[id].angelTeam.power * 4,
                0,
                msg.sender
            );
        }
        //green
        if (Battles[id].angelTeam.aura == 5) {
            Battles[id].angelTeam.action = 11;
            Battles[id].angelTeam.hp += 100;
        }

        // Reflect that aura has been called.
        if (Battles[id].angelTeam.petAuraStatus == 10) {
            Battles[id].angelTeam.petAuraStatus = 11;
        }
        if (Battles[id].angelTeam.petAuraStatus == 0) {
            Battles[id].angelTeam.petAuraStatus = 1;
        }

        // Only red auras have a damage, so this is the only one
        // that depends on monster turn

        if (Battles[id].angelTeam.aura == 4) {
            if (getOrder(id)) {
                applyDamage(id, true, Battles[id].angelTeam.resultValue);
                getMonsterAttack(id);
            } else {
                getMonsterAttack(id);
                applyDamage(id, true, Battles[id].angelTeam.resultValue);
            }
        } else {
            getOrder(id); // record who went first
            getMonsterAttack(id);
        }
    }

    //Function to summon a pet for unexpected results.
    function summonPet(uint64 id) public {
        require(
            (Battles[id].angelTeam.petAuraStatus != 10) &&
                (Battles[id].angelTeam.petAuraStatus != 11),
            'You called but no pets were there to answer. '
        );
        if (beforeRound(id)) {
            return;
        }

        if (Battles[id].angelTeam.petAuraStatus == 0) {
            Battles[id].angelTeam.petAuraStatus = 10;
        }
        if (Battles[id].angelTeam.petAuraStatus == 1) {
            Battles[id].angelTeam.petAuraStatus = 11;
        }

        uint16 petEffect = 0;
        uint8 petAction = getRandomNumber(100, 0, msg.sender);

        if (petAction < 15) {
            Battles[id].angelTeam.action = 15;
        }
        if (petAction > 14 && petAction < 50) {
            Battles[id].angelTeam.action = 16;
            petEffect = getRandomNumber(70, 30, msg.sender);
        }
        if (petAction > 49 && petAction < 70) {
            Battles[id].angelTeam.action = 17;
            petEffect = getRandomNumber(
                Battles[id].angelTeam.speed * 10,
                Battles[id].angelTeam.speed * 5,
                msg.sender
            );
        }
        if (petAction > 69) {
            Battles[id].angelTeam.action = 18;
            Battles[id].angelTeam.hp += getRandomNumber(
                Battles[id].angelTeam.speed * 4,
                Battles[id].angelTeam.speed,
                msg.sender
            );
            Battles[id].angelTeam.speed += Battles[id].angelTeam.speed;
            petEffect = 50;
        }

        if (getOrder(id) == true) {
            Battles[id].angelTeam.resultValue = petEffect;
            applyDamage(id, true, petEffect);
            getMonsterAttack(id);
        } else {
            getMonsterAttack(id);
            Battles[id].angelTeam.resultValue = petEffect;
            applyDamage(id, true, petEffect);
        }
    }

    function getMonsterAttack(uint64 id) public {
        uint8 action;
        uint16 resultValue;

        IABBattleSupport IABBattleSupportData = IABBattleSupport(
            ABBattleSupportContract
        );

        (action, resultValue) = IABBattleSupportData.getMonsterAttack(
            Battles[id].angelTeam.defenseBuff,
            Battles[id].monster.power,
            Battles[id].monster.monsterType
        );

        // Monster's turn waste and buffs have result value of 0
        if (resultValue > 0 && (action == 1 || action >= 5)) {
            applyDamage(id, false, resultValue);
        }
        if (action == 2) {
            Battles[id].monster.defenseBuff += resultValue;
        }
        if (action == 3) {
            Battles[id].monster.hp += resultValue;
        }
        if (action == 4) {
            endBattle(id);
        }
        if (action == 8) {
            Battles[id].angelTeam.defenseBuff = 0;
        } //Cornu Defense debuff
        if (action == 11) {
            Battles[id].monster.power += 5;
        } //Moko attack buff
        if (action == 14) {
            Battles[id].monster.power += 20;
        } //Biersal raises his power
        if (action == 17) {
            Battles[id].angelTeam.power += 10;
        } //Nix increases your attack
        if (action == 20) {
            if (Battles[id].angelTeam.power >= 8) {
                Battles[id].angelTeam.power -= 8;
            } else {
                Battles[id].angelTeam.power = 0;
            }
        } //ColoColo lowers your attack.
        if (action == 23) {
            Battles[id].monster.power += 35;
        } //Foawr beefs up his attack.
        if (action == 26) {
            Battles[id].angelTeam.hp = 50;
        } //Lunkus sets your hp to 50.
        if (action == 29) {
            Battles[id].monster.power += 50;
        } //pamba increases attack by 50.
        if (action == 32) {
            Battles[id].monster.hp += 350;
        } //dire moko heals for 350
        if (action == 35) {
            Battles[id].monster.defenseBuff += 75;
        } //lunkus captain increases def by 75.
        if (action == 38) {
            //naughty nix increases hp and def
            Battles[id].monster.defenseBuff += 75;
            Battles[id].monster.hp += 100;
        }
        if (action == 41) {
            // great foar
            Battles[id].monster.power += 15;
            Battles[id].monster.hp += 80;
        }
        if (action == 44) {
            //liquid metal cornu
            Battles[id].monster.defenseBuff += 75;
            Battles[id].monster.hp += 99;
            Battles[id].monster.power += 20;
        }
        Battles[id].monster.action = action;
        Battles[id].monster.resultValue = resultValue;
    }

    //Internal Functions

    //Function that returns true if the angel moves first, false if the monster does.
    function getOrder(uint64 battleId) public returns (bool) {
        uint8 chance = getRandomNumber(100, 0, msg.sender);

        if (chance <= (25 + Battles[battleId].angelTeam.speed)) {
            Battles[battleId].angelFirst = true;
            return true;
        }
        Battles[battleId].angelFirst = false;
        return false;
    }

    //Function that updates the hp values and checks if the battle needs to be ended.
    //if fromAngel is false, then the damage is to be applied to the angel.
    function applyDamage(
        uint64 battleId,
        bool fromAngel,
        uint16 damage
    ) internal {
        if (fromAngel == true) {
            //If the angel is the one attacking, check if the monster can survive the hit.
            if (Battles[battleId].monster.hp > damage) {
                Battles[battleId].monster.hp =
                    Battles[battleId].monster.hp -
                    damage;
            } else {
                Battles[battleId].monster.hp = 0;
                endBattle(battleId);
            }
        }
        if (fromAngel == false) {
            //If the monster is the one attacking, check if the angel can survive the hit.
            if (Battles[battleId].angelTeam.hp > damage) {
                Battles[battleId].angelTeam.hp =
                    Battles[battleId].angelTeam.hp -
                    damage;
            } else {
                Battles[battleId].angelTeam.hp = 0;
                endBattle(battleId);
            }
        }
    }

    //don't need to set address back to 0, just check each action whether a battle is live.
    function endBattle(uint64 battleId) internal {
        IABToken ABTokenData = IABToken(ABTokenDataContract);

        //remove cards from the in battle mapping
        cardsInBattle[Battles[battleId].angelTeam.angelId] = false;
        cardsInBattle[Battles[battleId].angelTeam.petId] = false;
        cardsInBattle[Battles[battleId].angelTeam.accessoryId] = false;

        //If angel won, update experience
        if (Battles[battleId].monster.hp == 0) {
            awardHalo(Battles[battleId].angelTeam.angelId);
            Battles[battleId].status = 101;
            if (Battles[battleId].angelFirst) {
                // send back signal that the monster died.
                Battles[battleId].monster.action = 45;
            }
            uint16 experience;
            (, , , , , , experience, ,) = ABTokenData.getABToken(
                Battles[battleId].angelTeam.angelId
            );
            if (Battles[battleId].monster.monsterType <= 3) {
                experience += 1;
            }
            if (
                Battles[battleId].monster.monsterType >= 4 &&
                Battles[battleId].monster.monsterType <= 8
            ) {
                experience += 3;
            }
            if (Battles[battleId].monster.monsterType >= 9) {
                experience += 5;
            }
            if (Battles[battleId].monster.monsterType == 12) {
                experience += 5;
                IABBattleSupport IABBattleSupportData = IABBattleSupport(
                    ABBattleSupportContract
                );
                IABBattleSupportData.buffLiquidMetalCornu(msg.sender);
            } //extra 5 exp for liquid metal cornu

            if (experience > bestAngel) {
                bestAngel = experience;
            } //adjust the strongest angel if this battle changes it.

            ABTokenData.setExperience(
                Battles[battleId].angelTeam.angelId,
                experience
            );
        }
        //monster won
        else if (Battles[battleId].angelTeam.hp == 0) {
            Battles[battleId].status = 102;
            if (!Battles[battleId].angelFirst) {
                Battles[battleId].angelTeam.action = 19;
            }
        }
        //if neither won, then it's a running away, status 103.
        else {
            Battles[battleId].status = 103;
        }

        // Set last battle time for each token
        ABTokenData.setLastBattleTime(Battles[battleId].angelTeam.angelId);
        ABTokenData.setLastBattleTime(Battles[battleId].angelTeam.petId);

        if (Battles[battleId].angelTeam.accessoryId != 0) {
            ABTokenData.setLastBattleTime(
                Battles[battleId].angelTeam.accessoryId
            );
        }
    }

    function awardHalo(uint256 angelId) internal {
        // Make sure angel is not berakiel
        IABToken ABTokenData = IABToken(ABTokenDataContract);
        uint8 cardSeriesId;

        // not awarded for berakiel
        (cardSeriesId, , , , , , , ,) = ABTokenData.getABToken(angelId);
        if (cardSeriesId == 0) {
            return;
        }

        // see how many Halo tokens the arena battles contract has
        // players can claim streams to add tokens up to 5 years
        IHalo Halo = IHalo(HaloTokenContract);
        uint256 myBalance = Halo.balanceOf(address(this));

        // return if the contract has no balance
        if (myBalance == 0) {
            return;
        }

        // send the tokens to the owner of the angel

        Halo.transfer(ABTokenData.ownerOf(angelId), myBalance / rewardDivisor);
    }

    function checkBattleParameters(
        uint256 angelId,
        uint256 petId,
        uint256 accessoryId
    ) public view {
        IABToken ABTokenData = IABToken(ABTokenDataContract);

        //First of all make sure that the player is battling with cards they own.
        require(ABTokenData.ownerOf(angelId) == msg.sender, 'Not Angel Owner');
        require(ABTokenData.ownerOf(petId) == msg.sender, 'Not Pet Owner');
        require(
            ((ABTokenData.ownerOf(accessoryId) == msg.sender) ||
                (accessoryId == 0)),
            'Not Accessort Owner'
        );

        //Next, make sure the cards aren't currently battling
        require(cardsInBattle[angelId] == false, 'Angel already in Battle');
        require(cardsInBattle[petId] == false, 'Pet already in Battle');
        require(
            ((cardsInBattle[accessoryId] == false) || (accessoryId == 0)),
            'Accessory already in Battle'
        );

        //Make sure the cards aren't trying to battle during the cool down period.
        (, , , , , , , uint64 lastBattleTime, ) = ABTokenData.getABToken(
            angelId
        );
        require(
            block.timestamp > lastBattleTime + getBattleCooldown(angelId),
            'Angel in cooldown'
        );

        //Pets cannot battle within petBattleDelay battling.
        (, , , , , , , lastBattleTime,  ) = ABTokenData.getABToken(petId);
        require(
            block.timestamp > lastBattleTime + petBattleDelay,
            'Pet in cooldown'
        );
    }

    //Read Functions

    function getCurrentBattleResults(uint64 id)
        public
        view
        returns (
            uint64 battleId,
            uint16 monsterHp,
            uint16 angelHp,
            uint8 angelAction,
            uint16 angelResultValue,
            uint8 monsterAction,
            uint16 monsterResultValue,
            uint8 status,
            bool angelFirst,
            uint8 aura
        )
    {
        battleId = id;
        monsterHp = Battles[id].monster.hp;
        monsterAction = Battles[id].monster.action;
        monsterResultValue = Battles[id].monster.resultValue;
        angelHp = Battles[id].angelTeam.hp;
        angelAction = Battles[id].angelTeam.action;
        angelResultValue = Battles[id].angelTeam.resultValue;
        status = Battles[id].status;
        angelFirst = Battles[id].angelFirst;
        aura = Battles[id].angelTeam.aura;
    }

    //Function that returns all battle info for the address calling.
    function getBattleResultsForCaller(address resultsFor)
        public
        view
        returns (
            uint64 id,
            uint8 status,
            uint16 monsterHp,
            uint8 monsterAction,
            uint16 monsterResultValue,
            uint16 monsterDefenseBuff,
            uint16 angelHp,
            uint8 angelAction,
            uint16 angelResultValue,
            uint8 petAuraStatus,
            uint16 angelDefenseBuff,
            bool angelFirst
        )
    {
        //About the Battle
        id = addressBattleId[resultsFor];

        status = Battles[id].status;

        //About the Monster
        monsterHp = Battles[id].monster.hp;
        monsterAction = Battles[id].monster.action;
        monsterResultValue = Battles[id].monster.resultValue;
        monsterDefenseBuff = Battles[id].monster.defenseBuff;

        //About the angelTeam
        angelHp = Battles[id].angelTeam.hp;
        angelAction = Battles[id].angelTeam.action;
        angelResultValue = Battles[id].angelTeam.resultValue;
        petAuraStatus = Battles[id].angelTeam.petAuraStatus;

        angelDefenseBuff = Battles[id].angelTeam.defenseBuff;
        angelFirst = Battles[id].angelFirst;
    }

    function getStaticAngelStatsForCaller(address resultsFor)
        public
        view
        returns (uint16 power, uint16 speed)
    {
        //About the Battle
        uint64 id = addressBattleId[resultsFor];
        power = Battles[id].angelTeam.power;
        speed = Battles[id].angelTeam.speed;
    }

    //Get the monster stats on a battle that the caller is in. Must be separated from getBattleResultsForCaller due to stack too deep error.
    function getStaticMonsterStatsForCaller(address resultsFor)
        public
        view
        returns (
            uint8 monsterType,
            uint16 monsterPower,
            uint16 monsterAuraRed,
            uint16 monsterAuraYellow,
            uint16 monsterAuraBlue,
            uint8 aura
        )
    {
        uint64 id = addressBattleId[resultsFor];
        monsterType = Battles[id].monster.monsterType;
        monsterPower = Battles[id].monster.power;
        monsterAuraRed = Battles[id].monster.auraRed;
        monsterAuraYellow = Battles[id].monster.auraYellow;
        monsterAuraBlue = Battles[id].monster.auraBlue;
        aura = Battles[id].angelTeam.aura;
    }

    // Get the angel team stats on a battle that the caller is in.
    // Must be separated from getBattleResultsForCaller due to stack too deep error.
    function getStaticAngelTeamStatsForCaller(address resultsFor)
        public
        view
        returns (
            uint256 angelId,
            uint256 petId,
            uint256 accessoryId
        )
    {
        uint64 id = addressBattleId[resultsFor];
        angelId = Battles[id].angelTeam.angelId;
        petId = Battles[id].angelTeam.petId;
        accessoryId = Battles[id].angelTeam.accessoryId;
    }

    function getBattleCooldown(uint256 angelId) public view returns (uint64) {
        IABToken ABTokenData = IABToken(ABTokenDataContract);
        uint16 experience;
        (, , , , , , experience, , ) = ABTokenData.getABToken(angelId);
        if (experience >= bestAngel) {
            return 24 * angelBaseBattleDelay;
        }
        if (bestAngel - experience > 300) {
            return 0;
        }
        if (bestAngel - experience > 200) {
            return angelBaseBattleDelay;
        }
        if (bestAngel - experience > 100) {
            return 4 * angelBaseBattleDelay;
        }
        if (bestAngel - experience > 30) {
            return 8 * angelBaseBattleDelay;
        }
        return 0;
    }

    //Expose the experience of the strongest angel.
    function getBestAngel() public view returns (uint256) {
        return bestAngel;
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