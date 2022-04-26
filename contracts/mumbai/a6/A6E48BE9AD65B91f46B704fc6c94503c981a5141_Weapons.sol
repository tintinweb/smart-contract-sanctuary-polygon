// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../ISlayer.sol";

contract Weapons {
    ISlayer private immutable _slayer;
    address private immutable _gameMaster;

    uint private _weaponCounter;

    struct WeaponStats {
        uint64 intellect;
        uint64 strength;
        uint64 agility;
    }

    mapping(uint => WeaponStats) private _weapon;
    mapping(uint => mapping(uint => uint)) private _weaponBalances;
    mapping(uint => uint) private _equiped;
    mapping(address => bool) private _isGame;

    constructor(address slayer_) {
        _gameMaster = msg.sender;
        _slayer = ISlayer(slayer_);
    }

    modifier onlyMaster() {
        require(_gameMaster == msg.sender);
        _;
    }

    modifier onlyGame {
        require(_isGame[msg.sender] == true);
        _;
    }

    modifier onlyOperator(uint _id) {
        require(msg.sender == _slayer.getOperator(_id));
        _;
    }

    function mintWeapon(uint _to, uint _rid) external onlyGame {
        _weaponBalances[_to][_rid]++;
    }

    function burnWeapon(uint _from, uint _rid) external onlyGame {
        require(_weaponBalances[_from][_rid] > 0);
        _weaponBalances[_from][_rid]--;
    }

    function transfer(uint _from, uint _to, uint _rid) external onlyOperator(_from) {
        require(_to <= 10000);
        require(_weaponBalances[_from][_rid] > 0);
        _weaponBalances[_from][_rid]--;
        _weaponBalances[_to][_rid]++;
    }

    function equipWeapon(uint _id, uint _rid) external onlyOperator(_id) {
        require(getBalance(_id, _rid) > 0);
        _equiped[_id] = _rid;
        _weaponBalances[_id][_rid]--;
    }

    function initMoreWeapons(uint64 _o, uint64 _tw, uint64 _tr) external onlyMaster {
        _initMoreWeapon(_o, _tw, _tr);
    }

    function initWeapon(uint64 _o, uint64 _tw, uint64 _tr) external onlyMaster {
        _initMoreWeapon(_o, _tw, _tr);
    }

    // GETTERS

    function getBalance(uint _id, uint _rid) public view returns (uint) {
        return _weaponBalances[_id][_rid];
    }

    function getBalanceBatch(uint _id) external view returns(uint[] memory) {
        uint[] memory _batchBalance = new uint[](101);
        for (uint256 i = 0; i < 100; ++i) {
            _batchBalance[i] = _weaponBalances[_id][i];
        }
        return _batchBalance;
    }

    function getWeaponStats(uint _rid) public view returns (uint64, uint64, uint64) {
        WeaponStats memory weapon = _weapon[_rid];
        return (weapon.intellect, weapon.strength, weapon.agility);
    }

    function getEquip(uint _id) public view returns (uint) {
        return _equiped[_id];
    }

    function getEquipStats(uint _id) external view returns (uint64,uint64,uint64) {
        uint ringOnUser = _equiped[_id];
        (uint64 intel, uint64 str, uint64 agi) = getWeaponStats(ringOnUser);
        return (intel, str, agi);
    }

    // PRIVATE 
    function _initMoreWeapon(uint64 _one, uint64 _two, uint64 _tr) private {
        _initWeapon(_one, _two, _tr);
        _initWeapon(_tr, _one, _two);
        _initWeapon(_two, _tr, _one);
    }

    function _initWeapon(uint64 _intel, uint64 _str, uint64 _agi) private {
        WeaponStats storage weapon = _weapon[_weaponCounter];
        weapon.intellect = _intel;
        weapon.strength = _str;
        weapon.agility = _agi;
        _weaponCounter++;
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