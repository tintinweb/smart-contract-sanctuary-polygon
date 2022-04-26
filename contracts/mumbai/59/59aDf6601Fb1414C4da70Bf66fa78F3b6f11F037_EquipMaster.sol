// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../ISlayer.sol";
import "../Equipment/IRings.sol";
import "../Equipment/IWeapons.sol";

contract EquipMaster {
    ISlayer private immutable _slayer;
    IRings private immutable _ring;
    IWeapons private immutable _weapon;
    address immutable _gameMaster;
    mapping(address => bool) private _isGame;

    constructor(address slayer_, address ring_, address weapon_) {
        _slayer = ISlayer(slayer_);
        _ring = IRings(ring_);
        _weapon = IWeapons(weapon_);
        _gameMaster = msg.sender;
    }

    modifier onlyMaster {
        require(_gameMaster == msg.sender);
        _;
    }

    modifier onlyGame {
        require(_isGame[msg.sender] == true);
        _;
    }

    function getFinalStats(uint _id) external view returns (uint64, uint64, uint64) {
        (, uint64 intel, uint64 str, uint64 agi) = _slayer.getTokenStats(_id);
        (uint64 intelw, uint64 strw, uint64 agiw) = _weapon.getEquipStats(_id);
        (uint64 intelr, uint64 strr, uint64 agir) = _ring.getEquipStats(_id);
        return(intel + intelr + intelw, str + strr + strw, agi + agir + agiw);
    }

    function mintWeapon(uint _id, uint _rid) external onlyGame {
        _weapon.mintWeapon(_id, _rid);
    }

    function mintRing(uint _id, uint _rid) external onlyGame {
        _ring.mintRing(_id, _rid);
    }
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

interface IWeapons {
    function mintWeapon(uint _to, uint _rid) external;
    function burnWeapon(uint _from, uint _rid) external;
    function getEquipStats(uint _id) external view returns (uint64,uint64,uint64);
    function getEquip(uint _id) external view returns (uint);
    function getBalance(uint _id, uint _rid) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IRings {
    function mintRing(uint _to, uint _rid) external;
    function burnRing(uint _from, uint _rid) external;
    function getEquipStats(uint _id) external view returns (uint64,uint64,uint64);
    function getEquip(uint _id) external view returns (uint);
    function getBalance(uint _id, uint _rid) external view returns (uint);
}