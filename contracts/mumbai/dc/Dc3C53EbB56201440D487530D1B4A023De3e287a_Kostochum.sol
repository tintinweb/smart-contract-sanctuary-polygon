// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../ISlayer.sol";
import "../Equipment/IEquip.sol";
import "../Resources/IResources.sol";

contract Kostochum {
    ISlayer private immutable _slayer;
    IEquip private immutable _equip;
    IResources private immutable _resWB;

    address private immutable _gameMaster;
    uint private _lastKill;
    int private _bossHealthPoints;

    enum BossStatus {
        live,
        dead
    }

    BossStatus public WBStatus;

    mapping(uint => uint) private _slayerDamage;
    mapping(uint => mapping(uint => bool)) private _collectReward;

    constructor(address slayer_, address equip_, address res_) {
        _slayer = ISlayer(slayer_);
        _equip = IEquip(equip_);
        _resWB = IResources(res_);
        _gameMaster = msg.sender;
    }

    modifier onlyOperator(uint _id) {
        require(msg.sender == _slayer.getOperator(_id));
        _;
    }

    function attack(uint _id, uint8 _type) external onlyOperator(_id) returns (uint) {
        require(_type > 3);
        require(_getReadyStatus() == true);
        if (WBStatus == BossStatus.dead) {
            _initBoss();
        }
        if (_type == 0) {
            uint dmg = _magicSkill(_id);
            _bossHealthPoints - int(dmg);
            _slayerDamage[_id] += dmg;
            if (_bossHealthPoints < 0) {
                _lastKill = block.timestamp;
                _setDead();
            }
            return dmg;
        }
        if (_type == 1) {
            uint dmg = _strSkill(_id);
            _bossHealthPoints - int(dmg);
            _slayerDamage[_id] += dmg;
            if (_bossHealthPoints < 0) {
                _lastKill = block.timestamp;
                _setDead();
            }
            return dmg;
        }
        if (_type == 2) {
            uint dmg = _agiSkill(_id);
            _bossHealthPoints - int(dmg);
            _slayerDamage[_id] += dmg;
            if (_bossHealthPoints < 0) {
                _lastKill = block.timestamp;
                _setDead();
            }
            return dmg;
        }
        return 0;
    }

    function collectReward(uint _id) external onlyOperator(_id) {
        require(WBStatus == BossStatus.dead);
        require(_slayerDamage[_id] > 0);
        uint shardofdestr;
        uint bone;
        if (_slayerDamage[_id] > 2) {
            shardofdestr++;
        }
        if (_slayerDamage[_id] > 6) {
            shardofdestr++;
            if (_collectReward[_id][0] == false) {
                _equip.mintRing(_id, 0);
                _collectReward[_id][0] = true;
            }
        }
        if (_slayerDamage[_id] > 10) {
            shardofdestr++;
            if (_collectReward[_id][1] == false) {
                _equip.mintWeapon(_id, 0);
                _collectReward[_id][1] = true;
            }
        }
        if (_slayerDamage[_id] > 25 && _getlvl(_id) < 25) {
            _slayer.lvlUp(_id);
        }
        if (_slayerDamage[_id] > 50) {
            bone++;
        }
        _resWB.mint(_id, 0, shardofdestr);
        _resWB.mint(_id, 1, bone);
        _slayerDamage[_id] = 0;
    }

    // GETTERS

    function getReadyStatus() external view returns (bool) {
        return _getReadyStatus();
    }

    // PRIVATE

    function _getReadyStatus() private view returns (bool) {
        if (WBStatus == BossStatus.dead) {
            if (block.timestamp > _lastKill + 12 hours) {
                return true;
            } else {
                return false;
            }
        }
        else {
            return true;
        }
    }

    function _setDead() private {
        WBStatus = BossStatus.dead;
    }

    function _initBoss() private {
        WBStatus = BossStatus.live;
        _bossHealthPoints = 10;
    }

    function _getBossStatus() private view returns (BossStatus) {
        return WBStatus;
    }

    function _getStats(uint _id) private view returns (uint64,uint64,uint64) {
        (,uint64 intel, uint64 str, uint64 agi) = _equip.getFinalStats(_id);
        return (intel, str, agi);
    }

    function _getlvl(uint _id) private view returns (uint8) {
        (uint8 lvl,,,) = _equip.getFinalStats(_id);
        return lvl;
    }

    function _magicSkill(uint _id) private view returns (uint) {
        (uint64 intel,,) = _getStats(_id);
        return uint(intel + 2);
    }

    function _strSkill(uint _id) private view returns (uint) {
        (,uint64 str,) = _getStats(_id);
        return uint(str + 2);
    }

    function _agiSkill(uint _id) private view returns (uint) {
        (,,uint64 agi) = _getStats(_id);
        return uint(agi + 2);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IResources {
    function mint(uint _to, uint _rid, uint _amount) external;
    function burn(uint _from, uint _rid, uint _amount) external;
    function getBalance(uint _id, uint _rid) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ISlayer {
    function onGrind(uint _id) external;
    function offGrind(uint _id) external;
    function lvlUp(uint _id) external;
    function getTokenStats(uint _id) external view returns(uint8 _lvl, uint64 _intellect, uint64 _strenght, uint64 _agility);
    function getOperator(uint _id) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IEquip {
    function getFinalStats(uint _id) external view returns (uint8, uint64, uint64, uint64);
    function mintWeapon(uint _id, uint _rid) external;
    function mintRing(uint _id, uint _rid) external;
}