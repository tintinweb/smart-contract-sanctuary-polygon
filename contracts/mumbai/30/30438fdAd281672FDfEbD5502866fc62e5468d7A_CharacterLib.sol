// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library CharacterLib {

    struct Character {
        uint256 level;
        int256 hp;
        uint256 strength;
        uint256 agility;
        uint256 intelligence;
        uint256 dexterity;
        uint256 luck;
        uint256 experience;
    }

    function setStats(Character storage character, 
        uint256 _lvl,
        int256 _hp, 
        uint256 _str,
        uint256 _agi,
        uint256 _int,
        uint256 _dex,
        uint256 _luk,
        uint256 _exp
        ) public {
            character.level = _lvl;
            character.hp = _hp;
            character.strength = _str;
            character.agility = _agi;
            character.intelligence = _int;
            character.dexterity = _dex;
            character.luck = _luk;
            character.experience = _exp;
    }

    function getStats(Character storage character) public view
        returns (
            uint256 level,
            int256 hp,
            uint256 strength,
            uint256 agility,
            uint256 intelligence,
            uint256 dexterity,
            uint256 luck,
            uint256 experience
        ) {
            return (
                character.level,
                character.hp,
                character.strength,
                character.agility,
                character.intelligence,
                character.dexterity,
                character.luck,
                character.experience
                );
        }

    function levelUp(Character storage character, uint256 _expRequired) public {
        character.level += 1;
        character.hp += 10;
        character.strength += 1;
        character.agility += 1;
        character.intelligence += 1;
        character.dexterity += 1;
        character.luck += 1;
        character.experience -= _expRequired;
    }

    function lvlUpExp(Character storage character) public view returns (uint256 experience) {
        uint256 _lvlUpExp = ((character.level-1) + character.level) * 150;
        return _lvlUpExp;
    }

    //Stack too deep when rerolling, splitting up the set stat function
    function setLevels(Character storage character, uint256 _lvl, uint256 _exp) public {
        character.level = _lvl;
        character.experience = _exp;
    }

    function setNewStats(Character storage character, 
            int256 _hp, 
            uint256 _str,
            uint256 _agi,
            uint256 _int,
            uint256 _dex,
            uint256 _luk
        ) public {
            character.hp = _hp;
            character.strength = _str;
            character.agility = _agi;
            character.intelligence = _int;
            character.dexterity = _dex;
            character.luck = _luk;
    }


}