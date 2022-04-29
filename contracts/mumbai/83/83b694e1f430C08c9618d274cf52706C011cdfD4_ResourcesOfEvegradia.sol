// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../ISlayer.sol";

contract ResourcesOfEvegradia {
    ISlayer private immutable _slayer;

    address private immutable _gameMaster;

    mapping(address => bool) private _isGame;
    mapping(uint => mapping(uint => uint)) private _balances; // token id to resource id to balance

    constructor(address slayer_) {
        _slayer = ISlayer(slayer_);
        _gameMaster = msg.sender;
    }

    modifier onlyGame {
        require(_isGame[msg.sender] == true);
        _;
    }

    modifier onlyMaster() {
        require(_gameMaster == msg.sender);
        _;
    }

    // GAME FUNCTIONS

    function mint(uint _to, uint _rid, uint _amount) external onlyGame {
        require(_to > 0 && _to <= 10000);
        _balances[_to][_rid] += _amount;
    }

    function burn(uint _from, uint _rid, uint _amount) external onlyGame {
        require(_from > 0 && _from <= 10000);
        require(_balances[_from][_rid] >= _amount);
        _balances[_from][_rid] -= _amount;
    }

    function transfer(uint _from, uint _to, uint _rid, uint _amount) external {
        require(msg.sender == _slayer.getOperator(_from));
        require(_to <= 10000);
        require(_balances[_from][_rid] >= _amount);
        _balances[_from][_rid] -= _amount;
        _balances[_to][_rid] += _amount;
    }

    function addGame(address _game) external onlyMaster {
        _isGame[_game] = true;
    }

    // GETTERS

    function getBalance(uint _id, uint _rid) external view returns (uint) {
        return _balances[_id][_rid];
    }

    function getBalanceBatch(uint _id) external view returns(uint[] memory) {
        uint[] memory _batchBalance = new uint[](23);
        for (uint256 i = 0; i < 22; ++i) {
            _batchBalance[i] = _balances[_id][i];
        }
        return _batchBalance;
    }

    // MASTER FUNCTIONS

    function addGameAddress(address _game) external onlyMaster {
        require(_gameMaster == msg.sender);
        _isGame[_game] = true;
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