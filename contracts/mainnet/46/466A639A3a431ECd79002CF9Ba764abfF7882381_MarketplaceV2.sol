// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "../system/CrudKeySet.sol";
import "../system/HSystemChecker.sol";
import "../milk/ITreasury.sol";
import "./IItemFactory.sol";

/// @dev Dev notes:
/// @dev System will carry out marketplace transactions on user's behalf
/// @dev Team decided that it will be cleaner to have the marketplace take ownership of the listed items,
/// @dev avoid having to check if item is sold on external marketplaces
contract MarketplaceV2 is Context, HSystemChecker {
  IItemFactory _itemFactory;
  address public _itemFactoryContractAddress;
  address public _treasuryContractAddress;

  using CrudKeySetLib for CrudKeySetLib.Set;
  CrudKeySetLib.Set _listingSet;

  mapping(bytes32 => uint256) _listingData;
  mapping(bytes32 => uint256) _listingPrices;

  struct ListingStruct {
    address seller;
    uint256 id;
    uint256 tokenId;
    uint256 amount;
    uint256 listingTime;
    uint256 price; // desired price to earn in Wei
    uint256 listedPrice; // price + fees
  }

  /// @dev start _listingId as 1
  /// @dev reserve 0 to check for non-existent listing mapping in listingExists modifier
  uint256 public _listingId = 1;

  /// @dev 10% sales fee as basis point
  uint256 public _saleFeeBp = 1000;

  event LogNewListing(uint256 listingId, address seller, uint256 tokenId, uint256 amount, uint256 price);
  event LogRemoveListing(uint256 listingId, address seller);
  event LogPurchase(uint256 listingId, address seller, address buyer);
  event LogSetFee(uint256 feeBp);

  constructor(
    address systemCheckerContractAddress,
    address treasuryContractAddress,
    address itemFactoryContractAddress
  ) HSystemChecker(systemCheckerContractAddress) {
    _itemFactoryContractAddress = itemFactoryContractAddress;
    _itemFactory = IItemFactory(itemFactoryContractAddress);

    _treasuryContractAddress = treasuryContractAddress;
  }

  /// @notice Check that a listing exists
  /// @param listingId identifier for the desired listing
  modifier listingExists(uint256 listingId) {
    require(_listingSet.exists(bytes32(listingId)), "MP 400 - Listing does not exist.");
    _;
  }

  /// @notice Creates a new listing
  /// @dev This can only be sent from the system
  /// @dev gameSafeTransfer() handles isUser()
  /// @param tokenId token id of item to list
  /// @param amount amount of tokenId to list
  /// @param price desired price to list in wei
  /// @param seller address of seller/owner of tokens
  function createListing(
    uint256 tokenId,
    uint256 amount,
    uint256 price,
    address seller
  ) public onlyRole(GAME_ROLE) {
    bytes32 listingIdBytes = bytes32(_listingId);

    _setListing(listingIdBytes, seller, _listingId, tokenId, amount, block.timestamp, price);

    _listingSet.insert(listingIdBytes);

    // transfer token from seller to systemAddress
    _itemFactory.gameSafeTransferFrom(seller, _systemChecker.getSafeAddress(MARKETPLACE_KEY_BYTES), tokenId, amount, "");

    emit LogNewListing(_listingId++, seller, tokenId, amount, price); // increase _listingId by 1
  }

  /// @notice Handles data packing for a listing
  /// @param listingIdBytes bytes32 of listing id
  /// @param seller address of seller
  /// @param listingId id of listing
  /// @param tokenId token id of item to list
  /// @param amount amount of tokenId to list
  /// @param listingTime time listing was created
  /// @param price MILK price in wei
  function _setListing(
    bytes32 listingIdBytes,
    address seller,
    uint256 listingId,
    uint256 tokenId,
    uint256 amount,
    uint256 listingTime,
    uint256 price
  ) internal {
    require(listingId < 281474976710656, "MP 401 - Listing ID exceeds max of uint48.");
    require(tokenId < 65536, "MP 402 - Token Id exceeds max of uint16.");
    require(amount < 4294967296, "MP 403 - Amount to sell exceeds max of uint32.");
    require(listingTime < 28147497671066, "MP 404 - Listing time exceeds max of uint48.");
    require((price + ((price * _saleFeeBp) / 10000)) <= type(uint104).max, "MP 405 - Price exceeds max of uint104.");

    uint256 listing = uint256(uint160(seller)); //uint160
    listing |= listingId << 160; //uint48
    listing |= tokenId << 208; //uint16
    listing |= amount << 224; //uint32
    _listingData[listingIdBytes] = listing;

    uint256 pricing = uint256(price); //uint104
    pricing |= (price + ((price * _saleFeeBp) / 10000)) << 104; //uint104
    pricing |= listingTime << 208; //uint48
    _listingPrices[listingIdBytes] = pricing;
  }

  /// @notice Get the listing by uint256 listing id
  /// @dev Takes listingId in uint256 and calls internal getListing(bytes32)
  /// @param listingId listing id
  /// @return listing listing struct
  function getListing(uint256 listingId) external view listingExists(listingId) returns (ListingStruct memory) {
    //takes the uint256 of listing id and returns the bytes
    return _getListing(bytes32(listingId));
  }

  /// @notice Get the listing by listing id in bytes32
  /// @dev This can only be sent from the system
  /// @param listingIdBytes listing id
  /// @return itemListing listing struct
  function _getListing(bytes32 listingIdBytes) internal view returns (ListingStruct memory itemListing) {
    uint256 listing = _listingData[listingIdBytes];
    itemListing.seller = address(uint160(listing));
    itemListing.id = uint256(uint48(listing >> 160));
    itemListing.tokenId = uint256(uint16(listing >> 208));
    itemListing.amount = uint256(uint32(listing >> 224));

    uint256 pricing = _listingPrices[listingIdBytes];
    itemListing.price = uint256(uint104(pricing));
    itemListing.listedPrice = uint256(uint104(pricing >> 104));
    itemListing.listingTime = uint256(uint48(pricing >> 208));
    return itemListing;
  }

  /// @notice Gets the array of listing ids
  /// @dev This can only be sent from the system
  /// @return listingIds_ array of listing ids
  function getListingIds() public view returns (bytes32[] memory) {
    return _listingSet.keyList;
  }

  /// @notice Deletes an existing listing struct, meant for removing listing without a sale
  /// @dev This can only be sent from the system
  /// @dev _removeListing checks if listing exists
  /// @dev Called when removing a listing, safeTransferFrom returns item to seller
  /// @param listingId listing id to deactivate
  /// @param seller address of the seller
  function removeListing(uint256 listingId, address seller) public onlyRole(GAME_ROLE) isUser(seller) {
    bytes32 listingIdBytes = bytes32(listingId);

    ListingStruct memory li = _getListing(listingIdBytes);

    require(li.seller == seller, "MP 406 - Not the seller.");

    _itemFactory.gameSafeTransferFrom(_systemChecker.getSafeAddress(MARKETPLACE_KEY_BYTES), li.seller, li.tokenId, li.amount, "");

    _removeListing(listingId, li.seller);
  }

  /// @notice Deletes an existing listing struct, meant for removing listing without a sale
  /// @dev This can only be sent from the system
  /// @dev Has modifier to check if listing exists
  /// @dev Called when removing a listing after being sold, safeTransferFrom to transfer token from game to buyer is called in the buying function
  /// @param listingId listing id to deactivate
  function _removeListing(uint256 listingId, address seller) internal {
    bytes32 listingIdBytes = bytes32(listingId);

    // emit before required data is deleted
    emit LogRemoveListing(listingId, seller);

    // update listing trackers
    _listingSet.remove(listingIdBytes);

    delete _listingData[listingIdBytes];
    delete _listingPrices[listingIdBytes];
  }

  /// @notice Buys a listing's offering
  /// @dev This can only be sent from the system
  /// @dev gameSafeTransfer() handles isUser()
  /// @dev listingExists() check is handled by _removeListing
  /// @param buyer address of buyer
  /// @param listingId listing id
  function buyListing(address buyer, uint256 listingId) public onlyRole(GAME_ROLE) isUser(buyer) {
    ITreasury treasury = ITreasury(_treasuryContractAddress);

    // create a temporary listing struct to reference
    ListingStruct memory li = _getListing(bytes32(listingId));

    // remove listing that is purchased
    _removeListing(listingId, li.seller);

    // transfer token ownership
    _itemFactory.gameSafeTransferFrom(_systemChecker.getSafeAddress(MARKETPLACE_KEY_BYTES), buyer, li.tokenId, li.amount, "");

    // transfer milk of buyer to seller at seller's desired price through treasury
    treasury.transferFrom(buyer, li.seller, li.price);

    // transfer milk of buyer to system at fee price (listingPrice - price) through treasury
    treasury.transferFrom(buyer, _systemChecker.getSafeAddress(SYSTEM_KEY_BYTES), li.listedPrice - li.price);

    emit LogPurchase(listingId, li.seller, buyer);
  }

  /// @notice Set the transaction fee desired for subsequent new listings
  /// @dev This can only be sent from the system
  /// @dev 500 = 5%
  /// @param feeBp desired fee basis point
  function setFee(uint256 feeBp) external onlyRole(ADMIN_ROLE) {
    require(feeBp <= 10000, "MP 407 - Don't be greedy.");
    _saleFeeBp = feeBp;
    emit LogSetFee(feeBp);
  }

  /// @notice Push new address for the Treasury Contract
  /// @param treasuryContractAddress - address of the Item Factory
  function setTreasuryContractAddress(address treasuryContractAddress) external onlyRole(ADMIN_ROLE) {
    _treasuryContractAddress = treasuryContractAddress;
  }

  /// @notice Push new address for the Item Factory Contract
  /// @param itemFactoryContractAddress - address of the Item Factory
  function setItemFactoryContractAddress(address itemFactoryContractAddress) external onlyRole(ADMIN_ROLE) {
    _itemFactoryContractAddress = itemFactoryContractAddress;
    _itemFactory = IItemFactory(itemFactoryContractAddress);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
Hitchens UnorderedKeySet v0.93
Library for managing CRUD operations in dynamic key sets.
https://github.com/rob-Hitchens/UnorderedKeySet
Copyright (c), 2019, Rob Hitchens, the MIT License
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
THIS SOFTWARE IS NOT TESTED OR AUDITED. DO NOT USE FOR PRODUCTION.
*/
// Edited to suit our needs

library CrudKeySetLib {
    struct Set {
        mapping(bytes32 => uint256) keyPointers;
        bytes32[] keyList;
    }

    function insert(Set storage self, bytes32 key) internal {
        require(key != 0x0, "UnorderedKeySet 100 - Key cannot be 0x0");
        require(
            !exists(self, key),
            "UnorderedKeySet 101 - Key already exists in the set."
        );
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }

    function remove(Set storage self, bytes32 key) internal {
        require(
            exists(self, key),
            "UnorderedKeySet 102 - Key does not exist in the set."
        );
        uint last = count(self) - 1;
        uint rowToReplace = self.keyPointers[key];
        if(rowToReplace != last) {
            bytes32 keyToMove = self.keyList[last];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
        }
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    function count(Set storage self) internal view returns (uint256) {
        return (self.keyList.length);
    }

    function exists(Set storage self, bytes32 key)
        internal
        view
        returns (bool)
    {
        if (self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    function keyAtIndex(Set storage self, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return self.keyList[index];
    }

    function nukeSet(Set storage self) internal {
        for (uint256 i; i < self.keyList.length; i++) {
            delete self.keyPointers[self.keyList[i]];
        }
        delete self.keyList;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISystemChecker.sol";
import "./RolesAndKeys.sol";

contract HSystemChecker is RolesAndKeys {

    ISystemChecker _systemChecker;
    address public _systemCheckerContractAddress;

    constructor(address systemCheckerContractAddress) {
        _systemCheckerContractAddress = systemCheckerContractAddress;
        _systemChecker = ISystemChecker(systemCheckerContractAddress);
    }

    /// @notice Check if an address is a registered user or not
    /// @dev Triggers a require in systemChecker
    modifier isUser(address user) {
        _systemChecker.isUser(user);
        _;
    }

    /// @notice Check that the msg.sender has the desired role
    /// @dev Triggers a require in systemChecker
    modifier onlyRole(bytes32 role) {
        require(_systemChecker.hasRole(role, _msgSender()), "SC: Invalid transaction source");
        _;
    }

    /// @notice Push new address for the SystemChecker Contract
    /// @param systemCheckerContractAddress - address of the System Checker
    function setSystemCheckerContractAddress(address systemCheckerContractAddress) external onlyRole(ADMIN_ROLE) {
        _systemCheckerContractAddress = systemCheckerContractAddress;
        _systemChecker = ISystemChecker(systemCheckerContractAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITreasury {
    function balanceOf(address account) external view returns (uint256);
    function withdraw(address user, uint256 amount) external;
    function burn(address owner, uint256 amount) external;
    function mint(address owner, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IItemFactory {
    function burnItem(address owner, uint256 itemTokenId, uint256 amount) external;
    function mintItem(address owner, uint256 itemTokenId, uint256 amount) external;
    function gameSafeTransferFrom( address from, address to, uint256 id, uint256 amount, bytes memory data ) external;
    function getItemById(uint256 itemTokenId) external returns(bytes32 categoryKey, bytes32 typeKey);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISystemChecker {
    function createNewRole(bytes32 role) external;
    function hasRole(bytes32 role, address account) external returns (bool);
    function hasPermission(bytes32 role, address account) external;
    function isUser(address user) external;
    function getSafeAddress(bytes32 key) external returns (address);
    function grantRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';

abstract contract RolesAndKeys is Context {
    // ROLES
    bytes32 constant MASTER_ROLE = keccak256("MASTER_ROLE");
    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 constant GAME_ROLE = keccak256("GAME_ROLE");
    bytes32 constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");
    bytes32 constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    // KEYS
    bytes32 constant MARKETPLACE_KEY_BYTES = keccak256("MARKETPLACE");
    bytes32 constant SYSTEM_KEY_BYTES = keccak256("SYSTEM");
    bytes32 constant QUEST_KEY_BYTES = keccak256("QUEST");
    bytes32 constant BATTLE_KEY_BYTES = keccak256("BATTLE");
    bytes32 constant HOUSE_KEY_BYTES = keccak256("HOUSE");
    bytes32 constant QUEST_GUILD_KEY_BYTES = keccak256("QUEST_GUILD");

    // COMMON
    bytes32 constant public PET_BYTES = 0x5065740000000000000000000000000000000000000000000000000000000000;
}