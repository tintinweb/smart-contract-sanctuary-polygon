// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
import "./Constant.sol";
import "./IGame.sol";
import "./MultiStaticCall.sol";

interface IBullet {
    function bulletOf(address user) external view returns (uint256);
}

contract GameRecord is MultiStaticCall {
    struct LevelDetail {
        uint256 lv;
        uint256 user_bullet;
        uint256 user_damage;
    }

    function claimableRewardOf(
        IGame game,
        address user
    ) public view returns (uint256 total_reward) {
        total_reward = 0;
        (uint256 pre_roundId, uint256 pre_lv) = game.preRoundLevelOf(user);
        if (game.canRecycleLevelBullet(user)) {
            (, , uint256 recycled_total, ) = game.levelBulletOf(pre_roundId, pre_lv, user);
            total_reward += recycled_total;
        }

        if (game.canClaimPrizeReward(user)) {
            uint256 prize_reward = game.userPrizeRewardOf(pre_roundId, user);
            total_reward += prize_reward;
        }

        GameStructs.RoundLevel[] memory _lvs = game.killRewardRoundLevelsOf(user);
        for (uint i = 0; i < _lvs.length; i++) {
            if (game.canClaimKillReward(_lvs[i].roundId, _lvs[i].lv, user)) {
                uint256 kill_reward = game.killRewardOf(_lvs[i].roundId, _lvs[i].lv, user);
                total_reward += kill_reward;
            }
        }
    }

    function bulletAndClaimableOf(
        address game,
        address user
    ) public view returns (uint256 bullet_, uint256 claimable_) {
        bullet_ = IBullet(game).bulletOf(user);
        claimable_ = claimableRewardOf(IGame(game), user);
    }

    function levelDetailOf(
        IGame game,
        uint256 roundId_,
        uint256 lv_,
        address user_
    ) public view returns (LevelDetail memory detail) {
        (uint256 _lv, , , , ) = game.roundOf(roundId_);

        (uint256 _cur_roundId, ) = game.theLastLevel();

        if (roundId_ > _cur_roundId || lv_ > _lv) {
            detail = LevelDetail(0, 0, 0);
        } else {
            (uint256 total_bullet, uint256 user_bullet, uint256 boss_hp) = game.levelOf(
                roundId_,
                lv_,
                user_
            );
            if (boss_hp <= total_bullet) {
                uint256 _damage = (boss_hp * user_bullet) / total_bullet;
                detail = LevelDetail(lv_, user_bullet, _damage);
            } else {
                detail = LevelDetail(lv_, user_bullet, 0);
            }
        }
    }

    function levelDetailListOf(
        IGame game,
        uint256 roundId_,
        address user
    ) public view returns (LevelDetail[] memory list) {
        uint256[] memory lvs = game.attackedLvsOf(roundId_, user);
        list = new LevelDetail[](lvs.length);
        for (uint i = 0; i < lvs.length; i++) {
            list[i] = levelDetailOf(game, roundId_, lvs[i], user);
        }
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;
import "./GameStructs.sol";

interface IGame is GameStructs {
    function roundOf(
        uint256 roundId_
    )
        external
        view
        returns (
            uint256 _lv,
            uint256 _prize,
            Config memory _config,
            uint32[] memory _prize_config,
            address[] memory _prize_users
        );

    function canRecycleLevelBullet(address user_) external view returns (bool);

    function levelBulletOf(
        uint256 roundId_,
        uint256 lv_,
        address user_
    )
        external
        view
        returns (
            uint256 recycled_bullet,
            uint256 unused_bullet,
            uint256 recycled_total,
            uint256 user_bullet
        );

    function preRoundLevelOf(address user_) external view returns (uint256 _roundId, uint256 _lv);

    function canClaimPrizeReward(address user) external view returns (bool);

    function userPrizeRewardOf(
        uint256 roundId_,
        address user
    ) external view returns (uint256 reward);

    function killRewardRoundLevelsOf(address user) external view returns (RoundLevel[] memory _lvs);

    function canClaimKillReward(
        uint256 roundId_,
        uint256 lv_,
        address user
    ) external view returns (bool);

    function killRewardOf(
        uint256 roundId_,
        uint256 lv_,
        address user_
    ) external view returns (uint256 total_reward);

    function theLastLevel() external view returns (uint256 roundId_, uint256 lv_);

    function levelOf(
        uint256 roundId_,
        uint256 lv_,
        address user_
    ) external view returns (uint256 total_bullet, uint256 user_bullet, uint256 boss_hp);

    function attackedLvsOf(
        uint256 roundId_,
        address user
    ) external view returns (uint256[] memory lvs);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiStaticCall {
    function staticCall(address[] calldata addr, bytes[] calldata data)
        external
        view
        returns (bool[] memory bools,bytes[] memory results)
    {
        require(addr.length==data.length);
        bools = new bool[](data.length);
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(addr[i]).staticcall(
                data[i]
            );
            bools[i] = success;
            if(success) results[i] = result;
        }
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

library Constant {
    uint256 constant E4 = 10000;
    uint256 constant E3 = 1000;
    uint256 constant PRIZE_BLACK_TIME = 60;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface GameStructs {
    struct Config {
        uint256 base_hp;
        uint32 hp_scale;
        uint32 lock_lv;
        uint32 lock_percent;
        uint32 lv_reward_percent;
        uint32 prize_percent;
        uint32 attack_cd;
        uint32 escape_cd;
    }

    struct Boss {
        uint256 hp;
        uint64 born_time;
        uint64 attack_time;
        uint64 escape_time;
    }

    struct UserBullet {
        uint256 attacked;
        bool recycled;
        bool kill_reward_claimed;
    }

    struct Level {
        uint256 hp;
        uint256 total_bullet;
        mapping(address => UserBullet) user_bullet;
    }

    struct Round {
        uint256 lv;
        uint256 prize;
        Config config;
        uint32[] prize_config;
        address[] prize_users;
        mapping(address => uint256) prize_claimed;
    }

    struct RoundLevel {
        uint256 roundId;
        uint256 lv;
    }
}