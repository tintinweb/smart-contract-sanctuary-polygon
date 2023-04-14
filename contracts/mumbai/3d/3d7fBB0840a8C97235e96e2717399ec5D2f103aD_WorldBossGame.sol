// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./IGame.sol";
import "./Bullet.sol";
import "./GamePauseable.sol";

contract WorldBossGame is Bullet, GamePauseable, AutomationCompatible, IGame {
    event NewBoss(
        uint256 roundId,
        uint256 lv,
        uint256 hp,
        uint256 born_time,
        uint256 attack_time,
        uint256 escape_time
    );
    event PreAttack(address user, uint256 roundId, uint256 lv, uint256 bullet_mount);
    event Attack(address user, uint256 roundId, uint256 lv, uint256 bullet_mount);
    event Killed(uint256 roundId, uint256 lv, uint256 boss_hp, uint256 total_bullet);
    event Escaped(uint256 roundId, uint256 lv, uint256 boss_hp, uint256 total_bullet);

    event RecycleLevelBullet(address user, uint256 roundId, uint256 lv, uint256 amount);
    event ClaimKillReward(address user, uint256 roundId, uint256 lv, uint256 amount);
    event ClaimPrizeReward(address user, uint256 roundId, uint256 amount);
    event PrizeWinner(uint256 roundId, address[] winners);
    event IncreasePrize(uint256 roundId, address user, uint256 amount);

    uint256 public roundId;
    Config private global_config;
    uint32[] private global_prize_config;
    uint64 public born_cd_pre_attack;
    uint64 public born_cd_attack;
    Boss public boss;
    mapping(uint256 => Round) public rounds;
    mapping(uint256 => mapping(uint256 => Level)) private levels;
    mapping(address => RoundLevel) private userPreRoundLevel;
    mapping(address => RoundLevel[]) private killRewardRoundLevels;
    /**       user              roundId     levels */
    mapping(address => mapping(uint256 => uint256[])) private attacked_lvs;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address owner_,
        address admin_,
        address system_wallet_,
        address fee_wallet_,
        address token_,
        uint256 fee_
    ) public initializer {
        _initOwnable(owner_, admin_);
        _initBullet(token_, system_wallet_, fee_wallet_, fee_);
        born_cd_pre_attack = 300;
        born_cd_attack = 1800;
        global_config = Config(3000000000000000000000, 10900, 3, 4000, 800, 100, 300, 21300);
        global_prize_config = [800, 800, 800, 2500, 5100];
    }

    function setConfig(
        uint256 base_hp_,
        uint32 hp_scale,
        uint32 lock_lv_,
        uint32 lock_percent_,
        uint32 lv_reward_percent_,
        uint32 prize_percent_,
        uint32 attack_cd,
        uint32 escape_cd,
        uint32[] memory prize_config_
    ) external onlyOwner {
        require(base_hp_ > 0);
        require(hp_scale > 0);
        require(lock_lv_ > 0);
        require(lock_percent_ > 0 && lock_percent_ < Constant.E4);
        require(lv_reward_percent_ > 0 && lv_reward_percent_ < Constant.E4);
        require(prize_percent_ > 0 && prize_percent_ < Constant.E4);
        require(attack_cd > 0);
        require(escape_cd > 0);
        global_config = Config(
            base_hp_,
            hp_scale,
            lock_lv_,
            lock_percent_,
            lv_reward_percent_,
            prize_percent_,
            attack_cd,
            escape_cd
        );
        uint256 _total;
        for (uint i = 0; i < prize_config_.length; i++) {
            _total += prize_config_[i];
        }
        require(_total == Constant.E4, "The sum of the prize pool shares is not 100%");
        global_prize_config = prize_config_;
    }

    function _cloneConfigToRound() internal {
        Round storage round = rounds[roundId];
        require(round.config.base_hp == 0);
        round.config.base_hp = global_config.base_hp;
        round.config.hp_scale = global_config.hp_scale;
        round.config.lock_lv = global_config.lock_lv;
        round.config.lock_percent = global_config.lock_percent;
        round.config.lv_reward_percent = global_config.lv_reward_percent;
        round.config.prize_percent = global_config.prize_percent;
        round.config.attack_cd = global_config.attack_cd;
        round.config.escape_cd = global_config.escape_cd;

        round.prize_config = global_prize_config;
    }

    function startGame() external onlyAdmin whenGameNotPaused {
        require(global_config.base_hp > 0);
        roundId = 1;
        rounds[roundId].lv = 1;
        _cloneConfigToRound();
        _bornBoss();
    }

    function _increaseHp() internal view returns (uint256 _hp) {
        Config storage _round_config = rounds[roundId].config;
        if (rounds[roundId].lv == 1) {
            _hp = _round_config.base_hp;
        } else {
            _hp = (boss.hp * _round_config.hp_scale) / Constant.E4;
        }
    }

    function _bornBoss() internal {
        Config storage _round_config = rounds[roundId].config;
        uint256 _hp = _increaseHp();
        uint256 _born_time;

        if (rounds[roundId].lv > 1) {
            Level storage pre_lv = levels[roundId][rounds[roundId].lv - 1];
            if (pre_lv.total_bullet > pre_lv.hp) {
                _born_time =
                    block.timestamp +
                    born_cd_pre_attack -
                    (block.timestamp % born_cd_pre_attack);
            } else {
                _born_time = block.timestamp + born_cd_attack - (block.timestamp % born_cd_attack);
            }
        } else {
            _born_time = block.timestamp + born_cd_attack - (block.timestamp % born_cd_attack);
        }

        uint256 _attack_time = _born_time + _round_config.attack_cd;
        uint256 _escape_time = _attack_time + _round_config.escape_cd;
        boss = Boss(_hp, uint64(_born_time), uint64(_attack_time), uint64(_escape_time));
        levels[roundId][rounds[roundId].lv].hp = _hp;
        emit NewBoss(
            roundId,
            rounds[roundId].lv,
            boss.hp,
            boss.born_time,
            boss.attack_time,
            boss.escape_time
        );
    }

    function _frozenLevelReward(uint256 roundId_) internal {
        Config storage _round_config = rounds[roundId_].config;
        uint256 _lv_reward = (boss.hp * _round_config.lv_reward_percent) / Constant.E4;
        _addFrozenBullet(_lv_reward);
    }

    function preAttack(
        uint256 roundId_,
        uint256 lv_,
        uint256 bullet_amount_
    ) external whenGameNotPaused {
        _preAttack(msg.sender, roundId_, lv_, bullet_amount_);
    }

    function _preAttack(
        address user_,
        uint256 roundId_,
        uint256 lv_,
        uint256 bullet_amount_
    ) internal {
        require(roundId == roundId_, "invalid roundId_");
        require(rounds[roundId].lv == lv_, "invalid lv_");
        require(block.timestamp > boss.born_time, "boss isn't born yet");
        require(block.timestamp <= boss.attack_time, "invalid time");
        _autoClaim(user_);
        _pushRoundLevel(user_);
        _reduceBullet(user_, bullet_amount_);
        Level storage level = levels[roundId_][lv_];
        level.user_bullet[user_].attacked += bullet_amount_;
        level.total_bullet += bullet_amount_;
        _updatePrizeUser(user_, bullet_amount_);
        emit PreAttack(user_, roundId_, lv_, bullet_amount_);
    }

    function attack(
        uint256 roundId_,
        uint256 lv_,
        uint256 bullet_amount_
    ) external whenGameNotPaused {
        _attack(msg.sender, roundId_, lv_, bullet_amount_);
    }

    function decideEscapedOrDead() public whenGameNotPaused {
        Level storage level = levels[roundId][rounds[roundId].lv];
        if (boss.hp <= level.total_bullet) {
            require(block.timestamp > boss.attack_time, "invalid time");
            _dead();
        } else {
            require(block.timestamp > boss.escape_time, "invalid time");
            _escape();
        }
    }

    function checkUpkeep(
        bytes calldata /**checkData */
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        performData = bytes("");

        if (!isPausing && roundId > 0) {
            Level storage level = levels[roundId][rounds[roundId].lv];
            if (boss.hp <= level.total_bullet) {
                // boss dead
                upkeepNeeded = block.timestamp > boss.attack_time + 300;
            } else {
                upkeepNeeded = block.timestamp > boss.escape_time + 300;
            }
        }
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        decideEscapedOrDead();
    }

    /**
     * on boss dead
     */
    function _dead() internal {
        emit Killed(
            roundId,
            rounds[roundId].lv,
            boss.hp,
            levels[roundId][rounds[roundId].lv].total_bullet
        );
        _frozenLevelReward(roundId);
        _frozenPrizeReward(roundId);
        _nextLevel();
    }

    /**
     * on boss escaped
     */
    function _escape() internal {
        require(block.timestamp > boss.escape_time);
        Level storage level = levels[roundId][rounds[roundId].lv];
        require(boss.hp > level.total_bullet);
        _unfrozenLevelRewardAndClaimBulletToSystem();
        emit Escaped(roundId, rounds[roundId].lv, boss.hp, level.total_bullet);
        emit PrizeWinner(roundId, rounds[roundId].prize_users);
        _nextRound();
    }

    function _attack(
        address user_,
        uint256 roundId_,
        uint256 lv_,
        uint256 bullet_amount_
    ) internal {
        require(roundId == roundId_, "invalid roundId_");
        require(rounds[roundId].lv == lv_, "invalid lv_");
        require(block.timestamp > boss.attack_time, "invalid time");
        require(block.timestamp <= boss.escape_time, "boss escaped");
        Level storage level = levels[roundId_][lv_];
        require(boss.hp > level.total_bullet, "boss was dead");

        if (bullet_amount_ > boss.hp - level.total_bullet) {
            bullet_amount_ = boss.hp - level.total_bullet;
        }
        _autoClaim(user_);
        _pushRoundLevel(user_);
        _reduceBullet(user_, bullet_amount_);
        level.user_bullet[user_].attacked += bullet_amount_;
        level.total_bullet += bullet_amount_;
        _updatePrizeUser(user_, bullet_amount_);
        emit Attack(user_, roundId, rounds[roundId].lv, bullet_amount_);
        if (level.total_bullet >= boss.hp) {
            _dead();
        }
    }

    function _pushRoundLevel(address user_) internal {
        if (levels[roundId][rounds[roundId].lv].user_bullet[user_].attacked > 0) return;
        attacked_lvs[user_][roundId].push(rounds[roundId].lv);
        userPreRoundLevel[user_].roundId = roundId;
        userPreRoundLevel[user_].lv = rounds[roundId].lv;
        killRewardRoundLevels[user_].push(RoundLevel(roundId, rounds[roundId].lv));
    }

    function autoClaim() external whenGameNotPaused {
        _autoClaim(msg.sender);
    }

    function _autoClaim(address user_) internal {
        if (canRecycleLevelBullet(user_)) {
            _recycleLevelBullet(user_);
        }

        if (canClaimPrizeReward(user_)) {
            _claimPrizeReward(user_);
        }

        RoundLevel[] memory kr_lvs = killRewardRoundLevels[user_];
        for (uint i = 0; i < kr_lvs.length; i++) {
            if (canClaimKillReward(kr_lvs[i].roundId, kr_lvs[i].lv, user_)) {
                _claimKillReward(user_, kr_lvs[i].roundId, kr_lvs[i].lv);
            } else {
                if (roundId > kr_lvs[i].roundId) {
                    _removeFromKillRewardRoundLevel(user_, kr_lvs[i].roundId, kr_lvs[i].lv);
                }
            }
        }
    }

    function _frozenPrizeReward(uint256 roundId_) internal {
        Config storage _round_config = rounds[roundId_].config;
        uint256 _add_prize = (boss.hp * _round_config.prize_percent) / Constant.E4;
        rounds[roundId].prize += _add_prize;
        _addFrozenBullet(_add_prize);
    }

    function _nextLevel() internal {
        delete rounds[roundId].prize_users;
        rounds[roundId].lv++;
        _bornBoss();
    }

    function canRecycleLevelBullet(address user) public view returns (bool) {
        uint256 roundId_ = userPreRoundLevel[user].roundId;
        uint256 lv_ = userPreRoundLevel[user].lv;
        if (rounds[roundId_].lv == lv_) return false;
        Level storage level = levels[roundId_][lv_];
        if (level.user_bullet[user].attacked == 0) return false;
        if (level.user_bullet[user].recycled) return false;
        return true;
    }

    function levelBulletOf(
        uint256 roundId_,
        uint256 lv_,
        address user_
    )
        public
        view
        returns (
            uint256 recycled_bullet,
            uint256 unused_bullet,
            uint256 recycled_total,
            uint256 user_bullet
        )
    {
        Level storage level = levels[roundId_][lv_];
        Config storage _round_config = rounds[roundId_].config;
        user_bullet = level.user_bullet[user_].attacked;
        if (level.total_bullet >= level.hp) {
            uint256 _damage = (level.hp * user_bullet) / level.total_bullet;
            if (user_bullet > _damage) unused_bullet = user_bullet - _damage;
            recycled_bullet = (_damage * (Constant.E4 - _round_config.lock_percent)) / Constant.E4;
            recycled_total = unused_bullet + recycled_bullet;
        }
    }

    function _recycleLevelBullet(address user_) internal {
        uint256 roundId_ = userPreRoundLevel[user_].roundId;
        uint256 lv_ = userPreRoundLevel[user_].lv;
        Level storage level = levels[roundId_][lv_];
        (, , uint256 total, ) = levelBulletOf(roundId_, lv_, user_);
        level.user_bullet[user_].recycled = true;
        _addBullet(user_, total);
        emit RecycleLevelBullet(user_, roundId_, lv_, total);
    }

    function canClaimKillReward(
        uint256 roundId_,
        uint256 lv_,
        address user
    ) public view returns (bool) {
        Config storage _round_config = rounds[roundId_].config;
        if (rounds[roundId_].lv <= lv_ + _round_config.lock_lv) return false;
        Level storage level = levels[roundId_][lv_];
        if (level.user_bullet[user].attacked == 0) return false;
        if (level.user_bullet[user].kill_reward_claimed) return false;
        return true;
    }

    function killRewardOf(
        uint256 roundId_,
        uint256 lv_,
        address user_
    ) public view returns (uint256 total_reward) {
        Config storage _round_config = rounds[roundId_].config;
        require(rounds[roundId_].lv > lv_ + _round_config.lock_lv);
        if (rounds[roundId_].lv > lv_ + _round_config.lock_lv) {
            Level storage level = levels[roundId_][lv_];
            uint256 _damage = (level.hp * level.user_bullet[user_].attacked) / level.total_bullet;
            total_reward =
                (_damage * (_round_config.lock_percent + _round_config.lv_reward_percent)) /
                Constant.E4;
        }
    }

    function _claimKillReward(address user_, uint256 roundId_, uint256 lv_) internal {
        uint256 total_reward = killRewardOf(roundId_, lv_, user_);
        Level storage level = levels[roundId_][lv_];
        level.user_bullet[user_].kill_reward_claimed = true;
        _addBullet(user_, total_reward);
        emit ClaimKillReward(user_, roundId_, lv_, total_reward);
        _removeFromKillRewardRoundLevel(user_, roundId_, lv_);
    }

    function _removeFromKillRewardRoundLevel(
        address user_,
        uint256 roundId_,
        uint256 lv_
    ) internal {
        uint256 index = 0;
        bool _to_remove = false;
        RoundLevel[] storage _lvs = killRewardRoundLevels[user_];
        for (uint i = 0; i < _lvs.length; i++) {
            if (_lvs[i].roundId == roundId_ && _lvs[i].lv == lv_) {
                index = i;
                _to_remove = true;
            }
        }
        if (_to_remove) {
            _lvs[index] = _lvs[_lvs.length - 1];
            _lvs.pop();
        }
    }

    function _unfrozenLevelRewardAndClaimBulletToSystem() internal {
        uint256 _lastLv = rounds[roundId].lv;
        Config storage _round_config = rounds[roundId].config;
        for (uint i = 1; i <= _round_config.lock_lv; i++) {
            if (_lastLv > i) {
                uint256 _boss_hp = levels[roundId][_lastLv - i].hp;
                // //unfrozen level reward
                uint256 _lv_reward = (_boss_hp * _round_config.lv_reward_percent) / Constant.E4;
                _reduceFrozenBullet(_lv_reward);
                //claim locked bullet to system
                _addSystemBullet((_boss_hp * _round_config.lock_percent) / Constant.E4);
            } else {
                break;
            }
        }
    }

    function _nextRound() internal {
        roundId++;
        rounds[roundId].lv = 1;
        _cloneConfigToRound();
        _bornBoss();
        rounds[roundId].prize = _leftPrizeRewardOf(roundId - 1);
    }

    function canClaimPrizeReward(address user) public view returns (bool) {
        uint256 roundId_ = userPreRoundLevel[user].roundId;

        if (roundId == roundId_) return false;

        Round storage round = rounds[roundId_];
        if (round.prize_claimed[user] > 0) return false;

        Level storage level = levels[roundId_][rounds[roundId_].lv];
        if (level.user_bullet[user].attacked == 0) return false;

        return true;
    }

    function userPrizeRewardOf(
        uint256 roundId_,
        address user
    ) public view returns (uint256 reward) {
        if (roundId_ == roundId) reward = 0;
        Round storage round = rounds[roundId_];
        address[] storage prize_users = round.prize_users;
        uint32[] storage prize_config = round.prize_config;
        uint256 offset = prize_config.length - prize_users.length;
        for (uint256 i = 0; i < prize_users.length; i++) {
            if (user == prize_users[i]) {
                reward += (round.prize * prize_config[i + offset]) / Constant.E4;
            }
        }

        Level storage level = levels[roundId_][round.lv];
        reward += level.user_bullet[user].attacked;
    }

    function prizeWinnersOf(
        uint256 roundId_
    ) public view returns (address[] memory users, uint256 prize, uint32[] memory prize_config) {
        Round storage round = rounds[roundId_];
        address[] storage prize_users = round.prize_users;
        users = prize_users;
        prize = round.prize;
        prize_config = round.prize_config;
    }

    function _leftPrizeRewardOf(uint256 roundId_) internal view returns (uint256 left) {
        require(roundId_ < roundId);
        Round storage round = rounds[roundId_];
        address[] storage prize_users = round.prize_users;
        uint32[] storage prize_config = round.prize_config;
        uint256 length = prize_config.length - prize_users.length;
        uint256 _left_percent;
        for (uint256 i = 0; i < length; i++) {
            _left_percent += prize_config[i];
        }
        left = (round.prize * _left_percent) / Constant.E4;
    }

    function _claimPrizeReward(address user_) internal {
        uint256 roundId_ = userPreRoundLevel[user_].roundId;
        uint256 _reward = userPrizeRewardOf(roundId_, user_);
        rounds[roundId_].prize_claimed[user_] = _reward;
        _addBullet(user_, _reward);
        emit ClaimPrizeReward(user_, roundId_, _reward);
    }

    function increasePrize(uint256 amount) external payable nonReentrant whenGameNotPaused {
        require(roundId > 0, "game don't start");
        if (token == address(0)) {
            require(amount == msg.value, "invalid msg.value");
        } else {
            require(0 == msg.value, "invalid msg.value");
            SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);
        }
        rounds[roundId].prize += amount;
        emit IncreasePrize(roundId, msg.sender, amount);
    }

    function _updatePrizeUser(address user_, uint256 bullet_) internal {
        Round storage round = rounds[roundId];
        if (block.timestamp + Constant.PRIZE_BLACK_TIME > boss.escape_time) return;

        if (bullet_ >= boss.hp / 100) {
            address[] storage prize_users = round.prize_users;
            if (prize_users.length < round.prize_config.length) {
                prize_users.push(user_);
            } else {
                for (uint i = 1; i < prize_users.length; i++) {
                    prize_users[i - 1] = prize_users[i];
                }
                prize_users[prize_users.length - 1] = user_;
            }
            require(prize_users.length <= round.prize_config.length);
        }
    }

    function updateBornCD(uint64 born_cd_pre_attack_, uint64 born_cd_attack_) external onlyAdmin {
        born_cd_pre_attack = born_cd_pre_attack_;
        born_cd_attack = born_cd_attack_;
    }

    function _beforeWithdraw() internal override {
        _autoClaim(msg.sender);
    }

    function levelOf(
        uint256 roundId_,
        uint256 lv_,
        address user_
    ) public view returns (uint256 total_bullet, uint256 user_bullet, uint256 boss_hp) {
        total_bullet = levels[roundId_][lv_].total_bullet;
        user_bullet = levels[roundId_][lv_].user_bullet[user_].attacked;
        boss_hp = levels[roundId_][lv_].hp;
    }

    function theLastLevel() public view returns (uint256 roundId_, uint256 lv_) {
        roundId_ = roundId;
        lv_ = rounds[roundId].lv;
    }

    function onGameResume() internal virtual override {
        boss.escape_time += uint64(unpauseTime - pauseTime);
    }

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
        )
    {
        _lv = rounds[roundId_].lv;
        _prize = rounds[roundId_].prize;
        _config = rounds[roundId_].config;
        _prize_config = rounds[roundId_].prize_config;
        _prize_users = rounds[roundId_].prize_users;
    }

    function preRoundLevelOf(address user_) external view returns (uint256 _roundId, uint256 _lv) {
        _roundId = userPreRoundLevel[user_].roundId;
        _lv = userPreRoundLevel[user_].lv;
    }

    function killRewardRoundLevelsOf(
        address user
    ) external view returns (RoundLevel[] memory _lvs) {
        _lvs = killRewardRoundLevels[user];
    }

    function attackedLvsOf(
        uint256 roundId_,
        address user
    ) external view returns (uint256[] memory lvs) {
        lvs = attacked_lvs[user][roundId_];
    }

    function getUserProxyInfo(
        address user
    ) public view returns (address proxy_address_, uint256 max_round_id_, uint256 max_lv) {
        UserProxyInfo storage proxyInfo = _userProxy[user];
        proxy_address_ = proxyInfo.proxy_address;
        max_round_id_ = proxyInfo.max_round_id;
        max_lv = proxyInfo.max_lv;
    }

    function setUserProxyAddress(address proxy_address_) external whenGameNotPaused {
        _userProxy[msg.sender].proxy_address = proxy_address_;
    }

    function setUserProxyMaxRoundAndLevel(
        uint256 max_round_id_,
        uint256 max_lv_
    ) external whenGameNotPaused {
        _userProxy[msg.sender].max_round_id = max_round_id_;
        _userProxy[msg.sender].max_lv = max_lv_;
    }

    function _checkProxy(address original_user_, uint256 roundId_, uint256 lv_) internal view {
        UserProxyInfo storage proxyInfo = _userProxy[original_user_];
        require(proxyInfo.proxy_address == msg.sender, "invalid proxy");
        require(roundId_ <= proxyInfo.max_round_id, "roundId_ > max_round_id_");
        require(lv_ <= proxyInfo.max_lv, "lv_ > max_lv");
    }

    function proxyPreAttack(
        address original_user_,
        uint256 roundId_,
        uint256 lv_,
        uint256 bullet_amount_
    ) external whenGameNotPaused {
        _checkProxy(original_user_, roundId_, lv_);
        _preAttack(original_user_, roundId_, lv_, bullet_amount_);
    }

    function proxyAttack(
        address original_user_,
        uint256 roundId_,
        uint256 lv_,
        uint256 bullet_amount_
    ) external whenGameNotPaused {
        require(msg.sender.code.length == 0, "EOA only");
        _checkProxy(original_user_, roundId_, lv_);
        _attack(original_user_, roundId_, lv_, bullet_amount_);
    }

    // upgrade version vars
    struct UserProxyInfo {
        address proxy_address;
        uint256 max_round_id;
        uint256 max_lv;
    }

    mapping(address => UserProxyInfo) private _userProxy; // mapping slot : the same as uint256

    uint256[63] private __gap; // original:  uint256[64] private __gap;
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
import "./OwnableUpgradeable.sol";

