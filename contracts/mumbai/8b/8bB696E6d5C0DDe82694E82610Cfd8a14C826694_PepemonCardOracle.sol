// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Roles.sol";

contract AdminRole {
  using Roles for Roles.Role;

  event AdminAdded(address indexed account);
  event AdminRemoved(address indexed account);

  Roles.Role private admins;

  constructor() {
    _addAdmin(msg.sender);
  }

  modifier onlyAdmin() {
    require(isAdmin(msg.sender));
    _;
  }

  function isAdmin(address account) public view returns (bool) {
    return admins.has(account);
  }

  function addAdmin(address account) public onlyAdmin {
    _addAdmin(account);
  }

  function renounceAdmin() public {
    _removeAdmin(msg.sender);
  }

  function _addAdmin(address account) internal {
    admins.add(account);
    emit AdminAdded(account);
  }

  function _removeAdmin(address account) internal {
    admins.remove(account);
    emit AdminRemoved(account);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;


/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./lib/AdminRole.sol";

/**
This contract acts as the oracle, it contains battling information for both the Pepemon Battle and Support cards
**/
contract PepemonCardOracle is AdminRole {
    enum BattleCardType {
        FIRE,
        GRASS,
        WATER,
        LIGHTNING,
        WIND,
        POISON,
        GHOST,
        FAIRY,
        EARTH,
        UNKNOWN,
        NONE
    }

    enum SupportCardType {
        OFFENSE,
        STRONG_OFFENSE,
        DEFENSE,
        STRONG_DEFENSE
    }

    enum EffectTo {
        ATTACK,
        STRONG_ATTACK,
        DEFENSE,
        STRONG_DEFENSE,
        SPEED,
        INTELLIGENCE
    }

    enum EffectFor {
        ME,
        ENEMY
    }

    struct BattleCardStats {
        uint256 battleCardId;
        BattleCardType battleCardType;
        string name;
        uint256 hp; // hitpoints
        uint256 spd; // speed
        uint256 inte; // intelligence
        uint256 def; // defense
        uint256 atk; // attack
        uint256 sAtk; // special attack
        uint256 sDef; // special defense
    }

    struct SupportCardStats {
        uint256 supportCardId;
        SupportCardType supportCardType;
        string name;
        EffectOne[] effectOnes;
        EffectMany effectMany;
        // If true, duplicate copies of the card in the same turn will have no extra effect.
        bool unstackable;
        // This property is for EffectMany now.
        // If true, assume the card is already in effect
        // then the same card drawn and used within a number of turns does not extend or reset duration of the effect.
        bool unresettable;
    }

    struct EffectOne {
        // If power is 0, it is equal to the total of all normal offense/defense cards in the current turn.
        
        //basePower = power if req not met
        int256 basePower;

        //triggeredPower = power if req met
        int256 triggeredPower;
        EffectTo effectTo;
        EffectFor effectFor;
        uint256 reqCode; //requirement code
    }

    struct EffectMany {
        int256 power;
        uint256 numTurns;
        EffectTo effectTo;
        EffectFor effectFor;
        uint256 reqCode; //requirement code
    }

    mapping(uint256 => BattleCardStats) public battleCardStats;
    mapping(uint256 => SupportCardStats) public supportCardStats;

    event BattleCardCreated(address sender, uint256 cardId);
    event BattleCardUpdated(address sender, uint256 cardId);
    event SupportCardCreated(address sender, uint256 cardId);
    event SupportCardUpdated(address sender, uint256 cardId);

    function addBattleCard(BattleCardStats memory cardData) public onlyAdmin {
        require(battleCardStats[cardData.battleCardId].battleCardId == 0, "PepemonCard: BattleCard already exists");

        BattleCardStats storage _card = battleCardStats[cardData.battleCardId];
        _card.battleCardId = cardData.battleCardId;
        _card.battleCardType = cardData.battleCardType;
        _card.name = cardData.name;
        _card.hp = cardData.hp;
        _card.spd = cardData.spd;
        _card.inte = cardData.inte;
        _card.def = cardData.def;
        _card.atk = cardData.atk;
        _card.sDef = cardData.sDef;
        _card.sAtk = cardData.sAtk;

        emit BattleCardCreated(msg.sender, cardData.battleCardId);
    }

    function updateBattleCard(BattleCardStats memory cardData) public onlyAdmin {
        require(battleCardStats[cardData.battleCardId].battleCardId != 0, "PepemonCard: BattleCard not found");

        BattleCardStats storage _card = battleCardStats[cardData.battleCardId];
        _card.hp = cardData.hp;
        _card.battleCardType = cardData.battleCardType;
        _card.name = cardData.name;
        _card.spd = cardData.spd;
        _card.inte = cardData.inte;
        _card.def = cardData.def;
        _card.atk = cardData.atk;
        _card.sDef = cardData.sDef;
        _card.sAtk = cardData.sAtk;

        emit BattleCardUpdated(msg.sender, cardData.battleCardId);
    }

    function getBattleCardById(uint256 _id) public view returns (BattleCardStats memory) {
        require(battleCardStats[_id].battleCardId != 0, "PepemonCard: BattleCard not found");
        return battleCardStats[_id];
    }

    function addSupportCard(SupportCardStats memory cardData) public onlyAdmin {
        require(supportCardStats[cardData.supportCardId].supportCardId == 0, "PepemonCard: SupportCard already exists");

        SupportCardStats storage _card = supportCardStats[cardData.supportCardId];
        _card.supportCardId = cardData.supportCardId;
        _card.supportCardType = cardData.supportCardType;
        _card.name = cardData.name;
        for (uint256 i = 0; i < cardData.effectOnes.length; i++) {
            _card.effectOnes.push(cardData.effectOnes[i]);
        }
        _card.effectMany = cardData.effectMany;
        _card.unstackable = cardData.unstackable;
        _card.unresettable = cardData.unresettable;

        emit SupportCardCreated(msg.sender, cardData.supportCardId);
    }

    function updateSupportCard(SupportCardStats memory cardData) public onlyAdmin {
        require(supportCardStats[cardData.supportCardId].supportCardId != 0, "PepemonCard: SupportCard not found");

        SupportCardStats storage _card = supportCardStats[cardData.supportCardId];
        _card.supportCardId = cardData.supportCardId;
        _card.supportCardType = cardData.supportCardType;
        _card.name = cardData.name;
        for (uint256 i = 0; i < cardData.effectOnes.length; i++) {
            _card.effectOnes.push(cardData.effectOnes[i]);
        }
        _card.effectMany = cardData.effectMany;
        _card.unstackable = cardData.unstackable;
        _card.unresettable = cardData.unresettable;

        emit SupportCardUpdated(msg.sender, cardData.supportCardId);
    }

    function getSupportCardById(uint256 _id) public view returns (SupportCardStats memory) {
        require(supportCardStats[_id].supportCardId != 0, "PepemonCard: SupportCard not found");
        return supportCardStats[_id];
    }

    /**
     * @dev Get supportCardType of supportCard
     * @param _id uint256
     */
    function getSupportCardTypeById(uint256 _id) public view returns (SupportCardType) {
        return getSupportCardById(_id).supportCardType;
    }
}