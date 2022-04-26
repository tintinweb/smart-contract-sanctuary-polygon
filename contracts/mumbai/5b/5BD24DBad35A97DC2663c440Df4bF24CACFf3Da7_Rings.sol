// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../ISlayer.sol";

contract Rings {
    ISlayer private immutable _slayer;
    address private immutable _gameMaster;

    uint private _ringCounter;

    struct RingStats {
        uint64 intellect;
        uint64 strength;
        uint64 agility;
    }

    mapping(uint => RingStats) private _ring;
    mapping(uint => mapping(uint => uint)) private _ringBalances;
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

    function mintRing(uint _to, uint _rid) external onlyGame {
        _ringBalances[_to][_rid]++;
    }

    function burnRing(uint _from, uint _rid) external onlyGame {
        require(_ringBalances[_from][_rid] > 0);
        _ringBalances[_from][_rid]--;
    }

    function transfer(uint _from, uint _to, uint _rid) external onlyOperator(_from) {
        require(_to <= 10000);
        require(_ringBalances[_from][_rid] > 0);
        _ringBalances[_from][_rid]--;
        _ringBalances[_to][_rid]++;
    }

    function equipRing(uint _id, uint _rid) external onlyOperator(_id) {
        require(getBalance(_id, _rid) > 0);
        _equiped[_id] = _rid;
        _ringBalances[_id][_rid]--;
    }

    function addGame(address _game) external onlyMaster {
        _isGame[_game] = true;
    }

    function initMoreRings(uint64 _o, uint64 _tw, uint64 _tr) external onlyMaster {
        _initMoreRings(_o, _tw, _tr);
    }

    function initRing(uint64 _o, uint64 _tw, uint64 _tr) external onlyMaster {
        _initRing(_o, _tw, _tr);
    }

    // GETTERS

    function getBalance(uint _id, uint _rid) public view returns (uint) {
        return _ringBalances[_id][_rid];
    }

    function getBalanceBatch(uint _id) external view returns(uint[] memory) {
        uint[] memory _batchBalance = new uint[](101);
        for (uint256 i = 0; i < 100; ++i) {
            _batchBalance[i] = _ringBalances[_id][i];
        }
        return _batchBalance;
    }

    function getRingStats(uint _rid) public view returns (uint64, uint64, uint64) {
        RingStats memory ring = _ring[_rid];
        return (ring.intellect, ring.strength, ring.agility);
    }

    function getEquip(uint _id) public view returns (uint) {
        return _equiped[_id];
    }

    function getEquipStats(uint _id) external view returns (uint64,uint64,uint64) {
        uint ringOnUser = _equiped[_id];
        (uint64 intel, uint64 str, uint64 agi) = getRingStats(ringOnUser);
        return (intel, str, agi);
    }

    // PRIVATE
    function _initMoreRings(uint64 _one, uint64 _two, uint64 _tr) private {
        _initRing(_one, _two, _tr);
        _initRing(_tr, _one, _two);
        _initRing(_two, _tr, _one);
    }

    function _initRing(uint64 _intel, uint64 _str, uint64 _agi) private {
        RingStats storage ring = _ring[_ringCounter];
        ring.intellect = _intel;
        ring.strength = _str;
        ring.agility = _agi;
        _ringCounter++;
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