abstract contract GamePauseable is OwnableUpgradeable {
    event Paused(address account);
    event Unpaused(address account);
    bool public isPausing;
    uint256 public pauseTime;
    uint256 public unpauseTime;

    modifier whenGameNotPaused() {
        require(!isPausing, "Pausable: paused");
        _;
    }

    function setGamePause(bool pause_) external onlyAdmin {
        require(isPausing != pause_);
        isPausing = pause_;
        if (isPausing) {
            pauseTime = block.timestamp;
            emit Paused(address(this));
        } else {
            unpauseTime = block.timestamp;
            onGameResume();
            emit Unpaused(address(this));
        }
    }

    function onGameResume() internal virtual {}
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./BulletPauseable.sol";
import "./Constant.sol";

abstract contract Bullet is
    ReentrancyGuardUpgradeable,
    BulletPauseable
{
    struct WithdrawForm {
        uint256 amount;
        uint256 time;
    }
    event Topup(address user, uint256 amount);
    event PreWithdraw(address user, uint256 amount, uint256 timestamp);
    event Withdraw(address user, uint256 amount, uint256 timestamp);
    event ChargeFee(address user, uint256 amount);
    event WithdrawCDUpdated(uint256 cd);
    event FeeUpdated(uint256 fee);
    event TopupToSystem(address user, uint256 amount);
    event WithdrawFromSystem(address user, uint256 amount);

    mapping(address => uint256) private _bullet_balance;
    mapping(address => uint256) private _topup_block;
    mapping(address => WithdrawForm) public withdraw_form;
    address public token;
    uint256 public fee;
    uint256 private _system_bullet;
    address public system_wallet;
    address public fee_wallet;
    uint256 private _frozen_bullet;
    uint256 public withdraw_cd;

    function _initBullet(
        address token_,
        address system_wallet_,
        address fee_wallet_,
        uint256 fee_
    ) internal {
        token = token_;
        _setWallet(system_wallet_, fee_wallet_);
        require(fee_ <= Constant.E3);
        fee = fee_;
        withdraw_cd = 86400;
    }

    function _setWallet(address system_wallet_, address fee_wallet_) internal {
        require(system_wallet_ != address(0), "invalid system_wallet_");
        system_wallet = system_wallet_;
        require(fee_wallet_ != address(0), "invalid system_wallet_");
        fee_wallet = fee_wallet_;
    }

    function setWallet(address system_wallet_, address fee_wallet_) external onlyOwner {
        _setWallet(system_wallet_, fee_wallet_);
    }

    function topup(uint256 amount) external payable nonReentrant {
        if (token == address(0)) {
            require(amount == msg.value, "invalid msg.value");
        } else {
            require(0 == msg.value, "invalid msg.value");
            SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);
        }
        _topup(msg.sender, amount);
    }

    function batchTopup(
        address[] calldata users,
        uint256[] calldata amounts
    ) external payable nonReentrant onlyAdmin {
        uint256 _total;
        require(users.length == amounts.length);

        for (uint i = 0; i < users.length; i++) {
            _topup(users[i], amounts[i]);
            _total += amounts[i];
        }

        if (token == address(0)) {
            require(_total == msg.value, "invalid msg.value");
        } else {
            require(0 == msg.value, "invalid msg.value");
            SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), _total);
        }
    }

    function _topup(address to, uint256 amount) internal {
        require(to.code.length == 0, "topup to EOA only");
        _topup_block[to] = block.number;
        _addBullet(to, amount);
        emit Topup(to, amount);
    }

    function _beforeWithdraw() internal virtual {}

    function preWithdraw(uint256 amount) external whenBulletNotPaused {
        require(withdraw_form[msg.sender].amount == 0, "withdraw pls");
        _beforeWithdraw();
        _reduceBullet(msg.sender, amount);
        withdraw_form[msg.sender].amount = amount;
        withdraw_form[msg.sender].time = block.timestamp;
        emit PreWithdraw(msg.sender, amount, block.timestamp);
    }

    function withdrawTimeOf(address user) public view returns (uint256) {
        if (isBulletPausing) return type(uint256).max;
        return withdraw_form[user].time + withdraw_cd;
    }

    function withdraw() external nonReentrant whenBulletNotPaused {
        require(withdraw_form[msg.sender].amount > 0, "preWithdraw need");
        require(withdrawTimeOf(msg.sender) <= block.timestamp);
        uint256 amount = withdraw_form[msg.sender].amount;

        uint256 _fee = (amount * fee) / Constant.E4;
        uint256 _amount = amount - _fee;
        if (token == address(0)) {
            Address.sendValue(payable(msg.sender), _amount);
            Address.sendValue(payable(fee_wallet), _fee);
        } else {
            SafeERC20.safeTransfer(IERC20(token), msg.sender, _amount);
            SafeERC20.safeTransfer(IERC20(token), fee_wallet, _fee);
        }
        withdraw_form[msg.sender].amount = 0;
        withdraw_form[msg.sender].time = 0;
        emit Withdraw(msg.sender, amount, block.timestamp);
        emit ChargeFee(msg.sender, _fee);
    }

    function setFee(uint256 fee_) external onlyOwner {
        require(fee_ <= Constant.E3);
        fee = fee_;
        emit FeeUpdated(fee);
    }

    function setWithdrawCD(uint256 cd_) external onlyOwner {
        withdraw_cd = cd_;
        emit WithdrawCDUpdated(withdraw_cd);
    }

    function _addBullet(address user, uint256 amount) internal {
        _bullet_balance[user] += amount;
    }

    function _reduceBullet(address user, uint256 amount) internal {
        require(_topup_block[user] < block.number, "Error: same block");
        require(_bullet_balance[user] >= amount, "insufficient bullet_amount");
        _bullet_balance[user] -= amount;
    }

    function bulletOf(address user) public view returns (uint256) {
        return _bullet_balance[user];
    }

    function topupToSystem(uint256 amount) external payable nonReentrant {
        if (token == address(0)) {
            require(amount == msg.value, "invalid amount");
        } else {
            require(0 == msg.value, "Error");
            SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);
        }
        _addSystemBullet(amount);
        emit TopupToSystem(msg.sender, amount);
    }

    function withdrawFromSystem(uint256 amount) external nonReentrant onlyAdmin {
        require(amount + _frozen_bullet <= _system_bullet, "insufficient system_bullet");
        _reduceSystemBullet(amount);
        if (token == address(0)) {
            Address.sendValue(payable(system_wallet), amount);
        } else {
            SafeERC20.safeTransfer(IERC20(token), system_wallet, amount);
        }
        emit WithdrawFromSystem(msg.sender, amount);
    }

    function _addSystemBullet(uint256 amount) internal {
        _system_bullet += amount;
    }

    function _reduceSystemBullet(uint256 amount) internal {
        require(_system_bullet >= amount);
        _system_bullet -= amount;
    }

    function systemBullet() public view onlyAdmin returns (uint256) {
        return _system_bullet;
    }

    function _addFrozenBullet(uint256 amount) internal {
        _frozen_bullet += amount;
    }

    function _reduceFrozenBullet(uint256 amount) internal {
        require(_frozen_bullet >= amount);
        _frozen_bullet -= amount;
    }

    function frozenBullet() public view returns (uint256) {
        return _frozen_bullet;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

contract OwnableUpgradeable {
    address public owner;
    address public pendingOwner;
    address public mgr;

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewOwner(address oldOwner, address newOwner);
    event NewPendingOwner(address oldPendingOwner, address newPendingOwner);

    function _initOwnable(address owner_, address admin_) internal {
        require(owner_ != address(0), "owner_ cannot be Zero Address");
        owner = owner_;
        mgr = admin_;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "onlyOwner");
        _;
    }

    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "onlyPendingOwner");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == mgr || msg.sender == owner, "onlyAdmin");
        _;
    }

    function transferOwnership(address _pendingOwner) public onlyOwner {
        emit NewPendingOwner(pendingOwner, _pendingOwner);
        pendingOwner = _pendingOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit NewOwner(owner, address(0));
        emit NewAdmin(mgr, address(0));
        emit NewPendingOwner(pendingOwner, address(0));

        owner = address(0);
        pendingOwner = address(0);
        mgr = address(0);
    }

    function acceptOwner() public onlyPendingOwner {
        emit NewOwner(owner, pendingOwner);
        owner = pendingOwner;

        address newPendingOwner = address(0);
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }

    function setAdmin(address newAdmin) public onlyOwner {
        emit NewAdmin(mgr, newAdmin);
        mgr = newAdmin;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
import "./OwnableUpgradeable.sol";

abstract contract BulletPauseable is OwnableUpgradeable {
    event BulletPaused(address account);
    event BulletUnpaused(address account);
    bool public isBulletPausing;

    modifier whenBulletNotPaused() {
        require(!isBulletPausing, "Pausable: paused");
        _;
    }

    function setBulletPause(bool pause_) external onlyAdmin {
        require(isBulletPausing != pause_);
        isBulletPausing = pause_;
        if (isBulletPausing) {
            emit BulletPaused(address(this));
        } else {
            emit BulletUnpaused(address(this));
        }
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

library Constant {
    uint256 constant E4 = 10000;
    uint256 constant E3 = 1000;
    uint256 constant PRIZE_BLACK_TIME = 1800;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}