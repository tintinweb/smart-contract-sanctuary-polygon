/**
 *Submitted for verification at polygonscan.com on 2022-12-03
*/

//SPDX-License-Identifier: MIT License
pragma solidity ^0.8.0;

contract AccessControl {
    address public creatorAddress;
    uint16 public totalSeraphims = 0;
    mapping(address => bool) public seraphims;

    modifier onlyCREATOR() {
        require(
            msg.sender == creatorAddress,
            'You are not the creator of this contract'
        );
        _;
    }

    modifier onlySERAPHIM() {
        require(
            seraphims[msg.sender] == true,
            "You don't have proper permission to do that"
        );
        _;
    }

    // Constructor
    constructor() {
        creatorAddress = payable(msg.sender);
    }

    function addSERAPHIM(address _newSeraphim) public onlyCREATOR {
        if (seraphims[_newSeraphim] == false) {
            seraphims[_newSeraphim] = true;
            totalSeraphims += 1;
        }
    }

    function removeSERAPHIM(address _oldSeraphim) public onlyCREATOR {
        if (seraphims[_oldSeraphim] == true) {
            seraphims[_oldSeraphim] = false;
            totalSeraphims -= 1;
        }
    }
    
    function changeOwner(address payable _newOwner) public onlyCREATOR {
        creatorAddress = _newOwner;
    }
}

abstract contract IABToken is AccessControl {
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

    function mintABToken(
        address owner,
        uint8 _cardSeriesId,
        uint16 _power,
        uint16 _auraRed,
        uint16 _auraYellow,
        uint16 _auraBlue,
        string memory _name,
        uint16 _experience
    ) public virtual;
}

