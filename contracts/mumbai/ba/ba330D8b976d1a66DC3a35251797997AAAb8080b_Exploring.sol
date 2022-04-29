// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../Game/ISlayer.sol";
import "../Game/Resources/IResources.sol";

contract Exploring {
    ISlayer private immutable _slayer;
    IResources private immutable _resourcesOfEve;

    mapping(uint => bool) private _isOnGrind;
    mapping(uint => uint8) private _zone;
    mapping(uint => uint) private _timeStamp;
    
    constructor(address slayer_, address resources_) {
        _slayer = ISlayer(slayer_);
        _resourcesOfEve = IResources(resources_);
    }

    modifier onlyOperator(uint _id) {
        address _operator = _slayer.getOperator(_id);
        require(_operator == msg.sender);
        _;
    }

    function startHallOfShadow(uint _id) external onlyOperator(_id) {
        require(_isOnGrind[_id] == false);
        _zone[_id] = 1;
        _timeStamp[_id] = block.timestamp;
        _isOnGrind[_id] = true;
        _slayer.onGrind(_id);
    }

    function startGrindLastForest(uint _id) external onlyOperator(_id) {
        (uint8 lvl,,,uint64 agi) = _slayer.getTokenStats(_id);
        require(lvl >= 80 && agi >= 155 && _isOnGrind[_id] == false);
        _isOnGrind[_id] = true;
        _zone[_id] = 2;
        _timeStamp[_id] = block.timestamp;
        _slayer.onGrind(_id);
    }

    function startGrindLastCave(uint _id) external onlyOperator(_id) {
        (uint8 lvl,,uint64 str,) = _slayer.getTokenStats(_id);
        require(lvl >= 80 && str >= 155 && _isOnGrind[_id] == false);
        _isOnGrind[_id] = true;
        _zone[_id] = 3;
        _timeStamp[_id] = block.timestamp;
        _slayer.onGrind(_id);
    }

    function startGrindLastPalaces(uint _id) external onlyOperator(_id) {
        (uint8 lvl,uint64 intel,,) = _slayer.getTokenStats(_id);
        require(lvl >= 80 && intel >= 155 && _isOnGrind[_id] == false);
        _isOnGrind[_id] = true;
        _zone[_id] = 4;
        _timeStamp[_id] = block.timestamp;
        _slayer.onGrind(_id);
    }

    // hall of shadow

    function backFromHallOfShadow(uint _id) external onlyOperator(_id) {
        require(_zone[_id] == 1);
        require(_isOnGrind[_id] = true);
        (uint8 lvl, uint64 intel, uint64 str, uint64 agi) = _slayer.getTokenStats(_id);

        uint current = block.timestamp;
        uint shadowStone;
        uint twi;
        uint harmonyTear;
        uint saranit;
        uint smertocvet;

        if (current >= _timeStamp[_id] + 1 hours) {
            shadowStone++;
            if (lvl <= 10) {
                _slayer.lvlUp(_id);
            }
        }
        if (current >= _timeStamp[_id] + 2 hours) {
            shadowStone++;
            if (lvl < 25 && lvl > 10) {
                _slayer.lvlUp(_id);
            }
        }
        if (current >= _timeStamp[_id] + 6 hours) {
            twi++;
            if (lvl < 40 && lvl >= 25) {
                _slayer.lvlUp(_id);
            }
            if (intel > 50) {
                harmonyTear++;
            }
            if (str > 50) {
                saranit++;
            }
            if (agi > 50) {
                smertocvet++;
            }
        }
        _resourcesOfEve.mint(_id, 0, shadowStone);
        _resourcesOfEve.mint(_id, 1, twi);
        _resourcesOfEve.mint(_id, 2, harmonyTear);
        _resourcesOfEve.mint(_id, 3, saranit);
        _resourcesOfEve.mint(_id, 4, smertocvet);
        _zone[_id] == 0;
        _isOnGrind[_id] = false;
        _slayer.offGrind(_id);
    }

    // north forest

    function backFromNorthForest(uint _id) external onlyOperator(_id) {
        require(_zone[_id] == 2);
        require(_isOnGrind[_id] = true);
        (,,, uint64 agi) = _slayer.getTokenStats(_id);

        uint current = block.timestamp;
        uint deadleaf;
        uint frostflower;
        uint manaleaf;
        uint frostclover;
        uint northlotos;

        if (current >= _timeStamp[_id] + 1 hours) {
            deadleaf++;
        }
        if (current >= _timeStamp[_id] + 2 hours) {
            frostflower++;
        }
        if (current >= _timeStamp[_id] + 12 hours) {
            manaleaf++;
            if (agi >= 165) {
                frostclover++;
            }
            if (agi >= 170) {
                northlotos++;
            }
        }

        _resourcesOfEve.mint(_id, 5, deadleaf);
        _resourcesOfEve.mint(_id, 6, frostflower);
        _resourcesOfEve.mint(_id, 7, manaleaf);
        _resourcesOfEve.mint(_id, 8, frostclover);
        _resourcesOfEve.mint(_id, 9, northlotos);
        _zone[_id] == 0;
        _isOnGrind[_id] = false;
        _slayer.offGrind(_id);
    }

    // cave of silence

    function backFromCaveOfSilence(uint _id) external onlyOperator(_id) {
        require(_zone[_id] == 3);
        require(_isOnGrind[_id] = true);
        (,,uint64 str,) = _slayer.getTokenStats(_id);

        uint current = block.timestamp;
        uint adamantit;
        uint ethern;
        uint elemnty;
        uint obsidian;
        uint mithril;

        if (current >= _timeStamp[_id] + 1 hours) {
            adamantit++;
        }
        if (current >= _timeStamp[_id] + 2 hours) {
            ethern++;
        }
        if (current >= _timeStamp[_id] + 12 hours) {
            elemnty++;
            if (str >= 165) {
                obsidian++;
            }
            if (str >= 170) {
                mithril++;
            }
        }

        _resourcesOfEve.mint(_id, 10, adamantit);
        _resourcesOfEve.mint(_id, 11, ethern);
        _resourcesOfEve.mint(_id, 12, elemnty);
        _resourcesOfEve.mint(_id, 13, obsidian);
        _resourcesOfEve.mint(_id, 14, mithril);
        _zone[_id] == 0;
        _isOnGrind[_id] = false;
        _slayer.offGrind(_id);
    }

    // the Backcrystal

    function backFromTheBackcrystal(uint _id) external onlyOperator(_id) {
        require(_zone[_id] == 4);
        require(_isOnGrind[_id] = true);
        (,uint intel,,) = _slayer.getTokenStats(_id);

        uint current = block.timestamp;
        uint maelstrom;
        uint crystalOfTime;
        uint shadowshard;
        uint arkhanit;
        uint shardOfAstral;

        if (current >= _timeStamp[_id] + 1 hours) {
            maelstrom++;
        }
        if (current >= _timeStamp[_id] + 2 hours) {
            crystalOfTime++;
        }
        if (current >= _timeStamp[_id] + 12 hours) {
            shadowshard++;
            if (intel >= 165) {
                arkhanit++;
            }
            if (intel >= 170) {
                shardOfAstral++;
            }
        }

        _resourcesOfEve.mint(_id, 15, maelstrom);
        _resourcesOfEve.mint(_id, 16, crystalOfTime);
        _resourcesOfEve.mint(_id, 17, shadowshard);
        _resourcesOfEve.mint(_id, 18, arkhanit);
        _resourcesOfEve.mint(_id, 19, shardOfAstral);
        _zone[_id] == 0;
        _isOnGrind[_id] = false;
        _slayer.offGrind(_id);
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