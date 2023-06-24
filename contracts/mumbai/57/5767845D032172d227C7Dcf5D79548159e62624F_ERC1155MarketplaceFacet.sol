// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibERC1155Marketplace, ERC1155Listing} from "../libraries/LibERC1155Marketplace.sol";
import {IERC20} from "../../shared/interfaces/IERC20.sol";
import {IERC1155} from "../../shared/interfaces/IERC1155.sol";
import {LibMeta} from "../../shared/libraries/LibMeta.sol";
import {LibItems} from "../libraries/LibItems.sol";
import {LibERC1155} from "../../shared/libraries/LibERC1155.sol";
import "../WearableDiamond/interfaces/IEventHandlerFacet.sol";
import {BaazaarSplit, LibSharedMarketplace, SplitAddresses} from "../libraries/LibSharedMarketplace.sol";

contract ERC1155MarketplaceFacet is Modifiers {
    event ERC1155ListingAdd(
        uint256 indexed listingId,
        address indexed seller,
        address erc1155TokenAddress,
        uint256 erc1155TypeId,
        uint256 indexed category,
        uint256 quantity,
        uint256 priceInWei,
        uint256 time
    );

    event ERC1155ListingSplit(uint256 indexed listingId, uint16[2] principalSplit, address affiliate);
    event ERC1155ListingWhitelistSet(uint256 indexed listingId, uint32 whitelistId);

    event ERC1155ExecutedListing(
        uint256 indexed listingId,
        address indexed seller,
        address buyer,
        address erc1155TokenAddress,
        uint256 erc1155TypeId,
        uint256 indexed category,
        uint256 _quantity,
        uint256 priceInWei,
        uint256 time
    );

    ///@dev Is sent in tandem with ERC1155ExecutedListing
    event ERC1155ExecutedToRecipient(uint256 indexed listingId, address indexed buyer, address indexed recipient);

    event ERC1155ListingCancelled(uint256 indexed listingId);

    event ChangedListingFee(uint256 listingFeeInWei);

    ///@notice Allow the aavegotchi diamond owner or DAO to set the default listing fee
    ///@param _listingFeeInWei The new listing fee in wei
    function setListingFee(uint256 _listingFeeInWei) external onlyDaoOrOwner {
        s.listingFeeInWei = _listingFeeInWei;
        emit ChangedListingFee(s.listingFeeInWei);
    }

    struct Category {
        address erc1155TokenAddress;
        uint256 erc1155TypeId;
        uint256 category;
    }

    ///@notice Allow the aavegotchi diamond owner or DAO to set the category details for multiple ERC1155 NFTs
    ///@param _categories An array of structs where each struct contains details about each ERC1155 item //erc1155TokenAddress,erc1155TypeId and category
    function setERC1155Categories(Category[] calldata _categories) external onlyItemManager {
        for (uint256 i; i < _categories.length; i++) {
            s.erc1155Categories[_categories[i].erc1155TokenAddress][_categories[i].erc1155TypeId] = _categories[i].category;
        }
    }

    ///@notice Query the category details of a ERC1155 NFT
    ///@param _erc1155TokenAddress Contract address of NFT to query
    ///@param _erc1155TypeId Identifier of the NFT to query
    ///@return category_ Category of the NFT // 0 is wearable, 1 is badge, 2 is consumable, 3 is tickets
    function getERC1155Category(address _erc1155TokenAddress, uint256 _erc1155TypeId) public view returns (uint256 category_) {
        if (_erc1155TokenAddress == s.forgeDiamond && _erc1155TypeId < 1_000_000_000) {
            //Schematics are always supported to trade, so long as the wearable exists
            //Schematic IDs are under 1_000_000_000 offset.
            category_ = 7;
            require(s.itemTypes[_erc1155TypeId].maxQuantity > 0, "ERC1155Marketplace: erc1155 item not supported");
        } else {
            category_ = s.erc1155Categories[_erc1155TokenAddress][_erc1155TypeId];
        }

        if (category_ == 0) {
            require(
                _erc1155TokenAddress == address(this) && s.itemTypes[_erc1155TypeId].maxQuantity > 0,
                "ERC1155Marketplace: erc1155 item not supported"
            );
        }
    }

    ///@notice Allow an ERC1155 owner to list his NFTs for sale
    ///@dev If an NFT has been listed before,it cancels it and replaces it with the new one
    ///@param _erc1155TokenAddress The contract address of the NFT to be listed
    ///@param _erc1155TypeId The identifier of the NFT to be listed
    ///@param _quantity The amount of NFTs to be listed
    ///@param _priceInWei The cost price of the NFT individually in $GHST
    function setERC1155Listing(address _erc1155TokenAddress, uint256 _erc1155TypeId, uint256 _quantity, uint256 _priceInWei) external {
        createERC1155Listing(_erc1155TokenAddress, _erc1155TypeId, _quantity, _priceInWei, [10000, 0], address(0), 0);
    }

    function setERC1155ListingWithSplit(
        address _erc1155TokenAddress,
        uint256 _erc1155TypeId,
        uint256 _quantity,
        uint256 _priceInWei,
        uint16[2] memory _principalSplit,
        address _affiliate
    ) external {
        createERC1155Listing(_erc1155TokenAddress, _erc1155TypeId, _quantity, _priceInWei, _principalSplit, _affiliate, 0);
    }

    //@dev Not implemented in UI yet. Do not use unless you don't want anyone purchasing your NFT.

    function setERC1155ListingWithWhitelist(
        address _erc1155TokenAddress,
        uint256 _erc1155TypeId,
        uint256 _quantity,
        uint256 _priceInWei,
        uint16[2] memory _principalSplit,
        address _affiliate,
        uint32 _whitelistId
    ) external {
        createERC1155Listing(_erc1155TokenAddress, _erc1155TypeId, _quantity, _priceInWei, _principalSplit, _affiliate, _whitelistId);
    }

    function createERC1155Listing(
        address _erc1155TokenAddress,
        uint256 _erc1155TypeId,
        uint256 _quantity,
        uint256 _priceInWei,
        uint16[2] memory _principalSplit,
        address _affiliate,
        uint32 _whitelistId
    ) internal {
        address seller = LibMeta.msgSender();
        uint256 category = getERC1155Category(_erc1155TokenAddress, _erc1155TypeId);

        IERC1155 erc1155Token = IERC1155(_erc1155TokenAddress);
        require(erc1155Token.balanceOf(seller, _erc1155TypeId) >= _quantity, "ERC1155Marketplace: Not enough ERC1155 token");
        require(
            _erc1155TokenAddress == address(this) || erc1155Token.isApprovedForAll(seller, address(this)),
            "ERC1155Marketplace: Not approved for transfer"
        );

        uint256 cost = _quantity * _priceInWei;
        require(cost >= 1e18, "ERC1155Marketplace: cost should be 1 GHST or larger");
        require(_principalSplit[0] + _principalSplit[1] == 10000, "ERC1155Marketplace: Sum of principal splits not 10000");
        if (_affiliate == address(0)) {
            require(_principalSplit[1] == 0, "ERC1155Marketplace: Affiliate split must be 0 for address(0)");
        }

        uint256 listingId = s.erc1155TokenToListingId[_erc1155TokenAddress][_erc1155TypeId][seller];
        if (listingId == 0) {
            s.nextERC1155ListingId++;
            listingId = s.nextERC1155ListingId;
            s.erc1155TokenToListingId[_erc1155TokenAddress][_erc1155TypeId][seller] = listingId;
            s.erc1155Listings[listingId] = ERC1155Listing({
                listingId: listingId,
                seller: seller,
                erc1155TokenAddress: _erc1155TokenAddress,
                erc1155TypeId: _erc1155TypeId,
                category: category,
                quantity: _quantity,
                priceInWei: _priceInWei,
                timeCreated: block.timestamp,
                timeLastPurchased: 0,
                sourceListingId: 0,
                sold: false,
                cancelled: false,
                principalSplit: _principalSplit,
                affiliate: _affiliate,
                whitelistId: _whitelistId
            });
            LibERC1155Marketplace.addERC1155ListingItem(seller, category, "listed", listingId);

            emit ERC1155ListingAdd(listingId, seller, _erc1155TokenAddress, _erc1155TypeId, category, _quantity, _priceInWei, block.timestamp);

            if (_affiliate != address(0)) {
                emit ERC1155ListingSplit(listingId, _principalSplit, _affiliate);
            }
            if (_whitelistId != 0) {
                emit ERC1155ListingWhitelistSet(listingId, _whitelistId);
            }
        } else {
            ERC1155Listing storage listing = s.erc1155Listings[listingId];
            listing.quantity = _quantity;
            emit LibERC1155Marketplace.UpdateERC1155Listing(listingId, _quantity, listing.priceInWei, block.timestamp);
        }

        //Burn listing fee
        if (s.listingFeeInWei > 0) {
            LibSharedMarketplace.burnListingFee(s.listingFeeInWei, LibMeta.msgSender(), s.ghstContract);
        }
    }

    ///@notice Allow an ERC1155 owner to cancel his NFT listing through the listingID
    ///@param _listingId The identifier of the listing to be cancelled

    function cancelERC1155Listing(uint256 _listingId) external {
        LibERC1155Marketplace.cancelERC1155Listing(_listingId, LibMeta.msgSender());
    }

    ///@notice Allow a buyer to execcute an open listing i.e buy the NFT
    ///@dev Will throw if the NFT has been sold or if the listing has been cancelled already
    ///@dev Will be deprecated soon.
    ///@param _listingId The identifier of the listing to execute
    ///@param _quantity The amount of ERC1155 NFTs execute/buy
    ///@param _priceInWei the cost price of the ERC1155 NFTs individually
    function executeERC1155Listing(uint256 _listingId, uint256 _quantity, uint256 _priceInWei) external {
        ERC1155Listing storage listing = s.erc1155Listings[_listingId];
        handleExecuteERC1155Listing(_listingId, listing.erc1155TokenAddress, listing.erc1155TypeId, _quantity, _priceInWei, LibMeta.msgSender());
    }

    ///@notice Allow a buyer to execcute an open listing i.e buy the NFT on behalf of the recipient. Also checks to ensure the item details match the listing.
    ///@dev Will throw if the NFT has been sold or if the listing has been cancelled already
    ///@param _listingId The identifier of the listing to execute
    ///@param _contractAddress The token contract address
    ///@param _itemId the erc1155 token id
    ///@param _quantity The amount of ERC1155 NFTs execute/buy
    ///@param _priceInWei the cost price of the ERC1155 NFTs individually
    ///@param _recipient the recipient of the item
    function executeERC1155ListingToRecipient(
        uint256 _listingId,
        address _contractAddress,
        uint256 _itemId,
        uint256 _quantity,
        uint256 _priceInWei,
        address _recipient
    ) external {
        handleExecuteERC1155Listing(_listingId, _contractAddress, _itemId, _quantity, _priceInWei, _recipient);
    }

    ///@param listingId The identifier of the listing to execute
    ///@param contractAddress The token contract address
    ///@param itemId the erc1155 token id
    ///@param quantity The amount of ERC1155 NFTs execute/buy
    ///@param priceInWei The price of the item
    ///@param recipient The address to receive the NFT
    struct ExecuteERC1155ListingParams {
        uint256 listingId;
        address contractAddress;
        uint256 itemId;
        uint256 quantity;
        uint256 priceInWei;
        address recipient;
    }

    ///@notice execute ERC1155 listings in batch
    function batchExecuteERC1155Listing(ExecuteERC1155ListingParams[] calldata listings) external {
        require(listings.length <= 10, "ERC1155Marketplace: length should be lower than 10");
        for (uint256 i = 0; i < listings.length; i++) {
            handleExecuteERC1155Listing(
                listings[i].listingId,
                listings[i].contractAddress,
                listings[i].itemId,
                listings[i].quantity,
                listings[i].priceInWei,
                listings[i].recipient
            );
        }
    }

    function handleExecuteERC1155Listing(
        uint256 _listingId,
        address _contractAddress,
        uint256 _itemId,
        uint256 _quantity,
        uint256 _priceInWei,
        address _recipient
    ) internal {
        ERC1155Listing storage listing = s.erc1155Listings[_listingId];
        require(listing.timeCreated != 0, "ERC1155Marketplace: listing not found");
        require(listing.sold == false, "ERC1155Marketplace: listing is sold out");
        require(listing.cancelled == false, "ERC1155Marketplace: listing is cancelled");
        require(_priceInWei == listing.priceInWei, "ERC1155Marketplace: wrong price or price changed");
        require(listing.erc1155TokenAddress == _contractAddress, "ERC1155Marketplace: Incorrect token address");
        require(listing.erc1155TypeId == _itemId, "ERC1155Marketplace: Incorrect token id");
        address buyer = LibMeta.msgSender();
        address seller = listing.seller;
        require(seller != buyer, "ERC1155Marketplace: buyer can't be seller");
        if (listing.whitelistId > 0) {
            require(s.isWhitelisted[listing.whitelistId][buyer] > 0, "ERC1155Marketplace: Not whitelisted address");
        }
        require(_quantity > 0, "ERC1155Marketplace: _quantity can't be zero");
        require(_quantity <= listing.quantity, "ERC1155Marketplace: quantity is greater than listing");
        listing.quantity -= _quantity;
        uint256 cost = _quantity * _priceInWei;
        require(IERC20(s.ghstContract).balanceOf(buyer) >= cost, "ERC1155Marketplace: not enough GHST");
        {
            BaazaarSplit memory split = LibSharedMarketplace.getBaazaarSplit(
                cost,
                new uint256[](0),
                listing.affiliate == address(0) ? [10000, 0] : listing.principalSplit
            );

            LibSharedMarketplace.transferSales(
                SplitAddresses({
                    ghstContract: s.ghstContract,
                    buyer: buyer,
                    seller: seller,
                    affiliate: listing.affiliate,
                    royalties: new address[](0),
                    daoTreasury: s.daoTreasury,
                    pixelCraft: s.pixelCraft,
                    rarityFarming: s.rarityFarming
                }),
                split
            );

            listing.timeLastPurchased = block.timestamp;
            s.nextERC1155ListingId++;
            uint256 purchaseListingId = s.nextERC1155ListingId;
            s.erc1155Listings[purchaseListingId] = ERC1155Listing({
                listingId: purchaseListingId,
                seller: seller,
                erc1155TokenAddress: listing.erc1155TokenAddress,
                erc1155TypeId: listing.erc1155TypeId,
                category: listing.category,
                quantity: _quantity,
                priceInWei: _priceInWei,
                timeCreated: block.timestamp,
                timeLastPurchased: block.timestamp,
                sourceListingId: _listingId,
                sold: true,
                cancelled: false,
                principalSplit: listing.principalSplit,
                affiliate: listing.affiliate,
                whitelistId: listing.whitelistId
            });
            LibERC1155Marketplace.addERC1155ListingItem(seller, listing.category, "purchased", purchaseListingId);
            if (listing.quantity == 0) {
                listing.sold = true;
                LibERC1155Marketplace.removeERC1155ListingItem(_listingId, seller);
            }
        }
        // Have to call it like this because LibMeta.msgSender() gets in the way
        if (listing.erc1155TokenAddress == address(this)) {
            LibItems.removeFromOwner(seller, listing.erc1155TypeId, _quantity);
            LibItems.addToOwner(_recipient, listing.erc1155TypeId, _quantity);
            IEventHandlerFacet(s.wearableDiamond).emitTransferSingleEvent(address(this), seller, _recipient, listing.erc1155TypeId, _quantity);
            LibERC1155.onERC1155Received(address(this), seller, _recipient, listing.erc1155TypeId, _quantity, "");
        } else {
            // GHSTStakingDiamond
            IERC1155(listing.erc1155TokenAddress).safeTransferFrom(seller, _recipient, listing.erc1155TypeId, _quantity, new bytes(0));
        }
        emit ERC1155ExecutedListing(
            _listingId,
            seller,
            _recipient,
            listing.erc1155TokenAddress,
            listing.erc1155TypeId,
            listing.category,
            _quantity,
            listing.priceInWei,
            block.timestamp
        );

        //Only emit if buyer is not recipient
        if (buyer != _recipient) {
            emit ERC1155ExecutedToRecipient(_listingId, buyer, _recipient);
        }
    }

    ///@notice Update the ERC1155 listing of an address
    ///@param _erc1155TokenAddress Contract address of the ERC1155 token
    ///@param _erc1155TypeId Identifier of the ERC1155 token
    ///@param _owner Owner of the ERC1155 token
    function updateERC1155Listing(address _erc1155TokenAddress, uint256 _erc1155TypeId, address _owner) external {
        LibERC1155Marketplace.updateERC1155Listing(_erc1155TokenAddress, _erc1155TypeId, _owner);
    }

    ///@notice Update the ERC1155 listings of an address
    ///@param _erc1155TokenAddress Contract address of the ERC1155 token
    ///@param _erc1155TypeIds An array containing the identifiers of the ERC1155 tokens to update
    ///@param _owner Owner of the ERC1155 tokens
    function updateBatchERC1155Listing(address _erc1155TokenAddress, uint256[] calldata _erc1155TypeIds, address _owner) external {
        for (uint256 i; i < _erc1155TypeIds.length; i++) {
            LibERC1155Marketplace.updateERC1155Listing(_erc1155TokenAddress, _erc1155TypeIds[i], _owner);
        }
    }

    ///@notice Allow an ERC1155 owner to cancel his NFT listings through the listingIDs
    ///@param _listingIds An array containing the identifiers of the listings to be cancelled
    function cancelERC1155Listings(uint256[] calldata _listingIds) external onlyOwner {
        for (uint256 i; i < _listingIds.length; i++) {
            uint256 listingId = _listingIds[i];

            ERC1155Listing storage listing = s.erc1155Listings[listingId];
            if (listing.cancelled == true || listing.sold == true) {
                return;
            }
            listing.cancelled = true;
            emit LibERC1155Marketplace.ERC1155ListingCancelled(listingId, listing.category, block.number);
            LibERC1155Marketplace.removeERC1155ListingItem(listingId, listing.seller);
        }
    }

    ///@notice Allow an ERC1155 owner to update list price of his NFT for sale
    ///@dev If the NFT has not been listed before, it will be rejected
    ///@param _listingId The identifier of the listing to execute
    ///@param _quantity The amount of ERC1155 NFTs execute/buy
    ///@param _priceInWei The price of the item
    function updateERC1155ListingPriceAndQuantity(uint256 _listingId, uint256 _quantity, uint256 _priceInWei) external {
        LibERC1155Marketplace.updateERC1155ListingPriceAndQuantity(_listingId, _quantity, _priceInWei);
        if (s.listingFeeInWei > 0) {
            LibSharedMarketplace.burnListingFee(s.listingFeeInWei, LibMeta.msgSender(), s.ghstContract);
        }
    }

    function batchUpdateERC1155ListingPriceAndQuantity(
        uint256[] calldata _listingIds,
        uint256[] calldata _quantities,
        uint256[] calldata _priceInWeis
    ) external {
        require(_listingIds.length == _quantities.length, "ERC1155Marketplace: listing ids not same length as quantities");
        require(_listingIds.length == _priceInWeis.length, "ERC1155Marketplace: listing ids not same length as prices");

        for (uint256 i; i < _listingIds.length; i++) {
            LibERC1155Marketplace.updateERC1155ListingPriceAndQuantity(_listingIds[i], _quantities[i], _priceInWeis[i]);
        }

        if (s.listingFeeInWei > 0) {
            uint256 totalFee = s.listingFeeInWei * _listingIds.length;
            LibSharedMarketplace.burnListingFee(totalFee, LibMeta.msgSender(), s.ghstContract);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

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
pragma solidity 0.8.1;
import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import {LibMeta} from "../../shared/libraries/LibMeta.sol";
import {ILink} from "../interfaces/ILink.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

uint256 constant EQUIPPED_WEARABLE_SLOTS = 16;
uint256 constant NUMERIC_TRAITS_NUM = 6;
uint256 constant TRAIT_BONUSES_NUM = 5;
uint256 constant PORTAL_AAVEGOTCHIS_NUM = 10;

//  switch (traitType) {
//         case 0:
//             return energy(value);
//         case 1:
//             return aggressiveness(value);
//         case 2:
//             return spookiness(value);
//         case 3:
//             return brain(value);
//         case 4:
//             return eyeShape(value);
//         case 5:
//             return eyeColor(value);

struct Aavegotchi {
    uint16[EQUIPPED_WEARABLE_SLOTS] equippedWearables; //The currently equipped wearables of the Aavegotchi
    // [Experience, Rarity Score, Kinship, Eye Color, Eye Shape, Brain Size, Spookiness, Aggressiveness, Energy]
    int8[NUMERIC_TRAITS_NUM] temporaryTraitBoosts;
    int16[NUMERIC_TRAITS_NUM] numericTraits; // Sixteen 16 bit ints.  [Eye Color, Eye Shape, Brain Size, Spookiness, Aggressiveness, Energy]
    string name;
    uint256 randomNumber;
    uint256 experience; //How much XP this Aavegotchi has accrued. Begins at 0.
    uint256 minimumStake; //The minimum amount of collateral that must be staked. Set upon creation.
    uint256 usedSkillPoints; //The number of skill points this aavegotchi has already used
    uint256 interactionCount; //How many times the owner of this Aavegotchi has interacted with it.
    address collateralType;
    uint40 claimTime; //The block timestamp when this Aavegotchi was claimed
    uint40 lastTemporaryBoost;
    uint16 hauntId;
    address owner;
    uint8 status; // 0 == portal, 1 == VRF_PENDING, 2 == open portal, 3 == Aavegotchi
    uint40 lastInteracted; //The last time this Aavegotchi was interacted with
    bool locked;
    address escrow; //The escrow address this Aavegotchi manages.
}

struct Dimensions {
    uint8 x;
    uint8 y;
    uint8 width;
    uint8 height;
}

struct ItemType {
    string name; //The name of the item
    string description;
    string author;
    // treated as int8s array
    // [Experience, Rarity Score, Kinship, Eye Color, Eye Shape, Brain Size, Spookiness, Aggressiveness, Energy]
    int8[NUMERIC_TRAITS_NUM] traitModifiers; //[WEARABLE ONLY] How much the wearable modifies each trait. Should not be more than +-5 total
    //[WEARABLE ONLY] The slots that this wearable can be added to.
    bool[EQUIPPED_WEARABLE_SLOTS] slotPositions;
    // this is an array of uint indexes into the collateralTypes array
    uint8[] allowedCollaterals; //[WEARABLE ONLY] The collaterals this wearable can be equipped to. An empty array is "any"
    // SVG x,y,width,height
    Dimensions dimensions;
    uint256 ghstPrice; //How much GHST this item costs
    uint256 maxQuantity; //Total number that can be minted of this item.
    uint256 totalQuantity; //The total quantity of this item minted so far
    uint32 svgId; //The svgId of the item
    uint8 rarityScoreModifier; //Number from 1-50.
    // Each bit is a slot position. 1 is true, 0 is false
    bool canPurchaseWithGhst;
    uint16 minLevel; //The minimum Aavegotchi level required to use this item. Default is 1.
    bool canBeTransferred;
    uint8 category; // 0 is wearable, 1 is badge, 2 is consumable
    int16 kinshipBonus; //[CONSUMABLE ONLY] How much this consumable boosts (or reduces) kinship score
    uint32 experienceBonus; //[CONSUMABLE ONLY]
}

struct WearableSet {
    string name;
    uint8[] allowedCollaterals;
    uint16[] wearableIds; // The tokenIdS of each piece of the set
    int8[TRAIT_BONUSES_NUM] traitsBonuses;
}

struct Haunt {
    uint256 hauntMaxSize; //The max size of the Haunt
    uint256 portalPrice;
    bytes3 bodyColor;
    uint24 totalCount;
}

struct SvgLayer {
    address svgLayersContract;
    uint16 offset;
    uint16 size;
}

struct AavegotchiCollateralTypeInfo {
    // treated as an arary of int8
    int16[NUMERIC_TRAITS_NUM] modifiers; //Trait modifiers for each collateral. Can be 2, 1, -1, or -2
    bytes3 primaryColor;
    bytes3 secondaryColor;
    bytes3 cheekColor;
    uint8 svgId;
    uint8 eyeShapeSvgId;
    uint16 conversionRate; //Current conversionRate for the price of this collateral in relation to 1 USD. Can be updated by the DAO
    bool delisted;
}

struct ERC1155Listing {
    uint256 listingId;
    address seller;
    address erc1155TokenAddress;
    uint256 erc1155TypeId;
    uint256 category; // 0 is wearable, 1 is badge, 2 is consumable, 3 is tickets
    uint256 quantity;
    uint256 priceInWei;
    uint256 timeCreated;
    uint256 timeLastPurchased;
    uint256 sourceListingId;
    bool sold;
    bool cancelled;
    //new:
    uint16[2] principalSplit;
    address affiliate;
    uint32 whitelistId;
}

struct ERC721Listing {
    uint256 listingId;
    address seller;
    address erc721TokenAddress;
    uint256 erc721TokenId;
    uint256 category; // 0 is closed portal, 1 is vrf pending, 2 is open portal, 3 is Aavegotchi
    uint256 priceInWei;
    uint256 timeCreated;
    uint256 timePurchased;
    bool cancelled;
    //new:
    uint16[2] principalSplit;
    address affiliate;
    uint32 whitelistId;
}

struct ListingListItem {
    uint256 parentListingId;
    uint256 listingId;
    uint256 childListingId;
}

struct GameManager {
    uint256 limit;
    uint256 balance;
    uint256 refreshTime;
}

struct GotchiLending {
    // storage slot 1
    address lender;
    uint96 initialCost; // GHST in wei, can be zero
    // storage slot 2
    address borrower;
    uint32 listingId;
    uint32 erc721TokenId;
    uint32 whitelistId; // can be zero
    // storage slot 3
    address originalOwner; // if original owner is lender, same as lender
    uint40 timeCreated;
    uint40 timeAgreed;
    bool canceled;
    bool completed;
    // storage slot 4
    address thirdParty; // can be address(0)
    uint8[3] revenueSplit; // lender/original owner, borrower, thirdParty
    uint40 lastClaimed; //timestamp
    uint32 period; //in seconds
    // storage slot 5
    address[] revenueTokens;
    //storage slot 6
    //this is a bitmap value that packs all the permissions of a listing into a single uint256
    //each index represents a permission, therefore 32 indexes,== 32 possible permissions
    //index 0 means no permission by default
    //indexes can store up to 256 values (0-255), each value representing a modifer for that permission, but we only use 0-9
    uint256 permissions; //0=none, 1=channelling
}

struct LendingListItem {
    uint32 parentListingId;
    uint256 listingId;
    uint32 childListingId;
}

struct Whitelist {
    address owner;
    string name;
    address[] addresses;
}

struct XPMerkleDrops {
    bytes32 root;
    uint256 xpAmount; //10-sigprop, 20-coreprop
}

struct ERC721BuyOrder {
    uint256 buyOrderId;
    address buyer;
    address erc721TokenAddress;
    uint256 erc721TokenId;
    uint256 priceInWei;
    uint256 timeCreated;
    uint256 timePurchased;
    uint256 duration; //0 for unlimited
    bool cancelled;
    bytes32 validationHash;
    bool[] validationOptions;
}

struct AppStorage {
    mapping(address => AavegotchiCollateralTypeInfo) collateralTypeInfo;
    mapping(address => uint256) collateralTypeIndexes;
    mapping(bytes32 => SvgLayer[]) svgLayers;
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) nftItemBalances;
    mapping(address => mapping(uint256 => uint256[])) nftItems;
    // indexes are stored 1 higher so that 0 means no items in items array
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) nftItemIndexes;
    ItemType[] itemTypes;
    WearableSet[] wearableSets;
    mapping(uint256 => Haunt) haunts;
    mapping(address => mapping(uint256 => uint256)) ownerItemBalances;
    mapping(address => uint256[]) ownerItems;
    // indexes are stored 1 higher so that 0 means no items in items array
    mapping(address => mapping(uint256 => uint256)) ownerItemIndexes;
    mapping(uint256 => uint256) tokenIdToRandomNumber;
    mapping(uint256 => Aavegotchi) aavegotchis;
    mapping(address => uint32[]) ownerTokenIds;
    mapping(address => mapping(uint256 => uint256)) ownerTokenIdIndexes;
    uint32[] tokenIds;
    mapping(uint256 => uint256) tokenIdIndexes;
    mapping(address => mapping(address => bool)) operators;
    mapping(uint256 => address) approved;
    mapping(string => bool) aavegotchiNamesUsed;
    mapping(address => uint256) metaNonces;
    uint32 tokenIdCounter;
    uint16 currentHauntId;
    string name;
    string symbol;
    //Addresses
    address[] collateralTypes;
    address ghstContract;
    address childChainManager;
    address gameManager;
    address dao;
    address daoTreasury;
    address pixelCraft;
    address rarityFarming;
    string itemsBaseUri;
    bytes32 domainSeparator;
    //VRF
    mapping(bytes32 => uint256) vrfRequestIdToTokenId;
    mapping(bytes32 => uint256) vrfNonces;
    bytes32 keyHash;
    uint144 fee;
    address vrfCoordinator;
    ILink link;
    // Marketplace
    uint256 nextERC1155ListingId;
    // erc1155 category => erc1155Order
    //ERC1155Order[] erc1155MarketOrders;
    mapping(uint256 => ERC1155Listing) erc1155Listings;
    // category => ("listed" or purchased => first listingId)
    //mapping(uint256 => mapping(string => bytes32[])) erc1155MarketListingIds;
    mapping(uint256 => mapping(string => uint256)) erc1155ListingHead;
    // "listed" or purchased => (listingId => ListingListItem)
    mapping(string => mapping(uint256 => ListingListItem)) erc1155ListingListItem;
    mapping(address => mapping(uint256 => mapping(string => uint256))) erc1155OwnerListingHead;
    // "listed" or purchased => (listingId => ListingListItem)
    mapping(string => mapping(uint256 => ListingListItem)) erc1155OwnerListingListItem;
    mapping(address => mapping(uint256 => mapping(address => uint256))) erc1155TokenToListingId;
    uint256 listingFeeInWei;
    // erc1155Token => (erc1155TypeId => category)
    mapping(address => mapping(uint256 => uint256)) erc1155Categories;
    uint256 nextERC721ListingId;
    //ERC1155Order[] erc1155MarketOrders;
    mapping(uint256 => ERC721Listing) erc721Listings;
    // listingId => ListingListItem
    mapping(uint256 => ListingListItem) erc721ListingListItem;
    mapping(uint256 => mapping(string => uint256)) erc721ListingHead;
    // user address => category => sort => listingId => ListingListItem
    mapping(uint256 => ListingListItem) erc721OwnerListingListItem;
    mapping(address => mapping(uint256 => mapping(string => uint256))) erc721OwnerListingHead;
    // erc1155Token => (erc1155TypeId => category)
    // not really in use now, for the future
    mapping(address => mapping(uint256 => uint256)) erc721Categories;
    // erc721 token address, erc721 tokenId, user address => listingId
    mapping(address => mapping(uint256 => mapping(address => uint256))) erc721TokenToListingId;
    mapping(uint256 => uint256) sleeves;
    mapping(address => bool) itemManagers;
    mapping(address => GameManager) gameManagers;
    mapping(uint256 => address[]) hauntCollateralTypes;
    // itemTypeId => (sideview => Dimensions)
    mapping(uint256 => mapping(bytes => Dimensions)) sideViewDimensions;
    mapping(address => mapping(address => bool)) petOperators; //Pet operators for a token
    mapping(uint256 => address) categoryToTokenAddress;
    //***
    //Gotchi Lending
    //***
    uint32 nextGotchiListingId;
    mapping(uint32 => GotchiLending) gotchiLendings;
    mapping(uint32 => uint32) aavegotchiToListingId;
    mapping(address => uint32[]) lentTokenIds;
    mapping(address => mapping(uint32 => uint32)) lentTokenIdIndexes; // address => lent token id => index
    mapping(bytes32 => mapping(uint32 => LendingListItem)) gotchiLendingListItem; // ("listed" or "agreed") => listingId => LendingListItem
    mapping(bytes32 => uint32) gotchiLendingHead; // ("listed" or "agreed") => listingId
    mapping(bytes32 => mapping(uint32 => LendingListItem)) aavegotchiLenderLendingListItem; // ("listed" or "agreed") => listingId => LendingListItem
    mapping(address => mapping(bytes32 => uint32)) aavegotchiLenderLendingHead; // user address => ("listed" or "agreed") => listingId => LendingListItem
    Whitelist[] whitelists;
    // If zero, then the user is not whitelisted for the given whitelist ID. Otherwise, this represents the position of the user in the whitelist + 1
    mapping(uint32 => mapping(address => uint256)) isWhitelisted; // whitelistId => whitelistAddress => isWhitelisted
    mapping(address => bool) revenueTokenAllowed;
    mapping(address => mapping(address => mapping(uint32 => bool))) lendingOperators; // owner => operator => tokenId => isLendingOperator
    address realmAddress;
    // side => (itemTypeId => (slotPosition => exception Bool)) SVG exceptions
    mapping(bytes32 => mapping(uint256 => mapping(uint256 => bool))) wearableExceptions;
    mapping(uint32 => mapping(uint256 => uint256)) whitelistAccessRights; // whitelistId => action right => access right
    mapping(uint32 => mapping(address => EnumerableSet.UintSet)) whitelistGotchiBorrows; // whitelistId => borrower => gotchiId set
    address wearableDiamond;
    address forgeDiamond;
    //XP Drops
    mapping(bytes32 => XPMerkleDrops) xpDrops;
    mapping(uint256 => mapping(bytes32 => uint256)) xpClaimed;
    // states for buy orders
    uint256 nextERC721BuyOrderId;
    mapping(uint256 => ERC721BuyOrder) erc721BuyOrders; // buyOrderId => data
    mapping(address => mapping(uint256 => uint256[])) erc721TokenToBuyOrderIds; // erc721 token address => erc721TokenId => buyOrderIds
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) erc721TokenToBuyOrderIdIndexes; // erc721 token address => erc721TokenId => buyOrderId => index
    mapping(address => mapping(uint256 => mapping(address => uint256))) buyerToBuyOrderId; // erc721 token address => erc721TokenId => sender => buyOrderId
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}