contract ABBattleSupport is AccessControl {
    struct Monster {
        uint8 monsterType;
        uint16 hp;
        uint16 power;
        uint16 auraRed;
        uint16 auraYellow;
        uint16 auraBlue;
        uint8 action;
        uint16 resultValue;
        uint16 defenseBuff;
        //Mapping to an action and result for instance [1,34] == attack with 34 damage.
    }

    Monster[] Monsters; //Mapping holding base info about all Monsters.
    address public ABTokenDataContract = address(0);
    uint8 public smallAuraEffect = 15;
    uint8 public bigAuraEffect = 30;

    function setParameters(
        address _ABTokenDataContract,
        uint8 _smallAuraEffect,
        uint8 _bigAuraEffect
    ) public onlyCREATOR {
        ABTokenDataContract = _ABTokenDataContract;
        smallAuraEffect = _smallAuraEffect;
        bigAuraEffect = _bigAuraEffect;
    }

    function getRandomNumber(
        uint16 maxRandom,
        uint16 min,
        address privateAddress
    ) public view returns (uint16) {
        uint256 genNum = uint256(
            keccak256(abi.encodePacked(block.timestamp, privateAddress))
        );
        return uint16((genNum % (maxRandom - min + 1)) + min);
    }

    function initMonsters() public onlyCREATOR {
        // Wimpy Cirrus Meadows
        //cornu
        Monster memory monster;
        monster.monsterType = 0;
        monster.hp = 100;
        monster.power = 50;
        monster.auraRed = 25;
        monster.auraYellow = 30;
        monster.auraBlue = 15;
        monster.defenseBuff = 0;
        Monsters.push(monster);

        //moko
        monster.monsterType = 1;
        monster.hp = 150;
        monster.power = 70;
        monster.auraRed = 35;
        monster.auraYellow = 32;
        monster.auraBlue = 15;
        monster.defenseBuff = 10;
        Monsters.push(monster);

        //biersal
        monster.monsterType = 2;
        monster.hp = 200;
        monster.power = 90;
        monster.auraRed = 35;
        monster.auraYellow = 32;
        monster.auraBlue = 35;
        monster.defenseBuff = 15;
        Monsters.push(monster);

        //nix
        monster.monsterType = 3;
        monster.hp = 250;
        monster.power = 100;
        monster.auraRed = 25;
        monster.auraYellow = 32;
        monster.auraBlue = 19;
        monster.defenseBuff = 5;
        Monsters.push(monster);

        // Menacing Nimbus Forest
        //colo colo
        monster.monsterType = 4;
        monster.hp = 300;
        monster.power = 150;
        monster.auraRed = 25;
        monster.auraYellow = 32;
        monster.auraBlue = 19;
        monster.defenseBuff = 30;
        Monsters.push(monster);

        //foawr
        monster.monsterType = 5;
        monster.hp = 320;
        monster.power = 160;
        monster.auraRed = 25;
        monster.auraYellow = 60;
        monster.auraBlue = 19;
        monster.defenseBuff = 15;
        Monsters.push(monster);

        //lunkus
        monster.monsterType = 6;
        monster.hp = 340;
        monster.power = 180;
        monster.auraRed = 30;
        monster.auraYellow = 32;
        monster.auraBlue = 25;
        monster.defenseBuff = 25;
        Monsters.push(monster);

        //pamba
        monster.monsterType = 7;
        monster.hp = 360;
        monster.power = 200;
        monster.auraRed = 50;
        monster.auraYellow = 32;
        monster.auraBlue = 70;
        monster.defenseBuff = 35;
        Monsters.push(monster);

        // Thunderdome
        //dire moko
        monster.monsterType = 8;
        monster.hp = 400;
        monster.power = 300;
        monster.auraRed = 50;
        monster.auraYellow = 50;
        monster.auraBlue = 50;
        monster.defenseBuff = 45;
        Monsters.push(monster);

        //lunkus captain
        monster.monsterType = 9;
        monster.hp = 450;
        monster.power = 330;
        monster.auraRed = 75;
        monster.auraYellow = 75;
        monster.auraBlue = 75;
        monster.defenseBuff = 55;
        Monsters.push(monster);

        //naughty nix
        monster.monsterType = 10;
        monster.hp = 500;
        monster.power = 360;
        monster.auraRed = 75;
        monster.auraYellow = 75;
        monster.auraBlue = 75;
        monster.defenseBuff = 50;
        Monsters.push(monster);

        //great foawr
        monster.monsterType = 11;
        monster.hp = 550;
        monster.power = 400;
        monster.auraRed = 100;
        monster.auraYellow = 100;
        monster.auraBlue = 100;
        monster.defenseBuff = 55;
        Monsters.push(monster);

        //liquid metal cornu
        monster.monsterType = 12;
        monster.hp = 300;
        monster.power = 200;
        monster.auraRed = 120;
        monster.auraYellow = 120;
        monster.auraBlue = 120;
        monster.defenseBuff = 100;
        Monsters.push(monster);
    }

    function getMonsterAttack(
        uint16 angelDefenseBuff,
        uint16 monsterPower,
        uint8 monsterType
    ) public view returns (uint8 action, uint16 resultValue) {
        uint8 chance = uint8(getRandomNumber(100, 0, msg.sender));

        //Regular attack
        if (chance <= 40) {
            action = 1;
            uint16 monsterAttack = uint16(
                getRandomNumber(
                    uint16(2 * monsterPower),
                    monsterPower,
                    msg.sender
                )
            );
            if (monsterAttack >= angelDefenseBuff) {
                resultValue = monsterAttack - angelDefenseBuff;
            } else {
                resultValue = 0;
            }
            return (action, resultValue);
        }

        //Defense buff
        if (chance <= 50) {
            action = 2;
            resultValue = getRandomNumber(30, 20, msg.sender);
            return (action, resultValue);
        }

        //heal
        if (chance <= 60) {
            action = 3;
            resultValue = getRandomNumber(
                uint16(monsterPower * 2),
                10,
                msg.sender
            );
            return (action, resultValue);
        }
        //- no chance to run now
        // if (chance <= 65) {
        //     action = 4;
        //     resultValue = 0;
        //     return (action, resultValue);
        // }
        //desperate attack
        if (chance <= 65) {
            action = 5;
            resultValue = uint16(
                getRandomNumber(
                    uint16(3 * monsterPower),
                    monsterPower,
                    msg.sender
                )
            );
            return (action, resultValue);
        }
        //specific turn wasting attack
        if (chance <= 75) {
            action = 6 + (monsterType * 3);
            resultValue = 0;
            return (action, resultValue);
        }
        //specific strong attack
        if (chance <= 85) {
            action = 7 + (monsterType * 3);
            resultValue = uint16(
                getRandomNumber(
                    uint16(3 * monsterPower),
                    monsterPower,
                    msg.sender
                )
            );
            return (action, resultValue);
        }

        //specific move
        if (chance <= 100) {
            action = 8 + (monsterType * 3);
            resultValue = 0;
            return (action, resultValue);
        }
    }

    function getLureEffect(uint256 petId, uint256 accSeriesId)
        public
        view
        returns (uint16)
    {
        IABToken ABTokenData = IABToken(ABTokenDataContract);
        uint8 petSeriesId;

        (petSeriesId, , , , , , , , , ) = ABTokenData.getABToken(petId);
        // Non-elemental pet
        if (petSeriesId < 40) {
            // Accessory is carrot and pet is in horse line, etc
            if (
                (accSeriesId == 55 && (petSeriesId - 23) % 4 == 0) ||
                (accSeriesId == 56 && (petSeriesId - 23) % 4 == 1) ||
                (accSeriesId == 57 && (petSeriesId - 23) % 4 == 2) ||
                (accSeriesId == 58 && (petSeriesId - 23) % 4 == 3)
            ) {
                return smallAuraEffect;
            }
        }
        // Pet is Elemental and accessory is lightning rod
        else {
            if (accSeriesId == 59) {
                return bigAuraEffect;
            }
        }
        return 0;
    }

    // Function applied for arena battles. Vs Battles applies logic internally
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
        returns (
            uint16 newPower,
            uint16 newSpeed,
            uint16 newDefenseBuff
        )
    {
        IABToken ABTokenData = IABToken(ABTokenDataContract);

        uint16 red;
        uint16 yellow;
        uint16 blue;
        newPower = power;

        newDefenseBuff = defenseBuff;

        (, newSpeed, red, yellow, blue, , , , , ) = ABTokenData.getABToken(
            petId
        );

        newPower += getLureEffect(petId, accSeriesId);
        newSpeed += getLureEffect(petId, accSeriesId);

        if (accSeriesId == 43) {
            newPower += smallAuraEffect;
        }
        if (accSeriesId == 44) {
            newPower += bigAuraEffect;
        }
        if (accSeriesId == 47) {
            newSpeed += smallAuraEffect;
        }
        if (accSeriesId == 48) {
            newSpeed += bigAuraEffect;
        }

        //Account for colored accessories here.
        if (accSeriesId == 49) {
            red += smallAuraEffect;
        }
        if (accSeriesId == 50) {
            red += bigAuraEffect;
        }
        if (accSeriesId == 51) {
            yellow += smallAuraEffect;
        }
        if (accSeriesId == 52) {
            yellow += bigAuraEffect;
        }
        if (accSeriesId == 53) {
            blue += smallAuraEffect;
        }
        if (accSeriesId == 54) {
            blue += bigAuraEffect;
        }

        int16 diff;
        //See if it's positive or negative. Worst comes to worst, set a value to 1 instead of 0.

        /////////////////////////// Red Aura Difference increases attack.
        diff = getAuraDifferenceValue(red, monsterRed);
        if (diff > 0) {
            newPower += uint16(diff);
        }

        if (diff < 0) {
            if (newPower > uint16(diff * -1)) {
                newPower -= uint16(diff * -1);
            } else {
                newPower = 1;
            }
        }

        /////////////////////////// Blue Aura Difference increases defense.
        diff = getAuraDifferenceValue(blue, monsterBlue);
        if (diff > 0) {
            newDefenseBuff += uint16(diff);
        }
        if (diff < 0) {
            if (newDefenseBuff > uint16(diff)) {
                newDefenseBuff -= uint16(diff);
            } else {
                newDefenseBuff = 1;
            }
        }

        /////////////////////////// Yellow Aura Difference increases speed/luck.
        diff = getAuraDifferenceValue(yellow, monsterYellow);
        if (diff > 0) {
            newSpeed += uint16(diff);
        }

        if (diff < 0) {
            if (newSpeed > uint16(diff)) {
                newSpeed -= uint16(diff);
            } else {
                newSpeed = 1;
            }
        }
    }

    function updateMonster(
        uint8 _id,
        uint16 _hp,
        uint16 _power,
        uint16 _auraRed,
        uint16 _auraYellow,
        uint16 _auraBlue,
        uint16 _defenseBuff
    ) public onlyCREATOR {
        Monsters[_id].hp = _hp;
        Monsters[_id].auraRed = _auraRed;
        Monsters[_id].auraYellow = _auraYellow;
        Monsters[_id].auraBlue = _auraBlue;
        Monsters[_id].power = _power;
        Monsters[_id].defenseBuff = _defenseBuff;
    }

    function buffLiquidMetalCornu(address winner) public onlySERAPHIM {
        Monsters[12].hp += 5;
        Monsters[12].power += 4;

        // award medal to address who defeated

        IABToken ABTokenData = IABToken(ABTokenDataContract);
        ABTokenData.mintABToken(winner, 71, 0, 0, 0, 0, 'titanium', 0);
    }

    function pickMonster(uint8 difficulty)
        public
        view
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
        )
    {
        require(difficulty < 4, 'There are no more arenas');
        uint8 choice = uint8(getRandomNumber(100, 0, msg.sender));
        Monster memory monster;

        // Determine which monster to fight
        if (difficulty == 0) {
            // Pick Cornu for difficulty = 0
            monster = Monsters[0];
        } else {
            // Pick random monster for difficulty > 0
            uint8 monsterId;

            if (choice < 25) {
                monsterId = 0;
            } else if (choice < 50) {
                monsterId = 1;
            } else if (choice < 75) {
                monsterId = 2;
            } else {
                monsterId = 3;
            }

            // 4% chance to face Liquid Metal Cornu in any arena
            if (choice < 4) {
                monster = Monsters[12];
            } else {
                monster = Monsters[((difficulty - 1) * 4) + monsterId];
            }
        }

        monsterType = monster.monsterType;
        hp = monster.hp;
        power = monster.power;
        auraRed = monster.auraRed;
        auraYellow = monster.auraYellow;
        auraBlue = monster.auraBlue;
        action = 0;
        resultValue = 0;
        defenseBuff = monster.defenseBuff;
    }

    function getMonster(uint8 _id)
        public
        view
        returns (
            uint16 hp,
            uint16 power,
            uint16 auraRed,
            uint16 auraYellow,
            uint16 auraBlue,
            uint16 defenseBuff
        )
    {
        hp = Monsters[_id].hp;
        power = Monsters[_id].power;
        auraRed = Monsters[_id].auraRed;
        auraYellow = Monsters[_id].auraYellow;
        auraBlue = Monsters[_id].auraBlue;
        defenseBuff = Monsters[_id].defenseBuff;
    }

    function getInitialAngelHp(uint256 angelId, uint256 accessoryId)
        public
        view
        returns (uint256 hp)
    {
        IABToken ABTokenData = IABToken(ABTokenDataContract);
        uint16 bp;
        uint16 exp;
        uint8 accessorySeriesId;
        (, bp, , , , , exp, , , ) = ABTokenData.getABToken(angelId);

        // Leather and metal bracers do not affect initial hp
        (accessorySeriesId, , , , , , , , , ) = ABTokenData.getABToken(
            accessoryId
        );

        if (accessorySeriesId == 45) {
            exp += 50;
        }

        if (accessorySeriesId == 46) {
            exp += 100;
        }

        hp = (2 * bp) + getExpLevelValue(exp);

        return hp;
    }

    function getExpLevelValue(uint256 exp) public pure returns (uint256) {
        if ((exp) > 2000) {
            return 350;
        }
        if ((exp) > 1500) {
            return 300;
        }
        if ((exp) > 1100) {
            return 250;
        }

        if ((exp) > 850) {
            return 225;
        }

        if ((exp) > 650) {
            return 200;
        }

        if ((exp) > 500) {
            return 175;
        }

        if ((exp) > 375) {
            return 150;
        }

        if ((exp) > 275) {
            return 125;
        }

        if ((exp) > 200) {
            return 100;
        }

        if ((exp) > 100) {
            return 75;
        }

        if ((exp) > 40) {
            return 50;
        }

        return 0;
    }

    //use gradations to return a difference value
    function getAuraDifferenceValue(uint16 aura1, uint16 aura2)
        public
        pure
        returns (int16)
    {
        if (aura1 == aura2) {
            return 0;
        }

        if (aura1 > aura2) {
            if ((aura1 - aura2) > 400) {
                return 30;
            }
            if ((aura1 - aura2) > 200) {
                return 25;
            }
            if ((aura1 - aura2) > 100) {
                return 20;
            }
            if ((aura1 - aura2) > 60) {
                return 15;
            }
            if ((aura1 - aura2) > 40) {
                return 10;
            }
            if ((aura1 - aura2) > 20) {
                return 5;
            }
            return 2;
        }

        if (aura2 > aura1) {
            if ((aura2 - aura1) > 400) {
                return -30;
            }
            if ((aura2 - aura1) > 200) {
                return -25;
            }
            if ((aura2 - aura1) > 100) {
                return -20;
            }
            if ((aura2 - aura1) > 60) {
                return -15;
            }
            if ((aura2 - aura1) > 40) {
                return -10;
            }
            if ((aura2 - aura1) > 20) {
                return -5;
            }
            return -2;
        }
        //Something went wrong
        return 100;
    }

    //Function that returns an Aura number 0 - blue, 1 - yellow, 2 - purple, 3 orange 4 - red, 5 green.
    function getAuraCode(uint256 angelId) public view returns (uint8) {
        IABToken ABTokenData = IABToken(ABTokenDataContract);
        uint16 red;
        uint16 yellow;
        uint16 blue;

        (, , red, yellow, blue, , , , , ) = ABTokenData.getABToken(angelId);
        if ((red == 0) && (yellow == 0)) {
            return 0;
        }
        if ((red == 0) && (blue == 0)) {
            return 1;
        }
        if ((red == 1) && (blue == 1)) {
            return 2;
        }
        if ((red == 1) && (yellow == 1)) {
            return 3;
        }
        if ((blue == 0) && (yellow == 0)) {
            return 4;
        }
        if ((blue == 1) && (yellow == 1)) {
            return 5;
        }
        //Something went wrong
        return 100;
    }
}