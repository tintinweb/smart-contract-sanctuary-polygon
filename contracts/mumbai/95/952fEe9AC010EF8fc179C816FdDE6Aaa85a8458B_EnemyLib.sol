// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library EnemyLib {

    struct Enemy {
        int256 health;
        uint256 attack;
    }

    function assignEnemyStats(Enemy storage enemy, int256 _hp, uint256 _attack) public {
        enemy.health = _hp;
        enemy.attack  = _attack;
    }

    function getEnemyStats(Enemy storage enemy) view public returns (int256 hp, uint256 atk) {
        return (enemy.health, enemy.attack);
    }

    function attacked(Enemy storage enemy, uint256 _dmg) public {
        enemy.health -= int256(_dmg);
    }
}