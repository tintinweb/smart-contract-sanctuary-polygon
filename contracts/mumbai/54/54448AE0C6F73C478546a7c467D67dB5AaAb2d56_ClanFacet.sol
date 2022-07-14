// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ClanStorage as CLAN, Clan } from "../storage/ClanStorage.sol";
import { ItemsStorage as ITEM } from "../storage/ItemsStorage.sol";
import { KnightStorage as KNHT } from "../storage/KnightStorage.sol";
import { IClan } from "../../shared/interfaces/IClan.sol";

contract ClanFacet is IClan {
  using CLAN for CLAN.Layout;
  using KNHT for KNHT.Layout;

  function randomClanId() private view returns (uint clanId) {
    uint salt;
    do {
      salt++;
      clanId = uint(keccak256(abi.encodePacked(block.timestamp, tx.origin, salt)));
    } while (clanOwner(clanId) != 0);
  }
  
  function create(uint knightId) public returns (uint clanId) {
    require(knightId > KNHT.knightOffset(), "ClanFacet: Item is not a knight");
    require(ITEM.balanceOf(msg.sender, knightId) == 1,
            "ClanFacet: You don't own this knight");
    require(clanOwner(KNHT.knightClan(knightId)) == 0,
            "ClanFacet: Leave a clan before creating your own");
    require(KNHT.knightClanOwnerOf(knightId) == 0, "ClanFacet: Only one clan per knight");
    clanId = randomClanId();
    CLAN.layout().clan[clanId] = Clan(knightId, 1, 0, 0);
    KNHT.layout().knight[knightId].inClan = clanId;
    KNHT.layout().knight[knightId].ownsClan = clanId;
    emit ClanCreated(clanId, knightId);
  }

  function dissolve(uint clanId) public {
    uint ownerId = clanOwner(clanId);
    require(ITEM.balanceOf(msg.sender, ownerId) == 1,
            "ClanFacet: A knight owning this clan doesn't belong to you");
    KNHT.layout().knight[ownerId].ownsClan = 0;
    KNHT.layout().knight[ownerId].inClan = 0;
    CLAN.layout().clan[clanId].owner = 0;
    emit ClanDissloved(clanId, ownerId);
  }

  function onStake(address benefactor, uint clanId, uint amount) public {
    require(clanOwner(clanId) != 0, "ClanFacet: This clan doesn't exist");

    CLAN.layout().stake[benefactor][clanId] += amount;
    CLAN.layout().clan[clanId].stake += amount;
    leveling(clanId);

    emit StakeAdded(benefactor, clanId, amount);
  }

  function onWithdraw(address benefactor, uint clanId, uint amount) public {
    require(stakeOf(benefactor, clanId) >= amount, "ClanFacet: Not enough SBT staked");
    
    CLAN.layout().stake[benefactor][clanId] -= amount;
    CLAN.layout().clan[clanId].stake -= amount;
    leveling(clanId);

    emit StakeWithdrawn(benefactor, clanId, amount);
  }

  //Calculate clan level based on stake
  function leveling(uint clanId) private {
    uint newLevel = 0;
    while (clanStake(clanId) > clanLevelThresholds(newLevel) &&
           newLevel < clanMaxLevel()) {
      newLevel++;
    }
    if (clanLevel(clanId) < newLevel) {
      CLAN.layout().clan[clanId].level = newLevel;
      emit ClanLeveledUp (clanId, newLevel);
    } else if (clanLevel(clanId) > newLevel) {
      CLAN.layout().clan[clanId].level = newLevel;
      emit ClanLeveledDown (clanId, newLevel);
    }
  }

  function join(uint knightId, uint clanId) public {
    require(knightId > KNHT.knightOffset(),
      "ClanFacet: Item is not a knight");
    require(ITEM.balanceOf(msg.sender, knightId) == 1,
      "ClanFacet: You don't own this knight");
    require(clanOwner(KNHT.knightClan(knightId)) == 0,
      "ClanFacet: Leave your old clan before joining a new one");
    
    CLAN.layout().joinProposal[knightId] = clanId;
    emit KnightAskedToJoin(clanId, knightId);
  }

  function acceptJoin(uint256 knightId, uint256 clanId) public {
    require(ITEM.balanceOf(msg.sender, clanOwner(clanId)) == 1,
            "ClanFacet: A knight owning this clan doesn't belong to you");
    require(joinProposal(knightId) == clanId,
            "ClanFacet: This knight didn't offer to join your clan");

    CLAN.layout().clan[clanId].totalMembers++;
    KNHT.layout().knight[knightId].inClan = clanId;
    CLAN.layout().joinProposal[knightId] = 0;

    emit KnightJoinedClan(clanId, knightId);
  }

  function refuseJoin(uint256 knightId, uint256 clanId) public {
    require(ITEM.balanceOf(msg.sender, clanOwner(clanId)) == 1,
            "ClanFacet: A knight owning this clan doesn't belong to you");
    require(joinProposal(knightId) == clanId,
            "ClanFacet: This knight didn't offer to join your clan");
    
    CLAN.layout().joinProposal[knightId] = 0;

    emit JoinProposalRefused(clanId, knightId);
  }

  function leave(uint256 knightId, uint256 clanId) public {
    require(ITEM.balanceOf(msg.sender, knightId) == 1,
      "ClanFacet: This knight doesn't belong to you");
    require(KNHT.knightClan(knightId) == clanId, 
      "ClanFacet: Your knight doesn't belong to this clan");
    require(clanOwner(clanId) != knightId,
      "ClanFacet: You can't leave your own clan");

    CLAN.layout().leaveProposal[knightId] = clanId;
    
    emit KnightAskedToLeave(clanId, knightId);
  }

  function acceptLeave(uint256 knightId, uint256 clanId) public {
    require(ITEM.balanceOf(msg.sender, clanOwner(clanId)) == 1,
            "ClanFacet: A knight owning this clan doesn't belong to you");
    require(leaveProposal(knightId) == clanId,
            "ClanFacet: This knight didn't offer to leave your clan");

    CLAN.layout().clan[clanId].totalMembers--;
    KNHT.layout().knight[knightId].inClan = 0;
    CLAN.layout().leaveProposal[knightId] = 0;

    emit KnightLeavedClan(clanId, knightId);
  }

  function refuseLeave(uint256 knightId, uint256 clanId) public {
    require(ITEM.balanceOf(msg.sender, clanOwner(clanId)) == 1,
            "ClanFacet: A knight owning this clan doesn't belong to you");
    require(leaveProposal(knightId) == clanId,
            "ClanFacet: This knight didn't offer to leave your clan");
    
    CLAN.layout().leaveProposal[knightId] = 0;

    emit LeaveProposalRefused(clanId, knightId);
  }

  function clanCheck(uint clanId) public view returns(Clan memory) {
    return CLAN.clanCheck(clanId);
  }

  function clanOwner(uint clanId) public view returns(uint256) {
    return CLAN.clanOwner(clanId);
  }

  function clanTotalMembers(uint clanId) public view returns(uint) {
    return CLAN.clanTotalMembers(clanId);
  }
  
  function clanStake(uint clanId) public view returns(uint) {
    return CLAN.clanStake(clanId);
  }

  function clanLevel(uint clanId) public view returns(uint) {
    return CLAN.clanLevel(clanId);
  }

  function stakeOf(address benefactor, uint clanId) public view returns(uint256) {
    return CLAN.stakeOf(benefactor, clanId);
  }

  function clanLevelThresholds(uint newLevel) public view returns (uint) {
    return CLAN.clanLevelThresholds(newLevel);
  }

  function clanMaxLevel() public view returns (uint) {
    return CLAN.clanMaxLevel();
  }

  function joinProposal(uint256 knightId) public view returns (uint) {
    return CLAN.joinProposal(knightId);
  }

  function leaveProposal(uint256 knightId) public view returns (uint) {
    return CLAN.leaveProposal(knightId);
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

struct Clan {
  uint256 owner;
  uint totalMembers;
  uint stake;
  uint level;
}

library ClanStorage {
  struct Layout {
    uint MAX_CLAN_MEMBERS;
    uint[] levelThresholds;
    // clan_id => clan
    mapping(uint => Clan) clan;
    // character_id => clan_id
    mapping (uint256 => uint) joinProposal;
    // character_id => clan_id
    mapping (uint256 => uint) leaveProposal;
    // address => clan_id => amount
    mapping (address => mapping (uint => uint256)) stake;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("Clan.storage");

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }

  function clanCheck(uint clanId) internal view returns(Clan memory) {
    return layout().clan[clanId];
  }

  function clanOwner(uint clanId) internal view returns(uint256) {
    return layout().clan[clanId].owner;
  }

  function clanTotalMembers(uint clanId) internal view returns(uint) {
    return layout().clan[clanId].totalMembers;
  }
  
  function clanStake(uint clanId) internal view returns(uint256) {
    return layout().clan[clanId].stake;
  }

  function clanLevel(uint clanId) internal view returns(uint) {
    return layout().clan[clanId].level;
  }

  function stakeOf(address benefactor, uint clanId) internal view returns(uint256) {
    return layout().stake[benefactor][clanId];
  }

  function clanLevelThresholds(uint newLevel) internal view returns (uint) {
    return layout().levelThresholds[newLevel];
  }

  function clanMaxLevel() internal view returns (uint) {
    return layout().levelThresholds.length;
  }

  function joinProposal(uint256 knightId) internal view returns (uint) {
    return layout().joinProposal[knightId];
  }

  function leaveProposal(uint256 knightId) internal view returns (uint) {
    return layout().leaveProposal[knightId];
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

library ItemsStorage {
  struct Layout {
  //Original ERC1155 Layout
    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string _uri;

  //ERC1155Supply Addition
    // Total amount of tokens in with a given id.
    mapping(uint256 => uint256) _totalSupply;
    
  //Items Facet Addition
    // Mapping from token ID to its owner
    mapping (uint256 => address) _knightOwners;

    uint256 totalKnightSupply;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("Items.storage");

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }

  function balanceOf(address account, uint256 id) internal view returns (uint256) {
    require(account != address(0), "ERC1155: address zero is not a valid owner");
    return layout()._balances[id][account];
  }

  function totalSupply(uint256 id) internal view returns (uint256) {
      return layout()._totalSupply[id];
  }

  function totalKnightSupply() internal view returns (uint256) {
    return layout().totalKnightSupply;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

enum knightType {
  AAVE,
  OTHER
}

struct Knight {
  uint256 inClan;
  uint256 ownsClan;
  uint level;
  knightType kt;
  address owner;
}

library KnightStorage {
  struct Layout {
    uint256 knightOffset;
    mapping(uint256 => Knight) knight;
    mapping(knightType => uint256) knightPrice;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("Knight.storage");

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
  
  function knightCheck(uint256 kinghtId) internal view returns(Knight memory) {
    return layout().knight[kinghtId];
  }

  function knightClan(uint256 kinghtId) internal view returns(uint256) {
    return layout().knight[kinghtId].inClan;
  }

  function knightClanOwnerOf(uint256 kinghtId) internal view returns(uint256) {
    return layout().knight[kinghtId].ownsClan;
  }

  function knightLevel(uint256 kinghtId) internal view returns(uint) {
    return layout().knight[kinghtId].level;
  }

  function knightTypeOf(uint256 kinghtId) internal view returns(knightType) {
    return layout().knight[kinghtId].kt;
  }

  function knightOwner(uint256 knightId) internal view returns(address) {
    return layout().knight[knightId].owner;
  }

  function knightOffset() internal view returns (uint256) {
    return layout().knightOffset;
  }

  function knightPrice(knightType kt) internal view returns (uint256) {
    return layout().knightPrice[kt];
  }
}

contract KnightModifiers {
  modifier notKnight(uint256 itemId) {
    require(itemId < KnightStorage.layout().knightOffset, 
      "KnightModifiers: Wrong id for something other than knight");
    _;
  }

  modifier isKnight(uint256 knightId) {
    require(knightId >= KnightStorage.layout().knightOffset, 
      "KnightModifiers: Wrong id for knight");
    _;
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { Clan } from "../../StableBattle/storage/ClanStorage.sol";

interface IClan {
  
  function create(uint charId) external returns (uint clanId);

  function dissolve(uint clanId) external;

  function onStake(address benefactor, uint clanId, uint amount) external;

  function onWithdraw(address benefactor, uint clanId, uint amount) external;

  function join(uint charId, uint clanId) external;

  function acceptJoin(uint256 charId, uint256 clanId) external;

  function refuseJoin(uint256 charId, uint256 clanId) external;

  function leave(uint256 charId, uint256 clanId) external;

  function acceptLeave(uint256 charId, uint256 clanId) external;

  function refuseLeave(uint256 charId, uint256 clanId) external;

  function clanCheck(uint clanId) external view returns(Clan memory);

  function clanOwner(uint clanId) external view returns(uint256);

  function clanTotalMembers(uint clanId) external view returns(uint);
  
  function clanStake(uint clanId) external view returns(uint);

  function clanLevel(uint clanId) external view returns(uint);

  function stakeOf(address benefactor, uint clanId) external view returns(uint256);

  function clanLevelThresholds(uint newLevel) external view returns (uint);

  function clanMaxLevel() external view returns (uint);

  function joinProposal(uint256 knightId) external view returns (uint);

  function leaveProposal(uint256 knightId) external view returns (uint);

  event ClanCreated(uint clanId, uint charId);
  event ClanDissloved(uint clanId, uint charId);
  event StakeAdded(address benefactor, uint clanId, uint amount);
  event StakeWithdrawn(address benefactor, uint clanId, uint amount);
  event ClanLeveledUp(uint clanId, uint newLevel);
  event ClanLeveledDown(uint clanId, uint newLevel);
  event KnightAskedToJoin(uint clanId, uint charId);
  event KnightJoinedClan(uint clanId, uint charId);
  event JoinProposalRefused(uint clanId, uint charId);
  event KnightAskedToLeave(uint clanId, uint charId);
  event KnightLeavedClan(uint clanId, uint charId);
  event LeaveProposalRefused(uint clanId, uint charId);
}