/**
 *Submitted for verification at polygonscan.com on 2022-12-03
*/

//SPDX-License-Identifier: MIT License
pragma solidity ^0.8.0;

contract AccessControl {
    address payable public creatorAddress;

    modifier onlyCREATOR() {
        require(msg.sender == creatorAddress, 'You are not the creator');
        _;
    }

    // Constructor
    constructor() {
        creatorAddress = payable(msg.sender);
    }


    function changeOwner(address payable _newOwner) public onlyCREATOR {
        creatorAddress = _newOwner;
    }
}

abstract contract IBattleMtnData {
    function creatorAddress() public virtual returns (address);
}

abstract contract IVSBattle {
    function creatorAddress() public virtual returns (address);
}

contract CustomBattleMtn is AccessControl {
    struct BattleMtn {
        bool active;
        uint256 id;
        string title;
        string description;
        address battleMtnAddress;
        address vsBattleAddress;
        address owner;
    }

    // Next battle mountain id (0 is used to reference an invalid mtn)
    uint256 public battleMtnIdx = 1;
    // All battle mountains
    BattleMtn[] public battleMtns;
    // Count of battle mountains owned by player
    mapping(address => uint256) public playerMtnCount;
    // Player battle mountain ids
    mapping(address => uint256[]) public playerMountainIds;

    constructor() {
        // First battleMtn is used to reference an invalid mtn
        BattleMtn memory battleMtn;
        battleMtns.push(battleMtn);
    }

    // Initialize the custom mountain
    // @param string _title mountain title
    // @param string _description mountain description
    // @param address _battleMtnAddress BattleMtnData address
    // @param address _vsBattleAddress VsBattle address
    function initMountain(
        string memory _title,
        string memory _description,
        address _battleMtnAddress,
        address _vsBattleAddress
    ) external {
        IBattleMtnData battleMtnDataContract = IBattleMtnData(_battleMtnAddress);
        require(
            battleMtnDataContract.creatorAddress() == msg.sender,
            'Not owner of Battle Mountain contract'
        );

        IVSBattle vsBattleContract = IVSBattle(_vsBattleAddress);
        require(
            vsBattleContract.creatorAddress() == msg.sender,
            'Not owner of VS Battle contract'
        );

        // Save custom BattleMtnData information
        BattleMtn memory customBattleMtn = BattleMtn({
            id               : battleMtnIdx,
            active           : true,
            title            : _title,
            description      : _description,
            battleMtnAddress : _battleMtnAddress,
            vsBattleAddress  : _vsBattleAddress,
            owner            : msg.sender
        });
        battleMtns.push(customBattleMtn);
        playerMountainIds[msg.sender].push(battleMtnIdx);
        playerMtnCount[msg.sender]++;


        // Increment battle mountain id
        battleMtnIdx++;
    }

    function updateInfo (
        uint256 _battleMtnId,
        string memory _title,
        string memory _description) public {
        BattleMtn storage battleMtn = battleMtns[_battleMtnId];
        require(battleMtns[_battleMtnId].owner == msg.sender, "Owner required for updates.");

        battleMtn.title = _title;
        battleMtn.description = _description;
    }

    // Number of custom mountains
    // @return uint length of battleMtns array
    function getCount() public view returns (uint) {
        return battleMtns.length;
    }

    function setActive(uint256 _battleMtnId, bool _active) public onlyCREATOR {
        BattleMtn storage battleMtn = battleMtns[_battleMtnId];
        battleMtn.active = _active;
    }
}