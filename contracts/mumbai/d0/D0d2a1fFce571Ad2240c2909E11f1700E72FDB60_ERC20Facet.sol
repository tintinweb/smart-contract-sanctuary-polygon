// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../libraries/LibERC20.sol";
import "../libraries/LibModifiers.sol";
import {WithStorage} from "../libraries/LibStorage.sol";

contract ERC20Facet is WithStorage, Modifiers {

  function s() private pure returns (ERC20Storage storage ds) {
    return erc20Storage();
  }

  function mint(address account, uint256 amount) external onlyOwner {
    LibERC20._mint(account, amount);
  }

  function burn(address account, uint256 amount) external onlyOwner {
    LibERC20._burn(account, amount);
  }

  function name() external view returns (string memory) {
    return s().name;
  }

  function symbol() external view returns (string memory) {
    return s().symbol;
  }

  function decimals() external pure returns (uint8) {
    return 18;
  }

  function totalSupply() external view returns (uint256) {
    return s().totalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return s().balances[account];
  }

  function transfer(address recipient, uint256 amount) external returns (bool) {
    LibERC20._transfer(msg.sender, recipient, amount);
    return true;
  }

  function allowance(address owner, address spender)
    external
    view
    returns (uint256)
  {
    return s().allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    LibERC20._approve(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool) {
    return LibERC20._transferFrom(sender, recipient, amount);
  }

  function increaseAllowance(address spender, uint256 addedValue)
    external
    returns (bool)
  {
    LibERC20._approve(
      msg.sender,
      spender,
      s().allowances[msg.sender][spender] + addedValue
    );
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    external
    returns (bool)
  {
    return LibERC20._decreaseAllowance(spender, subtractedValue);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {LibStorage, ERC20Storage} from "./LibStorage.sol";

library LibERC20 {
  bytes32 private constant _PERMIT_TYPEHASH =
    keccak256(
      "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

  function s() private pure returns (ERC20Storage storage ds) {
    return LibStorage.erc20Storage();
  }


  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    uint256 senderBalance = s().balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
      s().balances[sender] = senderBalance - amount;
    }
    s().balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);
  }

  function _transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) internal returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = s().allowances[sender][msg.sender];
    require(
      currentAllowance >= amount,
      "ERC20: transfer amount exceeds allowance"
    );
    unchecked {
      _approve(sender, msg.sender, currentAllowance - amount);
    }

    return true;
  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: mint to the zero address");

    s().totalSupply += amount;
    s().balances[account] += amount;
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: burn from the zero address");

    uint256 accountBalance = s().balances[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
      s().balances[account] = accountBalance - amount;
    }
    s().totalSupply -= amount;

    emit Transfer(account, address(0), amount);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    s().allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _decreaseAllowance(address spender, uint256 subtractedValue)
    internal
    returns (bool)
  {
    uint256 currentAllowance = s().allowances[msg.sender][spender];
    require(
      currentAllowance >= subtractedValue,
      "ERC20: decreased allowance below zero"
    );
    unchecked {
      _approve(msg.sender, spender, currentAllowance - subtractedValue);
    }

    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {WithStorage, LibStorage} from "./LibStorage.sol";
import {LibDiamond} from "./LibDiamond.sol";
import {GameItemType} from "../FGTypes.sol";

contract Modifiers {
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyFishItems(uint256 tokenId) {
        require((LibStorage.gameStorage().gameItemLookup[tokenId] == GameItemType.FISH || LibStorage.gameStorage().gameItemLookup[tokenId] == GameItemType.FISH_EGG), "Only fish tokens can be be used with this function.");
        _;
    }

    modifier onlyFishingPoleItems(uint256 tokenId) {
        require(LibStorage.gameStorage().gameItemLookup[tokenId] == GameItemType.FISHING_POLE, "Only fish tokens can be be used with this function.");
        _;
    }

    modifier onlyTackleBoxItems(uint256 tokenId) {
        require(LibStorage.gameStorage().gameItemLookup[tokenId] == GameItemType.TACKLE_BOX, "Only fish tokens can be be used with this function.");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {Player, FishMetadata, FishSpecies, FishMutations, TackleBoxSize, SpawnPool, Snapshot, StakedFish, PlayerCast, FishingPoleMetadata, TackleBoxMetadata, GameItemType} from "../FGTypes.sol";
import {Counters} from "./LibCounters.sol";
import {ILink} from "../interfaces/ILink.sol";

struct BlacklistStorage {
    bool enabled;
    uint256 drip;
    mapping(address => bool) bannedAccounts;
    address[] bannedAccountsArray;
}

struct GameStorage {
    // Contract housekeeping
    address diamondAddress;
    // admin controls
    bool paused;
    uint256 fishSpeciesCount;
    uint256 fishSpawnId;
    // Game world state
    uint256[] fishIds;
    address[] playerIds;
    Counters.Counter fishIdsCounter;
    Counters.Counter gameItemsCounter;
    // Spawn pool state
    mapping(uint256 => SpawnPool) spawnPoolMap; // key is species
    mapping(address => PlayerCast) castMap;
    mapping(uint256 => FishMetadata) fishMetadataLookup;
    mapping(address => Player) players;
    mapping(uint256 => address) fishingPoleOwners;
    mapping(uint256 => address) tackleBoxOwners;
    mapping(uint256 => GameItemType) gameItemLookup;
    mapping(address => mapping(uint256 => StakedFish)) walletToStakedFish; // wallet to (fishId => staked fish state) mapping
    mapping(address => uint256[]) walletToStakedFishIds; // wallet to an array of all staked fish ids -- faster lookup for walletToStakedFish
    mapping(uint256 => address) fishIdToWallet; // fish id to wallet
    mapping(uint256 => uint256) fishTypeToRewardRate; // current reward % for fish type
    mapping(uint256 => Snapshot[]) fishTypeToSnapshots; // fishType to snapshots
    mapping(uint256 => uint256[]) fishTypeToEmptySpawnIndex; // queue of empty spawn indexes for each fish type
    mapping(uint256 => uint256) fishSpeciesToBaitTokenId; // queue of empty spawn indexes for each fish type
    // Game item state
    mapping(uint256 => FishingPoleMetadata) fishingPoleMetadataLookup;
    mapping(uint256 => TackleBoxMetadata) tackleBoxPoleMetadataLookup;
    // Casting state
    mapping(address => uint256) castToRandomNumber;
    mapping(address => PlayerCast) castMetadata;
    mapping(bytes32 => address) vrfRequestIdToPlayer;
    mapping(bytes32 => uint256) vrfNonces;
}

struct ERC20Storage {
    string name;
    string symbol;
    uint256 totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
}

struct ERC20PermitStorage {
    mapping(address => Counters.Counter) nonces;
}

// Game config
struct GameConstants {
    bool ADMIN_CAN_ADJUST_SPAWN_INTERVALS;
    bool ADMIN_CAN_ADJUST_SEASON_END;
    uint256 SEASON_END_TIMESTAMP;
    uint256 FISHING_POLE_COST;
    uint256 FISHING_POLE_REPAIR_COST;
    uint256 TACKLE_BOX_COST;
    uint256 FISHING_POLE_STARTING_STARTING_DURABILITY;
    uint256 TOTAL_SPECIES_COUNT;
    mapping (uint256 => uint256) MAX_FISH_SPECIES_POPULATIONS;
    uint256[15][10] FISH_SPAWN_INTERVALS; // fish species -> intervals for every 10% of max population (0 -> 100)
    uint256 GAME_CURRENCY_MULTIPLIER; // used to adjust the price of items priced in Game Tokens
    uint256 GAME_RARITY_MULTIPLIER; // used to adjust the difficulty of catching higher level fish
    uint256 TIME_FACTOR_HUNDREDTHS; // speedup/slowdown game
    mapping(uint256 => uint256) SPECIES_TO_BAIT_COUNT_LOOKUP;
    // Chainlink oracle config
    bytes32 keyHash;
    uint144 fee;
    address vrfCoordinator;
    ILink link;
}

struct GameCurrency {
    uint256 maxSupply;
    uint256 currentSupply;
}

struct Upgrade {
    uint256 popCapMultiplier; // multiplier for max population
    uint256 popGroMultiplier; // multiplier for growth rate
    uint256 rangeMultiplier;
    uint256 speedMultiplier;
    uint256 defMultiplier;
}

/**
 * The Diamond Storage pattern (https://dev.to/mudgen/how-diamond-storage-works-90e)
 * is used to set the struct at a specific place in contract storage. The pattern
 * recommends that the hash of a specific namespace (e.g. "darkforest.game.storage")
 * be used as the slot to store the struct.
 *
 * Additionally, the Diamond Storage pattern can be used to access and change state inside
 * of Library contract code (https://dev.to/mudgen/solidity-libraries-can-t-have-state-variables-oh-yes-they-can-3ke9).
 * Instead of using `LibStorage.gameStorage()` directly, a Library will probably
 * define a convenience function to accessing state, similar to the `gs()` function provided
 * in the `WithStorage` base contract below.
 *
 * This pattern was chosen over the AppStorage pattern (https://dev.to/mudgen/appstorage-pattern-for-state-variables-in-solidity-3lki)
 * because AppStorage seems to indicate it doesn't support additional state in contracts.
 * This becomes a problem when using base contracts that manage their own state internally.
 *
 * There are a few caveats to this approach:
 * 1. State must always be loaded through a function (`LibStorage.gameStorage()`)
 *    instead of accessing it as a variable directly. The `WithStorage` base contract
 *    below provides convenience functions, such as `gs()`, for accessing storage.
 * 2. Although inherited contracts can have their own state, top level contracts must
 *    ONLY use the Diamond Storage. This seems to be due to how contract inheritance
 *    calculates contract storage layout.
 * 3. The same namespace can't be used for multiple structs. However, new namespaces can
 *    be added to the contract to add additional storage structs.
 * 4. If a contract is deployed using the Diamond Storage, you must ONLY ADD fields to the
 *    very end of the struct during upgrades. During an upgrade, if any fields get added,
 *    removed, or changed at the beginning or middle of the existing struct, the
 *    entire layout of the storage will be broken.
 * 5. Avoid structs within the Diamond Storage struct, as these nested structs cannot be
 *    changed during upgrades without breaking the layout of storage. Structs inside of
 *    mappings are fine because their storage layout is different. Consider creating a new
 *    Diamond storage for each struct.
 *
 * More information on Solidity contract storage layout is available at:
 * https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html
 *
 * Nick Mudge, the author of the Diamond Pattern and creator of Diamond Storage pattern,
 * wrote about the benefits of the Diamond Storage pattern over other storage patterns at
 * https://medium.com/1milliondevs/new-storage-layout-for-proxy-contracts-and-diamonds-98d01d0eadb#bfc1
 */
library LibStorage {
    // Storage are structs where the data gets updated throughout the lifespan of the game
    bytes32 constant GAME_STORAGE_POSITION = keccak256("fishinggame.storage.game");
    bytes32 constant BLACKLIST_STORAGE_POSITION = keccak256("fishinggame.storage.blacklist");
    // Constants are structs where the data gets configured on game initialization
    bytes32 constant GAME_CONSTANTS_POSITION = keccak256("fishinggame.constants.game");
    bytes32 constant GAME_CURRENCY_POSITION = keccak256("fishinggame.constants.currency");
    bytes32 constant UPGRADE_POSITION = keccak256("fishinggame.constants.upgrades");
    bytes32 constant ERC20_POSITION = keccak256("fishinggame.constants.erc20");
    bytes32 constant ERC20_PERMITS_POSITION = keccak256("fishinggame.constants.erc20.permits");

    function gameStorage() internal pure returns (GameStorage storage gs) {
        bytes32 position = GAME_STORAGE_POSITION;
        assembly {
            gs.slot := position
        }
    }

    function blacklistStorage() internal pure returns (BlacklistStorage storage bs) {
        bytes32 position = BLACKLIST_STORAGE_POSITION;
        assembly {
            bs.slot := position
        }
    }

    function gameConstants() internal pure returns (GameConstants storage gc) {
        bytes32 position = GAME_CONSTANTS_POSITION;
        assembly {
            gc.slot := position
        }
    }

    function gameCurrency() internal pure returns (GameCurrency storage gc) {
        bytes32 position = GAME_CURRENCY_POSITION;
        assembly {
            gc.slot := position
        }
    }

    function upgrades() internal pure returns (Upgrade[4][3] storage upgrades) {
        bytes32 position = UPGRADE_POSITION;
        assembly {
            upgrades.slot := position
        }
    }

    function erc20Storage() internal pure returns (ERC20Storage storage erc20) {
        bytes32 position = ERC20_POSITION;
        assembly {
            erc20.slot := position
        } 
    }

    function erc20Permits() internal pure returns (ERC20PermitStorage storage erc20permits) {
        bytes32 position = ERC20_PERMITS_POSITION;
        assembly {
            erc20permits.slot := position
        } 
    }
}

/**
 * The `WithStorage` contract provides a base contract for Facet contracts to inherit.
 *
 * It mainly provides internal helpers to access the storage structs, which reduces
 * calls like `LibStorage.gameStorage()` to just `gs()`.
 *
 * To understand why the storage stucts must be accessed using a function instead of a
 * state variable, please refer to the documentation above `LibStorage` in this file.
 */
contract WithStorage {
    function erc20Storage() internal pure returns (ERC20Storage storage) {
        return LibStorage.erc20Storage();
    }

    function erc20PermitStorage() internal pure returns (ERC20PermitStorage storage) {
        return LibStorage.erc20Permits();
    }

    function gs() internal pure returns (GameStorage storage) {
        return LibStorage.gameStorage();
    }

    function bs() internal pure returns (BlacklistStorage storage) {
        return LibStorage.blacklistStorage();
    }

    function gameConstants() internal pure returns (GameConstants storage) {
        return LibStorage.gameConstants();
    }

    function gameCurrency() internal pure returns (GameCurrency storage) {
        return LibStorage.gameCurrency();
    }

    function upgrades() internal pure returns (Upgrade[4][3] storage) {
        return LibStorage.upgrades();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {Counters} from "./libraries/LibCounters.sol";

/*
    We make sure that all enums have an invalid / unusable default value (0)
    This lets us use things like a mapping -> enum without worrying about
    the default value being inaccurate.
*/
enum FishSpecies {
    Unknown,    // 0
    Goldfish,   // 1
    Trout,      // 2
    Catfish,    // 3
    Tuna,       // 4
    Swordfish,  // 5
    Tigershark, // 6
    Lionfish,   // 7
    Squid,      // 8
    Lobster,    // 9
    Piranha,    // 10
    SeaHorse,   // 11
    Pufferfish, // 12
    Angelfish,  // 13
    Octopus,    // 14
    Pogfish     // 15
}

struct PlayerCast {
    uint256 baitId;
    uint256 fishingPoleId;
    uint256 timestamp;
}

enum TackleBoxSize {
    INVALID,
    SMALL,
    MEDIUM,
    LARGE,
    MASSIVE
}
enum FishMutations {
    NONE,
    TWO_HEADS,
    TWO_TAILS,
    ONE_EYE,
    NO_EYES
}

enum GameItemType {
    UNKNOWN,
    FISHING_POLE,
    TACKLE_BOX,
    FISH,
    BAIT,
    FISH_EGG
}

struct FishMetadata {
    uint256 id;
    uint256 weight;
    uint256 length;
    FishSpecies species; // Maps from a FishSpecies enum
    FishMutations[] mutations;
}

// Initialized when a fishing pole is purchased
struct Player {
    uint256 fishingExperience;
    uint256 fishingPoleId;
    uint256[] fishIds;
    // Keeps track of which fish id is at which index in fishIds for an instant lookup
    mapping(uint256 => uint256) fishIdIndexLookup;
}

struct Snapshot {
    uint256 start;
    uint256 end;
    uint256 rewardRate;
}

struct StakedFish {
    uint256 id;
    uint256 timestamp;
    uint256 snapshotIndex;
    FishSpecies species;
}

struct SpawnPool {
    FishSpecies species;
    uint256 currentPopulationCounter;
    uint256 maxPopulation;
    uint256 growthRate;
    uint256 currentRewardRate;
    uint256[] fishIds;
    uint256[] emptySpawnIndexQueue;
    Snapshot[] snapshots;
}

struct FishingPoleMetadata {
    uint256 durability;
}

struct TackleBoxMetadata {
    TackleBoxSize size;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/**
 * @title Uint representation modifiable only by increment or decrement
 * @dev underlying value must not be directly accessed
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library Counters {
  struct Counter {
    uint256 _value;
  }

  function current(
    Counter storage counter
  ) internal view returns (uint256) {
    return counter._value;
  }

  function increment(
    Counter storage counter
  ) internal {
    counter._value++;
  }

  function decrement(
    Counter storage counter
  ) internal {
    require(counter._value > 0, 'Counter: underflow');
    counter._value--;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ILink {
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function approve(address spender, uint256 value) external returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue) external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value) external returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}