contract Modifiers {
    AppStorage internal s;
    modifier onlyAavegotchiOwner(uint256 _tokenId) {
        require(LibMeta.msgSender() == s.aavegotchis[_tokenId].owner, "LibAppStorage: Only aavegotchi owner can call this function");
        _;
    }
    modifier onlyUnlocked(uint256 _tokenId) {
        require(s.aavegotchis[_tokenId].locked == false, "LibAppStorage: Only callable on unlocked Aavegotchis");
        _;
    }
    modifier onlyLocked(uint256 _tokenId) {
        require(s.aavegotchis[_tokenId].locked == true, "LibAppStorage: Only callable on locked Aavegotchis");
        _;
    }

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyDao() {
        address sender = LibMeta.msgSender();
        require(sender == s.dao, "Only DAO can call this function");
        _;
    }

    modifier onlyDaoOrOwner() {
        address sender = LibMeta.msgSender();
        require(sender == s.dao || sender == LibDiamond.contractOwner(), "LibAppStorage: Do not have access");
        _;
    }

    modifier onlyOwnerOrDaoOrGameManager() {
        address sender = LibMeta.msgSender();
        bool isGameManager = s.gameManagers[sender].limit != 0;
        require(sender == s.dao || sender == LibDiamond.contractOwner() || isGameManager, "LibAppStorage: Do not have access");
        _;
    }
    modifier onlyItemManager() {
        address sender = LibMeta.msgSender();
        require(s.itemManagers[sender] == true, "LibAppStorage: only an ItemManager can call this function");
        _;
    }
    modifier onlyOwnerOrItemManager() {
        address sender = LibMeta.msgSender();
        require(
            sender == LibDiamond.contractOwner() || s.itemManagers[sender] == true,
            "LibAppStorage: only an Owner or ItemManager can call this function"
        );
        _;
    }

    modifier onlyPeriphery() {
        address sender = LibMeta.msgSender();
        require(sender == s.wearableDiamond, "LibAppStorage: Not wearable diamond");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import {LibAppStorage, AppStorage, ListingListItem, ERC1155Listing} from "./LibAppStorage.sol";
import {IERC1155} from "../../shared/interfaces/IERC1155.sol";

// import "hardhat/console.sol";

library LibERC1155Marketplace {
    event ERC1155ListingCancelled(uint256 indexed listingId, uint256 category, uint256 time);
    event ERC1155ListingRemoved(uint256 indexed listingId, uint256 category, uint256 time);
    event UpdateERC1155Listing(uint256 indexed listingId, uint256 quantity, uint256 priceInWei, uint256 time);

    function cancelERC1155Listing(uint256 _listingId, address _owner) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        ListingListItem storage listingItem = s.erc1155ListingListItem["listed"][_listingId];
        if (listingItem.listingId == 0) {
            return;
        }
        ERC1155Listing storage listing = s.erc1155Listings[_listingId];
        if (listing.cancelled == true || listing.sold == true) {
            return;
        }
        require(listing.seller == _owner, "Marketplace: owner not seller");
        listing.cancelled = true;
        emit ERC1155ListingCancelled(_listingId, listing.category, block.number);
        removeERC1155ListingItem(_listingId, _owner);
    }

    function addERC1155ListingItem(address _owner, uint256 _category, string memory _sort, uint256 _listingId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 headListingId = s.erc1155OwnerListingHead[_owner][_category][_sort];
        if (headListingId != 0) {
            ListingListItem storage headListingItem = s.erc1155OwnerListingListItem[_sort][headListingId];
            headListingItem.parentListingId = _listingId;
        }
        ListingListItem storage listingItem = s.erc1155OwnerListingListItem[_sort][_listingId];
        listingItem.childListingId = headListingId;
        s.erc1155OwnerListingHead[_owner][_category][_sort] = _listingId;
        listingItem.listingId = _listingId;

        headListingId = s.erc1155ListingHead[_category][_sort];
        if (headListingId != 0) {
            ListingListItem storage headListingItem = s.erc1155ListingListItem[_sort][headListingId];
            headListingItem.parentListingId = _listingId;
        }
        listingItem = s.erc1155ListingListItem[_sort][_listingId];
        listingItem.childListingId = headListingId;
        s.erc1155ListingHead[_category][_sort] = _listingId;
        listingItem.listingId = _listingId;
    }

    function removeERC1155ListingItem(uint256 _listingId, address _owner) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        ListingListItem storage listingItem = s.erc1155ListingListItem["listed"][_listingId];
        if (listingItem.listingId == 0) {
            return;
        }
        uint256 parentListingId = listingItem.parentListingId;
        if (parentListingId != 0) {
            ListingListItem storage parentListingItem = s.erc1155ListingListItem["listed"][parentListingId];
            parentListingItem.childListingId = listingItem.childListingId;
        }
        uint256 childListingId = listingItem.childListingId;
        if (childListingId != 0) {
            ListingListItem storage childListingItem = s.erc1155ListingListItem["listed"][childListingId];
            childListingItem.parentListingId = listingItem.parentListingId;
        }
        ERC1155Listing storage listing = s.erc1155Listings[_listingId];
        if (s.erc1155ListingHead[listing.category]["listed"] == _listingId) {
            s.erc1155ListingHead[listing.category]["listed"] = listingItem.childListingId;
        }
        listingItem.listingId = 0;
        listingItem.parentListingId = 0;
        listingItem.childListingId = 0;

        listingItem = s.erc1155OwnerListingListItem["listed"][_listingId];

        parentListingId = listingItem.parentListingId;
        if (parentListingId != 0) {
            ListingListItem storage parentListingItem = s.erc1155OwnerListingListItem["listed"][parentListingId];
            parentListingItem.childListingId = listingItem.childListingId;
        }
        childListingId = listingItem.childListingId;
        if (childListingId != 0) {
            ListingListItem storage childListingItem = s.erc1155OwnerListingListItem["listed"][childListingId];
            childListingItem.parentListingId = listingItem.parentListingId;
        }
        listing = s.erc1155Listings[_listingId];
        if (s.erc1155OwnerListingHead[_owner][listing.category]["listed"] == _listingId) {
            s.erc1155OwnerListingHead[_owner][listing.category]["listed"] = listingItem.childListingId;
        }
        listingItem.listingId = 0;
        listingItem.parentListingId = 0;
        listingItem.childListingId = 0;
        s.erc1155TokenToListingId[listing.erc1155TokenAddress][listing.erc1155TypeId][_owner] = 0;

        emit ERC1155ListingRemoved(_listingId, listing.category, block.timestamp);
    }

    function updateERC1155Listing(address _erc1155TokenAddress, uint256 _erc1155TypeId, address _owner) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 listingId = s.erc1155TokenToListingId[_erc1155TokenAddress][_erc1155TypeId][_owner];
        if (listingId == 0) {
            return;
        }
        ERC1155Listing storage listing = s.erc1155Listings[listingId];
        if (listing.timeCreated == 0 || listing.cancelled == true || listing.sold == true) {
            return;
        }
        uint256 quantity = listing.quantity;
        if (quantity > 0) {
            quantity = IERC1155(listing.erc1155TokenAddress).balanceOf(listing.seller, listing.erc1155TypeId);
            if (quantity < listing.quantity) {
                listing.quantity = quantity;
                emit UpdateERC1155Listing(listingId, quantity, listing.priceInWei, block.timestamp);
            }
        }
        if (quantity == 0) {
            cancelERC1155Listing(listingId, listing.seller);
        }
    }

    function updateERC1155ListingPriceAndQuantity(uint256 _listingId, uint256 _quantity, uint256 _priceInWei) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        ERC1155Listing storage listing = s.erc1155Listings[_listingId];
        require(listing.timeCreated != 0, "ERC1155Marketplace: listing not found");
        require(listing.sold == false, "ERC1155Marketplace: listing is sold out");
        require(listing.cancelled == false, "ERC1155Marketplace: listing already cancelled");
        require(_quantity * _priceInWei >= 1e18, "ERC1155Marketplace: cost should be 1 GHST or larger");
        require(listing.seller == msg.sender, "ERC1155Marketplace: Not seller of ERC1155 listing");
        require(
            IERC1155(listing.erc1155TokenAddress).balanceOf(listing.seller, listing.erc1155TypeId) >= _quantity,
            "ERC1155Marketplace: Not enough ERC1155 token"
        );

        //comment out until subgraph is synced
        // listing.priceInWei = _priceInWei;
        // listing.quantity = _quantity;

        emit UpdateERC1155Listing(_listingId, _quantity, _priceInWei, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import {LibAppStorage, AppStorage, ItemType, Aavegotchi, EQUIPPED_WEARABLE_SLOTS} from "./LibAppStorage.sol";
import {LibERC1155} from "../../shared/libraries/LibERC1155.sol";

struct ItemTypeIO {
    uint256 balance;
    uint256 itemId;
    ItemType itemType;
}

library LibItems {
    //Wearables
    uint8 internal constant WEARABLE_SLOT_BODY = 0;
    uint8 internal constant WEARABLE_SLOT_FACE = 1;
    uint8 internal constant WEARABLE_SLOT_EYES = 2;
    uint8 internal constant WEARABLE_SLOT_HEAD = 3;
    uint8 internal constant WEARABLE_SLOT_HAND_LEFT = 4;
    uint8 internal constant WEARABLE_SLOT_HAND_RIGHT = 5;
    uint8 internal constant WEARABLE_SLOT_PET = 6;
    uint8 internal constant WEARABLE_SLOT_BG = 7;

    uint256 internal constant ITEM_CATEGORY_WEARABLE = 0;
    uint256 internal constant ITEM_CATEGORY_BADGE = 1;
    uint256 internal constant ITEM_CATEGORY_CONSUMABLE = 2;

    uint8 internal constant WEARABLE_SLOTS_TOTAL = 11;

    function itemBalancesOfTokenWithTypes(address _tokenContract, uint256 _tokenId)
        internal
        view
        returns (ItemTypeIO[] memory itemBalancesOfTokenWithTypes_)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 count = s.nftItems[_tokenContract][_tokenId].length;
        itemBalancesOfTokenWithTypes_ = new ItemTypeIO[](count);
        for (uint256 i; i < count; i++) {
            uint256 itemId = s.nftItems[_tokenContract][_tokenId][i];
            uint256 bal = s.nftItemBalances[_tokenContract][_tokenId][itemId];
            itemBalancesOfTokenWithTypes_[i].itemId = itemId;
            itemBalancesOfTokenWithTypes_[i].balance = bal;
            itemBalancesOfTokenWithTypes_[i].itemType = s.itemTypes[itemId];
        }
    }

    function addToParent(
        address _toContract,
        uint256 _toTokenId,
        uint256 _id,
        uint256 _value
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.nftItemBalances[_toContract][_toTokenId][_id] += _value;
        if (s.nftItemIndexes[_toContract][_toTokenId][_id] == 0) {
            s.nftItems[_toContract][_toTokenId].push(uint16(_id));
            s.nftItemIndexes[_toContract][_toTokenId][_id] = s.nftItems[_toContract][_toTokenId].length;
        }
    }

    function addToOwner(
        address _to,
        uint256 _id,
        uint256 _value
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.ownerItemBalances[_to][_id] += _value;
        if (s.ownerItemIndexes[_to][_id] == 0) {
            s.ownerItems[_to].push(uint16(_id));
            s.ownerItemIndexes[_to][_id] = s.ownerItems[_to].length;
        }
    }

    function removeFromOwner(
        address _from,
        uint256 _id,
        uint256 _value
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 bal = s.ownerItemBalances[_from][_id];
        require(_value <= bal, "LibItems: Doesn't have that many to transfer");
        bal -= _value;
        s.ownerItemBalances[_from][_id] = bal;
        if (bal == 0) {
            uint256 index = s.ownerItemIndexes[_from][_id] - 1;
            uint256 lastIndex = s.ownerItems[_from].length - 1;
            if (index != lastIndex) {
                uint256 lastId = s.ownerItems[_from][lastIndex];
                s.ownerItems[_from][index] = uint16(lastId);
                s.ownerItemIndexes[_from][lastId] = index + 1;
            }
            s.ownerItems[_from].pop();
            delete s.ownerItemIndexes[_from][_id];
        }
    }

    function removeFromParent(
        address _fromContract,
        uint256 _fromTokenId,
        uint256 _id,
        uint256 _value
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 bal = s.nftItemBalances[_fromContract][_fromTokenId][_id];
        require(_value <= bal, "Items: Doesn't have that many to transfer");
        bal -= _value;
        s.nftItemBalances[_fromContract][_fromTokenId][_id] = bal;
        if (bal == 0) {
            uint256 index = s.nftItemIndexes[_fromContract][_fromTokenId][_id] - 1;
            uint256 lastIndex = s.nftItems[_fromContract][_fromTokenId].length - 1;
            if (index != lastIndex) {
                uint256 lastId = s.nftItems[_fromContract][_fromTokenId][lastIndex];
                s.nftItems[_fromContract][_fromTokenId][index] = uint16(lastId);
                s.nftItemIndexes[_fromContract][_fromTokenId][lastId] = index + 1;
            }
            s.nftItems[_fromContract][_fromTokenId].pop();
            delete s.nftItemIndexes[_fromContract][_fromTokenId][_id];
            if (_fromContract == address(this)) {
                checkWearableIsEquipped(_fromTokenId, _id);
            }
        }
        if (_fromContract == address(this) && bal == 1) {
            Aavegotchi storage aavegotchi = s.aavegotchis[_fromTokenId];
            if (
                aavegotchi.equippedWearables[LibItems.WEARABLE_SLOT_HAND_LEFT] == _id &&
                aavegotchi.equippedWearables[LibItems.WEARABLE_SLOT_HAND_RIGHT] == _id
            ) {
                revert("LibItems: Can't hold 1 item in both hands");
            }
        }
    }

    function checkWearableIsEquipped(uint256 _fromTokenId, uint256 _id) internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        for (uint256 i; i < EQUIPPED_WEARABLE_SLOTS; i++) {
            require(s.aavegotchis[_fromTokenId].equippedWearables[i] != _id, "Items: Cannot transfer wearable that is equipped");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import {LibERC20} from "../../shared/libraries/LibERC20.sol";
import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";

struct BaazaarSplit {
    uint256 daoShare;
    uint256 pixelcraftShare;
    uint256 playerRewardsShare;
    uint256 sellerShare;
    uint256 affiliateShare;
    uint256[] royaltyShares;
}

struct SplitAddresses {
    address ghstContract;
    address buyer;
    address seller;
    address affiliate;
    address[] royalties;
    address daoTreasury;
    address pixelCraft;
    address rarityFarming;
}

library LibSharedMarketplace {
    function getBaazaarSplit(
        uint256 _amount,
        uint256[] memory _royaltyShares,
        uint16[2] memory _principalSplit
    ) internal pure returns (BaazaarSplit memory) {
        //Add up all the royalty amounts
        uint256 royaltyShares;
        for (uint256 i = 0; i < _royaltyShares.length; i++) {
            royaltyShares += _royaltyShares[i];
        }

        uint256 daoShare = _amount / 100; //1%
        uint256 pixelcraftShare = (_amount * 2) / 100; //2%
        uint256 playerRewardsShare = _amount / 200; //0.5%
        uint256 principal = _amount - royaltyShares - (daoShare + pixelcraftShare + playerRewardsShare); //96.5%-royalty

        uint256 sellerShare = (principal * _principalSplit[0]) / 10000;
        uint256 affiliateShare = (principal * _principalSplit[1]) / 10000;

        return
            BaazaarSplit({
                daoShare: daoShare,
                pixelcraftShare: pixelcraftShare,
                playerRewardsShare: playerRewardsShare,
                sellerShare: sellerShare,
                affiliateShare: affiliateShare,
                royaltyShares: _royaltyShares
            });
    }

    function transferSales(SplitAddresses memory _a, BaazaarSplit memory split) internal {
        if (_a.buyer == address(this)) {
            LibERC20.transfer(_a.ghstContract, _a.pixelCraft, split.pixelcraftShare);
            LibERC20.transfer(_a.ghstContract, _a.daoTreasury, split.daoShare);
            LibERC20.transfer(_a.ghstContract, _a.rarityFarming, split.playerRewardsShare);
            LibERC20.transfer(_a.ghstContract, _a.seller, split.sellerShare);

            //handle affiliate split if necessary
            if (split.affiliateShare > 0) {
                LibERC20.transfer(_a.ghstContract, _a.affiliate, split.affiliateShare);
            }
            //handle royalty if necessary
            if (_a.royalties.length > 0) {
                for (uint256 i = 0; i < _a.royalties.length; i++) {
                    if (split.royaltyShares[i] > 0) {
                        LibERC20.transfer(_a.ghstContract, _a.royalties[i], split.royaltyShares[i]);
                    }
                }
            }
        } else {
            LibERC20.transferFrom(_a.ghstContract, _a.buyer, _a.pixelCraft, split.pixelcraftShare);
            LibERC20.transferFrom(_a.ghstContract, _a.buyer, _a.daoTreasury, split.daoShare);
            LibERC20.transferFrom(_a.ghstContract, _a.buyer, _a.rarityFarming, split.playerRewardsShare);
            LibERC20.transferFrom(_a.ghstContract, _a.buyer, _a.seller, split.sellerShare);

            //handle affiliate split if necessary
            if (split.affiliateShare > 0) {
                LibERC20.transferFrom(_a.ghstContract, _a.buyer, _a.affiliate, split.affiliateShare);
            }
            //handle royalty if necessary
            if (_a.royalties.length > 0) {
                for (uint256 i = 0; i < _a.royalties.length; i++) {
                    if (split.royaltyShares[i] > 0) {
                        LibERC20.transferFrom(_a.ghstContract, _a.buyer, _a.royalties[i], split.royaltyShares[i]);
                    }
                }
            }
        }
    }

    function burnListingFee(uint256 listingFee, address owner, address ghstContract) internal {
        if (listingFee > 0) {
            LibERC20.transferFrom(ghstContract, owner, address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF), listingFee);
        }
    }

    ///@notice Query the category of an NFT
    ///@param _erc721TokenAddress The contract address of the NFT to query
    ///@param _erc721TokenId The identifier of the NFT to query
    ///@return category_ Category of the NFT // 0 == portal, 1 == vrf pending, 2 == open portal, 3 == Aavegotchi 4 == Realm.
    function getERC721Category(address _erc721TokenAddress, uint256 _erc721TokenId) internal view returns (uint256 category_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(
            _erc721TokenAddress == address(this) || s.erc721Categories[_erc721TokenAddress][0] != 0,
            "ERC721Marketplace: ERC721 category does not exist"
        );
        if (_erc721TokenAddress != address(this)) {
            category_ = s.erc721Categories[_erc721TokenAddress][0];
        } else {
            category_ = s.aavegotchis[_erc721TokenId].status; // 0 == portal, 1 == vrf pending, 2 == open portal, 3 == Aavegotchi
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IEventHandlerFacet {
    function emitApprovalEvent(
        address _account,
        address _operator,
        bool _approved
    ) external;

    function emitUriEvent(string memory _value, uint256 _id) external;

    function emitTransferSingleEvent(
        address _operator,
        address _from,
        address _to,
        uint256 _id,
        uint256 _value
    ) external;

    function emitTransferBatchEvent(
        address _operator,
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://eips.ethereum.org/EIPS/eip-1155
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
/* is ERC165 */
interface IERC1155 {
    /**
    @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
    @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    MUST revert if `_to` is the zero address.
    MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
    MUST revert on any other error.
    MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
    After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).        
    @param _from    Source address
    @param _to      Target address
    @param _id      ID of the token type
    @param _value   Transfer amount
    @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    /**
    @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
    @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    MUST revert if `_to` is the zero address.
    MUST revert if length of `_ids` is not the same as length of `_values`.
    MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
    MUST revert on any other error.        
    MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
    Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
    After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
    @param _from    Source address
    @param _to      Target address
    @param _ids     IDs of each token type (order and length must match _values array)
    @param _values  Transfer amounts per token type (order and length must match _ids array)
    @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /**
    @notice Get the balance of an account's tokens.
    @param _owner  The address of the token holder
    @param _id     ID of the token
    @return        The _owner's balance of the token type requested
    */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
    @notice Get the balance of multiple account/token pairs
    @param _owners The addresses of the token holders
    @param _ids    ID of the tokens
    @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
    */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    /**
    @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    @dev MUST emit the ApprovalForAll event on success.
    @param _operator  Address to add to the set of authorized operators
    @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
    @notice Queries the approval status of an operator for a given owner.
    @param _owner     The owner of the tokens
    @param _operator  Address of authorized operator
    @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface IERC1155TokenReceiver {
    /**
    @notice Handle the receipt of a single ERC1155 token type.
    @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.        
    This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
    This function MUST revert if it rejects the transfer.
    Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
    @param _operator  The address which initiated the transfer (i.e. msg.sender)
    @param _from      The address which previously owned the token
    @param _id        The ID of the token being transferred
    @param _value     The amount of tokens being transferred
    @param _data      Additional data with no specified format
    @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    /**
    @notice Handle the receipt of multiple ERC1155 token types.
    @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.        
    This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
    This function MUST revert if it rejects the transfer(s).
    Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
    @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
    @param _from      The address which previously owned the token
    @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
    @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
    @param _data      Additional data with no specified format
    @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IERC165} from "../interfaces/IERC165.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import {LibMeta} from "./LibMeta.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
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
        require(LibMeta.msgSender() == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    function addDiamondFunctions(
        address _diamondCutFacet,
        address _diamondLoupeFacet,
        address _ownershipFacet
    ) internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({facetAddress: _diamondCutFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors});
        functionSelectors = new bytes4[](5);
        functionSelectors[0] = IDiamondLoupe.facets.selector;
        functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facetAddress.selector;
        functionSelectors[4] = IERC165.supportsInterface.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: _diamondLoupeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        functionSelectors = new bytes4[](2);
        functionSelectors[0] = IERC173.transferOwnership.selector;
        functionSelectors[1] = IERC173.owner.selector;
        cut[2] = IDiamondCut.FacetCut({facetAddress: _ownershipFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors});
        diamondCut(cut, address(0), "");
    }

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
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(oldFacetAddress, selector);
            // add function
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
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
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        DiamondStorage storage ds = diamondStorage();
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
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint16(selectorPosition);
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
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = uint16(facetAddressPosition);
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
            if (success == false) {
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
        require(contractSize != 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import {IERC1155TokenReceiver} from "../interfaces/IERC1155TokenReceiver.sol";

library LibERC1155 {
    bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61; // Return value from `onERC1155Received` call if a contract accepts receipt (i.e `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`).
    bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81; // Return value from `onERC1155BatchReceived` call if a contract accepts receipt (i.e `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    event TransferToParent(address indexed _toContract, uint256 indexed _toTokenId, uint256 indexed _tokenTypeId, uint256 _value);
    event TransferFromParent(address indexed _fromContract, uint256 indexed _fromTokenId, uint256 indexed _tokenTypeId, uint256 _value);
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be LibMeta.msgSender()).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).        
    */
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).      
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be LibMeta.msgSender()).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).                
    */
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).        
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    function onERC1155Received(
        address _operator,
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes memory _data
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_to)
        }
        if (size > 0) {
            require(
                ERC1155_ACCEPTED == IERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _id, _value, _data),
                "Wearables: Transfer rejected/failed by _to"
            );
        }
    }

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes memory _data
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_to)
        }
        if (size > 0) {
            require(
                ERC1155_BATCH_ACCEPTED == IERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _ids, _values, _data),
                "Wearables: Transfer rejected/failed by _to"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/******************************************************************************\
* Author: Nick Mudge
*
/******************************************************************************/

import {IERC20} from "../interfaces/IERC20.sol";

library LibERC20 {
    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: ERC20 token address has no code");
        (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, _from, _to, _value));
        handleReturn(success, result);
    }

    function transfer(
        address _token,
        address _to,
        uint256 _value
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: ERC20 token address has no code");
        (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transfer.selector, _to, _value));
        handleReturn(success, result);
    }

    function handleReturn(bool _success, bytes memory _result) internal pure {
        if (_success) {
            if (_result.length > 0) {
                require(abi.decode(_result, (bool)), "LibERC20: transfer or transferFrom returned false");
            }
        } else {
            if (_result.length > 0) {
                // bubble up any reason for revert
                revert(string(_result));
            } else {
                revert("LibERC20: transfer or transferFrom reverted");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

library LibMeta {
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(bytes("EIP712Domain(string name,string version,uint256 salt,address verifyingContract)"));

    function domainSeparator(string memory name, string memory version) internal view returns (bytes32 domainSeparator_) {
        domainSeparator_ = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes(version)), getChainID(), address(this))
        );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
}