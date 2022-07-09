// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { IGear } from "../../shared/interfaces/IGear.sol";

import { GearStorage as GEAR, gearSlot, GearModifiers } from "../storage/GearStorage.sol";
import { ItemsStorage as ITEM } from "../storage/ItemsStorage.sol";
import { KnightModifiers } from "../storage/KnightStorage.sol";

contract GearFacet is IGear, KnightModifiers, GearModifiers {
  using GEAR for GEAR.Layout;
  using ITEM for ITEM.Layout;

  function createGear(uint id, gearSlot slot, string memory name) public isGear(id) {
    require(GEAR.getGearSlot(id) == gearSlot.NONE,
      "ForgeFacet: This type of gear already exists, use mintGear instead");
    require(slot != gearSlot.NONE,
      "ForgeFacet: Can't create gear of type EMPTY");
    GEAR.layout().gearSlot[id] = slot;
    GEAR.layout().gearName[id] = name;
    emit GearCreated(id, slot, name);
  }

  function equipItem(uint256 knightId, uint256 itemId) private notKnight(itemId) {
    require(ITEM.balanceOf(msg.sender, itemId) > 0, 
      "GearFacet: You don't own this item");
    uint256 oldItemId = getEquipmentInSlot(knightId, getGearSlot(itemId));
    if (oldItemId != itemId) {
      require(getGearEquipable(msg.sender, itemId) > 0,
        "GearFacet: This item is not equipable (either equipped on other character or part of ongoing lending or sell order)");
      //Equip new gear
      GEAR.layout().knightSlotItem[knightId][getGearSlot(itemId)] = itemId;
      GEAR.layout().notEquippable[msg.sender][itemId]++;
      //Unequip old gear
      if (oldItemId != 0) {
        GEAR.layout().notEquippable[msg.sender][oldItemId]--;
      }
      emit GearEquipped(knightId, getGearSlot(itemId), itemId);
    }
  }

  function unequipItem(uint256 knightId, gearSlot slot) private {
    uint256 oldItemId = getEquipmentInSlot(knightId, slot);
    //Uneqip slot
    GEAR.layout().knightSlotItem[knightId][slot] = 0;
    //Unequip item
    if (oldItemId != 0) {
      GEAR.layout().notEquippable[msg.sender][oldItemId]--;
    }
  }

  function updateKnightGear(uint256 knightId, uint256[] memory items) external isKnight(knightId) {
    require(ITEM.balanceOf(msg.sender, knightId)> 0, 
      "GearFacet: You don't own this knight");
    for (uint i = 0; i < items.length; i++) {
      if (items[i] > type(uint8).max) {
        equipItem(knightId, items[i]);
      } else {
        unequipItem(knightId, gearSlot(uint8(items[i])));
      }
    }
  }

  function getGearSlot(uint256 itemId) public view notKnight(itemId) returns(gearSlot) {
    return GEAR.getGearSlot(itemId);
  }

  function getGearName(uint256 itemId) public view notKnight(itemId) returns(string memory) {
    return GEAR.getGearName(itemId);
  }

  function getEquipmentInSlot(uint256 knightId, gearSlot slot) public view returns(uint256) {
    return GEAR.getEquipmentInSlot(knightId, slot);
  }

  function notEquippable(address account, uint256 itemId) internal view returns(uint256) {
    return GEAR.notEquippable(account, itemId);
  }

  function getGearEquipable(address account, uint256 itemId) public view notKnight(itemId) returns(uint256) {
    uint256 itemBalance = ITEM.balanceOf(account, itemId);
    uint256 equippedOrLended = notEquippable(account, itemId);
    return itemBalance - equippedOrLended;
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { gearSlot } from "../../StableBattle/storage/GearStorage.sol";

interface IGear {
  
  function getGearSlot(uint256 itemId) external returns(gearSlot);

  function getGearName(uint256 itemId) external view returns(string memory);

  function getEquipmentInSlot(uint256 knightId, gearSlot slot) external returns(uint256);

  function getGearEquipable(address account, uint256 itemId) external returns(uint256);

  function createGear(uint id, gearSlot slot, string memory name) external;

  function updateKnightGear(uint256 knightId, uint256[] memory items) external;

  event GearCreated(uint256 id, gearSlot slot, string name);
  event GearEquipped(uint256 knightId, gearSlot slot, uint256 itemId);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

enum gearSlot {
  NONE,
  WEAPON,
  SHIELD,
  HELMET,
  ARMOR,
  PANTS,
  SLEEVES,
  GLOVES,
  BOOTS,
  JEWELRY,
  CLOAK
}

library GearStorage {
	struct Layout {
    uint256 gearRangeLeft;
    uint256 gearRangeRight;
    //knightId => gearSlot => itemId
    //Returns an itemId of item equipped in gearSlot for Knight with knightId
    mapping(uint256 => mapping(gearSlot => uint256)) knightSlotItem;
    //itemId => slot
    //Returns gear slot for particular item per itemId
    mapping(uint256 => gearSlot) gearSlot;
    //itemId => itemName
    //Returns a name of particular item per itemId
    mapping(uint256 => string) gearName;
    //knightId => itemId => amount 
    //Returns amount of nonequippable (either already equipped or lended or in pending sell order)
      //items per itemId for a particular wallet
    mapping(address => mapping(uint256 => uint256)) notEquippable;
	}

	bytes32 internal constant STORAGE_SLOT = keccak256("Gear.storage");

	function layout() internal pure returns (Layout storage l) {
		bytes32 slot = STORAGE_SLOT;
		assembly {
			l.slot := slot
		}
	}

  function getGearSlot(uint256 itemId) internal view returns(gearSlot) {
    return layout().gearSlot[itemId];
  }

  function getGearName(uint256 itemId) internal view returns(string memory) {
    return layout().gearName[itemId];
  }

  function getEquipmentInSlot(uint256 knightId, gearSlot slot) internal view returns(uint256) {
    return layout().knightSlotItem[knightId][slot];
  }

  function notEquippable(address account, uint256 itemId) internal view returns(uint256) {
    return layout().notEquippable[account][itemId];
  }
}

contract GearModifiers {
  modifier isGear(uint256 id) {
    require(id >= GearStorage.layout().gearRangeLeft && 
            id <  GearStorage.layout().gearRangeRight,
            "GearFacet: Wrong id range for gear item");
    _;
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