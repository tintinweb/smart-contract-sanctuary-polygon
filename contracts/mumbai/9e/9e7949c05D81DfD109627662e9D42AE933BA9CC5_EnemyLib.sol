// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library EnemyLib {

    struct Enemy {
        int256 health;
        uint256 strength;
    }

    function assignEnemyStats(Enemy storage enemy, int256 _hp, uint256 _strength) public {
        enemy.health = _hp;
        enemy.strength  = _strength;
    }

    function getEnemyStats(Enemy storage enemy) view public returns (int256 hp, uint256 str){
        return (enemy.health, enemy.strength);
    }

    function attacked(Enemy storage enemy, uint256 _dmg) public {
        enemy.health -= int256(_dmg);
    }
}