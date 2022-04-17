// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../system/CrudKeySet.sol";
import "../system/HSystemChecker.sol";
import "../milk/ITreasury.sol";
import "./IItemFactory.sol";
import "./IMarketVault.sol";
import "../../common/Multicall.sol";

/// @dev Dev notes:
/// @dev System will carry out marketplace transactions on user's behalf
/// @dev Team decided that it will be cleaner to have the marketplace take ownership of the listed items,
/// @dev avoid having to check if item is sold on external marketplaces
contract MarketplaceV2 is HSystemChecker, Multicall {

    bytes32 constant MILK_WALLET_BYTES = keccak256("MILK_WALLET");

    IItemFactory _itemFactory;
    IMarketVault _marketVault;
    address public _itemFactoryContractAddress;
    address public _treasuryContractAddress;
    address public _marketVaultContractAddress;

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

    /// @notice Emitted when a new listing is created
    /// @param listingId - Listing id of new listing
    /// @param seller - Address of seller/owner of tokens
    /// @param tokenId - Token id of item listed
    /// @param amount - Amount of tokenId listed
    /// @param price - Price of item in wei
    /// @param priceWithFee - Price of listing in wei
    event LogNewListing(uint256 listingId, address seller, uint256 tokenId, uint256 amount, uint256 price, uint256 priceWithFee);

    /// @notice Emitted when a listing is removed
    /// @param listingId - Listing id being deactivated
    /// @param seller - Address of the seller
    /// @param isSale - flag to identify if listing was removed from a sale or delist
    event LogRemoveListing(uint256 listingId, address seller, bool isSale);

    /// @notice Emitted when a listing is purchased
    /// @param listingId - Listing id being deactivated
    /// @param seller - Address of the seller
    /// @param buyer - Address of the buyer
    event LogPurchase(uint256 listingId, address seller, address buyer);

    /// @notice Emitted when a new fee is set
    /// @param feeBp - New fee set
    event LogSetFee(uint256 feeBp);

    /// @notice Emitted when the Item Factory contract address is updated
    /// @param itemFactoryContractAddress - Item Factory contract address
    event LogSetItemFactoryAddress(address itemFactoryContractAddress);

    /// @notice Emitted when the Treasury contract address is updated
    /// @param marketVaultContractAddress - Market Vault contract address
    event LogSetMarketVaultContractAddress(address marketVaultContractAddress);

    /// @notice Emitted when the Treasury contract address is updated
    /// @param treasuryContractAddress - Treasury contract address
    event LogSetTreasuryContractAddress(address treasuryContractAddress);

    constructor(
        address systemCheckerContractAddress,
        address treasuryContractAddress,
        address itemFactoryContractAddress,
        address marketVaultContractAddress
    ) HSystemChecker(systemCheckerContractAddress) {
        _itemFactoryContractAddress = itemFactoryContractAddress;
        _itemFactory = IItemFactory(itemFactoryContractAddress);

        _treasuryContractAddress = treasuryContractAddress;

        _marketVaultContractAddress = marketVaultContractAddress;
        _marketVault = IMarketVault(marketVaultContractAddress);
    }

    /// @notice Check that a listing exists
    /// @param listingId - Identifier for the desired listing
    modifier listingExists(uint256 listingId) {
        require(_listingSet.exists(bytes32(listingId)), "MP 400 - Listing does not exist.");
        _;
    }

    /// @notice Creates a new listing
    /// @dev This can only be sent from the system
    /// @dev gameSafeTransfer() handles isUser()
    /// @param tokenId - Token id of item to list
    /// @param amount - Amount of tokenId to list
    /// @param price - Desired price to list in wei
    /// @param seller - Address of seller/owner of tokens
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
        _itemFactory.gameSafeTransferFrom(seller, _marketVaultContractAddress, tokenId, amount, "");

        // Handle token moving to vault
        _marketVault.tokenIn(seller, tokenId, amount);

        // price with fee's max uint104 value is checked in _setListing
        emit LogNewListing(_listingId++, seller, tokenId, amount, price, price + ((price * _saleFeeBp) / 10000));
        // increase _listingId by 1
    }

    /// @notice Handles data packing for a listing
    /// @param listingIdBytes - bytes32 of listing id
    /// @param seller - Address of seller
    /// @param listingId - Id of listing
    /// @param tokenId - Token id of item to list
    /// @param amount - Amount of tokenId to list
    /// @param listingTime - Time listing was created
    /// @param price - MILK price in wei
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
        require(amount > 0, "MP 410 - Invalid listing quantity");
        require(amount < 4294967296, "MP 403 - Amount to sell exceeds max of uint32.");
        require(listingTime < 28147497671066, "MP 404 - Listing time exceeds max of uint48.");
        require(price > 0, "MP 408 - Invalid listing price");
        require((price + ((price * _saleFeeBp) / 10000)) <= type(uint104).max, "MP 405 - Price exceeds max of uint104.");

        uint256 listing = uint256(uint160(seller));
        //uint160
        listing |= listingId << 160;
        //uint48
        listing |= tokenId << 208;
        //uint16
        listing |= amount << 224;
        //uint32
        _listingData[listingIdBytes] = listing;

        uint256 pricing = uint256(price);
        //uint104
        pricing |= (price + ((price * _saleFeeBp) / 10000)) << 104;
        //uint104
        pricing |= listingTime << 208;
        //uint48
        _listingPrices[listingIdBytes] = pricing;
    }

    /// @notice Get the listing by uint256 listing id
    /// @dev Takes listingId in uint256 and calls internal getListing(bytes32)
    /// @param listingId - Id of listing
    /// @return listing - Listing struct
    function getListing(uint256 listingId) external view listingExists(listingId) returns (ListingStruct memory) {
        //takes the uint256 of listing id and returns the bytes
        return _getListing(bytes32(listingId));
    }

    /// @notice Get the listing by listing id in bytes32
    /// @dev This can only be sent from the system
    /// @param listingIdBytes - Id of listing in bytes
    /// @return itemListing - Listing struct
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
    /// @return listingIds_ - Array of listing ids
    function getListingIds() public view returns (bytes32[] memory) {
        return _listingSet.keyList;
    }

    /// @notice Deletes an existing listing struct, meant for removing listing without a sale
    /// @dev This can only be sent from the system
    /// @dev _removeListing checks if listing exists
    /// @dev Called when removing a listing, safeTransferFrom returns item to seller
    /// @param listingId - Listing id to deactivate
    /// @param seller - Address of the seller
    function removeListing(uint256 listingId, address seller) public onlyRole(GAME_ROLE) isUser(seller) {
        bytes32 listingIdBytes = bytes32(listingId);

        ListingStruct memory li = _getListing(listingIdBytes);

        require(li.seller == seller, "MP 406 - Not the seller.");

        // Handle token to original seller
        _marketVault.tokenOut(li.seller, li.seller, li.tokenId, li.amount);

        // remove listing that is being delisted and not sold, pass false for isSale
        _removeListing(listingId, li.seller, false);
    }

    /// @notice Deletes an existing listing struct, meant for removing listing without a sale
    /// @dev This can only be sent from the system
    /// @dev Has modifier to check if listing exists
    /// @dev Called when removing a listing after being sold, safeTransferFrom to transfer token from game to buyer is called in the buying function
    /// @param listingId - Listing id to deactivate
    /// @param seller - Address of the seller
    /// @param isSale - Flag to identify if listing was removed from a sale or delist
    function _removeListing(uint256 listingId, address seller, bool isSale) internal {
        bytes32 listingIdBytes = bytes32(listingId);

        // emit before required data is deleted
        emit LogRemoveListing(listingId, seller, isSale);

        // update listing trackers
        _listingSet.remove(listingIdBytes);

        delete _listingData[listingIdBytes];
        delete _listingPrices[listingIdBytes];
    }

    /// @notice Buys a listing's offering
    /// @dev This can only be sent from the system
    /// @dev gameSafeTransfer() handles isUser()
    /// @dev listingExists() check is handled by _removeListing
    /// @param buyer - Address of buyer
    /// @param listingId - Id of listing
    function buyListing(address buyer, uint256 listingId) public onlyRole(GAME_ROLE) isUser(buyer) {
        ITreasury treasury = ITreasury(_treasuryContractAddress);

        // create a temporary listing struct to reference
        ListingStruct memory li = _getListing(bytes32(listingId));

        // remove listing that is purchased, pass true for isSale
        _removeListing(listingId, li.seller, true);

        // Handle token to the new owner
        _marketVault.tokenOut(li.seller, buyer, li.tokenId, li.amount);

        // transfer milk of buyer to seller at seller's desired price through treasury
        treasury.transferFrom(buyer, li.seller, li.price);

        // transfer milk of buyer to MILK_WALLET at fee price (listingPrice - price) through treasury
        treasury.transferFrom(buyer, _systemChecker.getSafeAddress(MILK_WALLET_BYTES), li.listedPrice - li.price);

        emit LogPurchase(listingId, li.seller, buyer);
    }

    /// @notice Set the transaction fee desired for subsequent new listings
    /// @dev This can only be sent from the system
    /// @dev 500 = 5%
    /// @param feeBp - Desired fee basis point
    function setFee(uint256 feeBp) external onlyRole(ADMIN_ROLE) {
        require(feeBp <= 10000, "MP 407 - Don't be greedy.");
        _saleFeeBp = feeBp;
        emit LogSetFee(feeBp);
    }

    /// @notice Push new address for the Treasury Contract
    /// @param treasuryContractAddress - Address of the Item Factory
    function setTreasuryContractAddress(address treasuryContractAddress) external onlyRole(ADMIN_ROLE) {
        _treasuryContractAddress = treasuryContractAddress;
        emit LogSetTreasuryContractAddress(treasuryContractAddress);
    }

    /// @notice Push new address for the Market Vault Contract
    /// @param marketVaultContractAddress - Address of the Market Vault
    function setMarketVaultContractAddress(address marketVaultContractAddress) external onlyRole(ADMIN_ROLE) {
        _marketVaultContractAddress = marketVaultContractAddress;
        _marketVault = IMarketVault(marketVaultContractAddress);
        emit LogSetMarketVaultContractAddress(marketVaultContractAddress);
    }

    /// @notice Push new address for the Item Factory Contract
    /// @param itemFactoryContractAddress - Address of the Item Factory
    function setItemFactoryContractAddress(address itemFactoryContractAddress) external onlyRole(ADMIN_ROLE) {
        _itemFactoryContractAddress = itemFactoryContractAddress;
        _itemFactory = IItemFactory(itemFactoryContractAddress);
        emit LogSetItemFactoryAddress(itemFactoryContractAddress);
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
        if (rowToReplace != last) {
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

    function gameSafeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;

    function getItemById(uint256 itemTokenId) external returns (bytes32 categoryKey, bytes32 typeKey);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketVault {
    function tokenIn(address from, uint256 tokenId, uint256 amount) external;

    function tokenOut(address from, address to, uint256 tokenId, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IMulticall.sol';

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /**
      * @dev mostly lifted from https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringBatchable.sol
      */
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
        // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
        // All that remains is the revert string
    }

    /**
      * @inheritdoc IMulticall
      * @dev does a basic multicall to any function on this contract
      */
    function multicall(bytes[] calldata data, bool revertOnFail)
    external payable override
    returns (bytes[] memory returning)
    {
        returning = new bytes[](data.length);
        bool success;
        bytes memory result;
        for (uint256 i = 0; i < data.length; i++) {
            (success, result) = address(this).delegatecall(data[i]);

            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }
            returning[i] = result;
        }
    }
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

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data, bool revertOnFail) external payable returns (bytes[] memory results);
}