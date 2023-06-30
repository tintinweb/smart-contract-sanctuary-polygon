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

import {IERC20} from "../shared/interfaces/IERC20.sol";
import {LibMeta} from "../shared/libraries/LibMeta.sol";

contract CollateralEscrow {
    struct AppStorage {
        address owner;
    }
    AppStorage internal s;

    constructor(address _aTokenContract) {
        s.owner = LibMeta.msgSender();
        approveAavegotchiDiamond(_aTokenContract);
    }

    function approveAavegotchiDiamond(address _aTokenContract) public {
        require(LibMeta.msgSender() == s.owner, "CollateralEscrow: Not owner of contract");
        require(IERC20(_aTokenContract).approve(s.owner, type(uint256).max), "CollateralEscrow: token not approved for transfer");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import {LibAavegotchi} from "../libraries/LibAavegotchi.sol";
import {LibBuyOrder} from "../libraries/LibBuyOrder.sol";
import {LibERC721Marketplace} from "../libraries/LibERC721Marketplace.sol";
import {LibERC20} from "../../shared/libraries/LibERC20.sol";
import {IERC20} from "../../shared/interfaces/IERC20.sol";
import {IERC721} from "../../shared/interfaces/IERC721.sol";
import {LibMeta} from "../../shared/libraries/LibMeta.sol";
import {LibGotchiLending} from "../libraries/LibGotchiLending.sol";
import {Modifiers, ERC721BuyOrder} from "../libraries/LibAppStorage.sol";
import {BaazaarSplit, LibSharedMarketplace, SplitAddresses} from "../libraries/LibSharedMarketplace.sol";

contract ERC721BuyOrderFacet is Modifiers {
    event ERC721BuyOrderAdded(
        uint256 indexed buyOrderId,
        address indexed buyer,
        address erc721TokenAddress,
        uint256 erc721TokenId,
        uint256 indexed category,
        uint256 priceInWei,
        uint256 duration,
        bytes32 validationHash,
        uint256 time
    );
    event ERC721BuyOrderCanceled(uint256 indexed buyOrderId, uint256 time);
    event ERC721BuyOrderExecuted(
        uint256 indexed buyOrderId,
        address indexed buyer,
        address seller,
        address erc721TokenAddress,
        uint256 erc721TokenId,
        uint256 priceInWei,
        uint256 time
    );

    function getERC721BuyOrder(uint256 _buyOrderId) external view returns (ERC721BuyOrder memory buyOrder_) {
        buyOrder_ = s.erc721BuyOrders[_buyOrderId];
        require(buyOrder_.timeCreated != 0, "ERC721BuyOrder: ERC721 buyOrder does not exist");
    }

    struct StatusesReturn {
        string status;
        uint256 buyOrderId;
    }

    function getERC721BuyOrderStatuses(uint256[] calldata _buyOrderIds) external view returns (StatusesReturn[] memory statuses_) {
        uint256 length = _buyOrderIds.length;
        statuses_ = new StatusesReturn[](length);
        for (uint256 i; i < length; i++) {
            ERC721BuyOrder memory buyOrder = s.erc721BuyOrders[_buyOrderIds[i]];
            if (buyOrder.timeCreated == 0) {
                statuses_[i].status = "nonexistent";
                statuses_[i].buyOrderId = _buyOrderIds[i];
            } else if (buyOrder.cancelled == true) {
                statuses_[i].status = "cancelled";
                statuses_[i].buyOrderId = _buyOrderIds[i];
            } else if (buyOrder.timePurchased != 0) {
                statuses_[i].status = "executed";
                statuses_[i].buyOrderId = _buyOrderIds[i];
            } else {
                bytes32 validationHash = LibBuyOrder.generateValidationHash(
                    buyOrder.erc721TokenAddress,
                    buyOrder.erc721TokenId,
                    buyOrder.validationOptions
                );

                //Handle active states
                if (validationHash != buyOrder.validationHash) {
                    statuses_[i].status = "invalid";
                } else if (buyOrder.duration != 0 && buyOrder.timeCreated + buyOrder.duration < block.timestamp) {
                    statuses_[i].status = "expired";
                } else {
                    statuses_[i].status = "pending";
                }

                // hash validation

                statuses_[i].buyOrderId = _buyOrderIds[i];
            }
        }
    }

    function getERC721BuyOrderIdsByTokenId(
        address _erc721TokenAddress,
        uint256 _erc721TokenId
    ) external view returns (uint256[] memory buyOrderIds_) {
        buyOrderIds_ = s.erc721TokenToBuyOrderIds[_erc721TokenAddress][_erc721TokenId];
    }

    function getERC721BuyOrdersByTokenId(
        address _erc721TokenAddress,
        uint256 _erc721TokenId
    ) external view returns (ERC721BuyOrder[] memory buyOrders_) {
        uint256[] memory buyOrderIds = s.erc721TokenToBuyOrderIds[_erc721TokenAddress][_erc721TokenId];
        uint256 length = buyOrderIds.length;
        buyOrders_ = new ERC721BuyOrder[](length);
        for (uint256 i; i < length; i++) {
            buyOrders_[i] = s.erc721BuyOrders[buyOrderIds[i]];
        }
    }

    function placeERC721BuyOrder(
        address _erc721TokenAddress,
        uint256 _erc721TokenId,
        uint256 _priceInWei,
        uint256 _duration,
        bool[] calldata _validationOptions // 0: BRS, 1: GHST, 2: skill points
    ) external {
        require(_priceInWei >= 1e18, "ERC721BuyOrder: price should be 1 GHST or larger");

        address sender = LibMeta.msgSender();
        uint256 ghstBalance = IERC20(s.ghstContract).balanceOf(sender);
        require(ghstBalance >= _priceInWei, "ERC721BuyOrder: Not enough GHST!");

        uint256 category = LibSharedMarketplace.getERC721Category(_erc721TokenAddress, _erc721TokenId);
        require(category != LibAavegotchi.STATUS_VRF_PENDING, "ERC721BuyOrder: Cannot buy a portal that is pending VRF");
        require(sender != IERC721(_erc721TokenAddress).ownerOf(_erc721TokenId), "ERC721BuyOrder: Owner can't be buyer");
        if (category == LibAavegotchi.STATUS_AAVEGOTCHI) {
            require(_validationOptions.length == 3, "ERC721BuyOrder: Not enough validation options for aavegotchi");
        }

        uint256 oldBuyOrderId = s.buyerToBuyOrderId[_erc721TokenAddress][_erc721TokenId][sender];
        if (oldBuyOrderId != 0) {
            ERC721BuyOrder memory erc721BuyOrder = s.erc721BuyOrders[oldBuyOrderId];
            require(erc721BuyOrder.timeCreated != 0, "ERC721BuyOrder: ERC721 buyOrder does not exist");
            require(erc721BuyOrder.cancelled == false && erc721BuyOrder.timePurchased == 0, "ERC721BuyOrder: Already processed");
            if ((erc721BuyOrder.duration == 0) || (erc721BuyOrder.timeCreated + erc721BuyOrder.duration >= block.timestamp)) {
                LibBuyOrder.cancelERC721BuyOrder(oldBuyOrderId);
                emit ERC721BuyOrderCanceled(oldBuyOrderId, block.timestamp);
            }
        }

        // Transfer GHST
        LibERC20.transferFrom(s.ghstContract, sender, address(this), _priceInWei);

        // Place new buy order
        s.nextERC721BuyOrderId++;
        uint256 buyOrderId = s.nextERC721BuyOrderId;

        s.erc721TokenToBuyOrderIdIndexes[_erc721TokenAddress][_erc721TokenId][buyOrderId] = s
        .erc721TokenToBuyOrderIds[_erc721TokenAddress][_erc721TokenId].length;
        s.erc721TokenToBuyOrderIds[_erc721TokenAddress][_erc721TokenId].push(buyOrderId);
        s.buyerToBuyOrderId[_erc721TokenAddress][_erc721TokenId][sender] = buyOrderId;

        bytes32 _validationHash = LibBuyOrder.generateValidationHash(_erc721TokenAddress, _erc721TokenId, _validationOptions);
        s.erc721BuyOrders[buyOrderId] = ERC721BuyOrder({
            buyOrderId: buyOrderId,
            buyer: sender,
            erc721TokenAddress: _erc721TokenAddress,
            erc721TokenId: _erc721TokenId,
            priceInWei: _priceInWei,
            validationHash: _validationHash,
            timeCreated: block.timestamp,
            timePurchased: 0,
            duration: _duration,
            cancelled: false,
            validationOptions: _validationOptions
        });
        emit ERC721BuyOrderAdded(
            buyOrderId,
            sender,
            _erc721TokenAddress,
            _erc721TokenId,
            category,
            _priceInWei,
            _duration,
            _validationHash,
            block.timestamp
        );
    }

    function cancelERC721BuyOrder(uint256 _buyOrderId) external {
        address sender = LibMeta.msgSender();
        ERC721BuyOrder memory erc721BuyOrder = s.erc721BuyOrders[_buyOrderId];

        require(erc721BuyOrder.timeCreated != 0, "ERC721BuyOrder: ERC721 buyOrder does not exist");
        require(
            sender == IERC721(erc721BuyOrder.erc721TokenAddress).ownerOf(erc721BuyOrder.erc721TokenId) || sender == erc721BuyOrder.buyer,
            "ERC721BuyOrder: Only ERC721 token owner or buyer can call this function"
        );
        require(erc721BuyOrder.cancelled == false && erc721BuyOrder.timePurchased == 0, "ERC721BuyOrder: Already processed");
        if (erc721BuyOrder.duration > 0) {
            require(erc721BuyOrder.timeCreated + erc721BuyOrder.duration >= block.timestamp, "ERC721BuyOrder: Already expired");
        }

        LibBuyOrder.cancelERC721BuyOrder(_buyOrderId);
        emit ERC721BuyOrderCanceled(_buyOrderId, block.timestamp);
    }

    function executeERC721BuyOrder(uint256 _buyOrderId, address _erc721TokenAddress, uint256 _erc721TokenId, uint256 _priceInWei) external {
        address sender = LibMeta.msgSender();
        ERC721BuyOrder storage erc721BuyOrder = s.erc721BuyOrders[_buyOrderId];

        require(erc721BuyOrder.timeCreated != 0, "ERC721BuyOrder: ERC721 buyOrder does not exist");
        require(erc721BuyOrder.erc721TokenAddress == _erc721TokenAddress, "ERC721BuyOrder: ERC721 token address not matched");
        require(erc721BuyOrder.erc721TokenId == _erc721TokenId, "ERC721BuyOrder: ERC721 token id not matched");
        require(erc721BuyOrder.priceInWei == _priceInWei, "ERC721BuyOrder: Price not matched");
        require(sender == IERC721(_erc721TokenAddress).ownerOf(_erc721TokenId), "ERC721BuyOrder: Only ERC721 token owner can call this function");
        require(erc721BuyOrder.cancelled == false && erc721BuyOrder.timePurchased == 0, "ERC721BuyOrder: Already processed");
        if (erc721BuyOrder.duration > 0) {
            require(erc721BuyOrder.timeCreated + erc721BuyOrder.duration >= block.timestamp, "ERC721BuyOrder: Already expired");
        }

        if (erc721BuyOrder.erc721TokenAddress == address(this)) {
            // disable for gotchi in lending
            uint256 category = LibSharedMarketplace.getERC721Category(_erc721TokenAddress, _erc721TokenId);
            if (category == LibAavegotchi.STATUS_AAVEGOTCHI) {
                require(!LibGotchiLending.isAavegotchiLent(uint32(_erc721TokenId)), "ERC721BuyOrder: Not supported for aavegotchi in lending");
            }
        }

        // hash validation
        require(
            erc721BuyOrder.validationHash ==
                LibBuyOrder.generateValidationHash(_erc721TokenAddress, _erc721TokenId, erc721BuyOrder.validationOptions),
            "ERC721BuyOrder: Invalid buy order"
        );

        //Execute order
        erc721BuyOrder.timePurchased = block.timestamp;

        BaazaarSplit memory split = LibSharedMarketplace.getBaazaarSplit(erc721BuyOrder.priceInWei, new uint256[](0), [10000, 0]);

        LibSharedMarketplace.transferSales(
            SplitAddresses({
                ghstContract: s.ghstContract,
                buyer: address(this),
                seller: sender,
                affiliate: address(0),
                royalties: new address[](0),
                daoTreasury: s.daoTreasury,
                pixelCraft: s.pixelCraft,
                rarityFarming: s.rarityFarming
            }),
            split
        );

        if (_erc721TokenAddress == address(this)) {
            s.aavegotchis[_erc721TokenId].locked = false;
            LibAavegotchi.transfer(sender, erc721BuyOrder.buyer, _erc721TokenId);
            LibERC721Marketplace.updateERC721Listing(address(this), _erc721TokenId, sender);
        } else {
            IERC721(_erc721TokenAddress).safeTransferFrom(sender, erc721BuyOrder.buyer, _erc721TokenId);
        }

        LibBuyOrder.removeERC721BuyOrder(_buyOrderId);

        emit ERC721BuyOrderExecuted(
            _buyOrderId,
            erc721BuyOrder.buyer,
            sender,
            _erc721TokenAddress,
            _erc721TokenId,
            erc721BuyOrder.priceInWei,
            block.timestamp
        );
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

import {IERC20} from "../../shared/interfaces/IERC20.sol";
import {LibAppStorage, AavegotchiCollateralTypeInfo, AppStorage, Aavegotchi, ItemType, NUMERIC_TRAITS_NUM, EQUIPPED_WEARABLE_SLOTS, PORTAL_AAVEGOTCHIS_NUM} from "./LibAppStorage.sol";
import {LibERC20} from "../../shared/libraries/LibERC20.sol";
import {LibMeta} from "../../shared/libraries/LibMeta.sol";
import {IERC721} from "../../shared/interfaces/IERC721.sol";
import {LibERC721} from "../../shared/libraries/LibERC721.sol";
import {LibItems, ItemTypeIO} from "../libraries/LibItems.sol";

struct AavegotchiCollateralTypeIO {
    address collateralType;
    AavegotchiCollateralTypeInfo collateralTypeInfo;
}

struct AavegotchiInfo {
    uint256 tokenId;
    string name;
    address owner;
    uint256 randomNumber;
    uint256 status;
    int16[NUMERIC_TRAITS_NUM] numericTraits;
    int16[NUMERIC_TRAITS_NUM] modifiedNumericTraits;
    uint16[EQUIPPED_WEARABLE_SLOTS] equippedWearables;
    address collateral;
    address escrow;
    uint256 stakedAmount;
    uint256 minimumStake;
    uint256 kinship; //The kinship value of this Aavegotchi. Default is 50.
    uint256 lastInteracted;
    uint256 experience; //How much XP this Aavegotchi has accrued. Begins at 0.
    uint256 toNextLevel;
    uint256 usedSkillPoints; //number of skill points used
    uint256 level; //the current aavegotchi level
    uint256 hauntId;
    uint256 baseRarityScore;
    uint256 modifiedRarityScore;
    bool locked;
    ItemTypeIO[] items;
}

struct PortalAavegotchiTraitsIO {
    uint256 randomNumber;
    int16[NUMERIC_TRAITS_NUM] numericTraits;
    address collateralType;
    uint256 minimumStake;
}

struct InternalPortalAavegotchiTraitsIO {
    uint256 randomNumber;
    int16[NUMERIC_TRAITS_NUM] numericTraits;
    address collateralType;
    uint256 minimumStake;
}

library LibAavegotchi {
    uint8 constant STATUS_CLOSED_PORTAL = 0;
    uint8 constant STATUS_VRF_PENDING = 1;
    uint8 constant STATUS_OPEN_PORTAL = 2;
    uint8 constant STATUS_AAVEGOTCHI = 3;

    event AavegotchiInteract(uint256 indexed _tokenId, uint256 kinship);

    function toNumericTraits(
        uint256 _randomNumber,
        int16[NUMERIC_TRAITS_NUM] memory _modifiers,
        uint256 _hauntId
    ) internal pure returns (int16[NUMERIC_TRAITS_NUM] memory numericTraits_) {
        if (_hauntId == 1) {
            for (uint256 i; i < NUMERIC_TRAITS_NUM; i++) {
                uint256 value = uint8(uint256(_randomNumber >> (i * 8)));
                if (value > 99) {
                    value /= 2;
                    if (value > 99) {
                        value = uint256(keccak256(abi.encodePacked(_randomNumber, i))) % 100;
                    }
                }
                numericTraits_[i] = int16(int256(value)) + _modifiers[i];
            }
        } else {
            for (uint256 i; i < NUMERIC_TRAITS_NUM; i++) {
                uint256 value = uint8(uint256(_randomNumber >> (i * 8)));
                if (value > 99) {
                    value = value - 100;
                    if (value > 99) {
                        value = uint256(keccak256(abi.encodePacked(_randomNumber, i))) % 100;
                    }
                }
                numericTraits_[i] = int16(int256(value)) + _modifiers[i];
            }
        }
    }

    function rarityMultiplier(int16[NUMERIC_TRAITS_NUM] memory _numericTraits) internal pure returns (uint256 multiplier) {
        uint256 rarityScore = LibAavegotchi.baseRarityScore(_numericTraits);
        if (rarityScore < 300) return 10;
        else if (rarityScore >= 300 && rarityScore < 450) return 10;
        else if (rarityScore >= 450 && rarityScore <= 525) return 25;
        else if (rarityScore >= 526 && rarityScore <= 580) return 100;
        else if (rarityScore >= 581) return 1000;
    }

    function singlePortalAavegotchiTraits(
        uint256 _hauntId,
        uint256 _randomNumber,
        uint256 _option
    ) internal view returns (InternalPortalAavegotchiTraitsIO memory singlePortalAavegotchiTraits_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 randomNumberN = uint256(keccak256(abi.encodePacked(_randomNumber, _option)));
        singlePortalAavegotchiTraits_.randomNumber = randomNumberN;

        address collateralType = s.hauntCollateralTypes[_hauntId][randomNumberN % s.hauntCollateralTypes[_hauntId].length];
        singlePortalAavegotchiTraits_.numericTraits = toNumericTraits(randomNumberN, s.collateralTypeInfo[collateralType].modifiers, _hauntId);
        singlePortalAavegotchiTraits_.collateralType = collateralType;

        AavegotchiCollateralTypeInfo memory collateralInfo = s.collateralTypeInfo[collateralType];
        uint256 conversionRate = collateralInfo.conversionRate;

        //Get rarity multiplier
        uint256 multiplier = rarityMultiplier(singlePortalAavegotchiTraits_.numericTraits);

        //First we get the base price of our collateral in terms of DAI
        uint256 collateralDAIPrice = ((10 ** IERC20(collateralType).decimals()) / conversionRate);

        //Then multiply by the rarity multiplier
        singlePortalAavegotchiTraits_.minimumStake = collateralDAIPrice * multiplier;
    }

    function portalAavegotchiTraits(
        uint256 _tokenId
    ) internal view returns (PortalAavegotchiTraitsIO[PORTAL_AAVEGOTCHIS_NUM] memory portalAavegotchiTraits_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.aavegotchis[_tokenId].status == LibAavegotchi.STATUS_OPEN_PORTAL, "AavegotchiFacet: Portal not open");

        uint256 randomNumber = s.tokenIdToRandomNumber[_tokenId];

        uint256 hauntId = s.aavegotchis[_tokenId].hauntId;

        for (uint256 i; i < portalAavegotchiTraits_.length; i++) {
            InternalPortalAavegotchiTraitsIO memory single = singlePortalAavegotchiTraits(hauntId, randomNumber, i);
            portalAavegotchiTraits_[i].randomNumber = single.randomNumber;
            portalAavegotchiTraits_[i].collateralType = single.collateralType;
            portalAavegotchiTraits_[i].minimumStake = single.minimumStake;
            portalAavegotchiTraits_[i].numericTraits = single.numericTraits;
        }
    }

    function getAavegotchi(uint256 _tokenId) internal view returns (AavegotchiInfo memory aavegotchiInfo_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        aavegotchiInfo_.tokenId = _tokenId;
        aavegotchiInfo_.owner = s.aavegotchis[_tokenId].owner;
        aavegotchiInfo_.randomNumber = s.aavegotchis[_tokenId].randomNumber;
        aavegotchiInfo_.status = s.aavegotchis[_tokenId].status;
        aavegotchiInfo_.hauntId = s.aavegotchis[_tokenId].hauntId;
        if (aavegotchiInfo_.status == STATUS_AAVEGOTCHI) {
            aavegotchiInfo_.name = s.aavegotchis[_tokenId].name;
            aavegotchiInfo_.equippedWearables = s.aavegotchis[_tokenId].equippedWearables;
            aavegotchiInfo_.collateral = s.aavegotchis[_tokenId].collateralType;
            aavegotchiInfo_.escrow = s.aavegotchis[_tokenId].escrow;
            aavegotchiInfo_.stakedAmount = IERC20(aavegotchiInfo_.collateral).balanceOf(aavegotchiInfo_.escrow);
            aavegotchiInfo_.minimumStake = s.aavegotchis[_tokenId].minimumStake;
            aavegotchiInfo_.kinship = kinship(_tokenId);
            aavegotchiInfo_.lastInteracted = s.aavegotchis[_tokenId].lastInteracted;
            aavegotchiInfo_.experience = s.aavegotchis[_tokenId].experience;
            aavegotchiInfo_.toNextLevel = xpUntilNextLevel(s.aavegotchis[_tokenId].experience);
            aavegotchiInfo_.level = aavegotchiLevel(s.aavegotchis[_tokenId].experience);
            aavegotchiInfo_.usedSkillPoints = s.aavegotchis[_tokenId].usedSkillPoints;
            aavegotchiInfo_.numericTraits = s.aavegotchis[_tokenId].numericTraits;
            aavegotchiInfo_.baseRarityScore = baseRarityScore(aavegotchiInfo_.numericTraits);
            (aavegotchiInfo_.modifiedNumericTraits, aavegotchiInfo_.modifiedRarityScore) = modifiedTraitsAndRarityScore(_tokenId);
            aavegotchiInfo_.locked = s.aavegotchis[_tokenId].locked;
            aavegotchiInfo_.items = LibItems.itemBalancesOfTokenWithTypes(address(this), _tokenId);
        }
    }

    //Only valid for claimed Aavegotchis
    function modifiedTraitsAndRarityScore(
        uint256 _tokenId
    ) internal view returns (int16[NUMERIC_TRAITS_NUM] memory numericTraits_, uint256 rarityScore_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.aavegotchis[_tokenId].status == STATUS_AAVEGOTCHI, "AavegotchiFacet: Must be claimed");
        Aavegotchi storage aavegotchi = s.aavegotchis[_tokenId];
        numericTraits_ = getNumericTraits(_tokenId);
        uint256 wearableBonus;
        for (uint256 slot; slot < EQUIPPED_WEARABLE_SLOTS; slot++) {
            uint256 wearableId = aavegotchi.equippedWearables[slot];
            if (wearableId == 0) {
                continue;
            }
            ItemType storage itemType = s.itemTypes[wearableId];
            //Add on trait modifiers
            for (uint256 j; j < NUMERIC_TRAITS_NUM; j++) {
                numericTraits_[j] += itemType.traitModifiers[j];
            }
            wearableBonus += itemType.rarityScoreModifier;
        }
        uint256 baseRarity = baseRarityScore(numericTraits_);
        rarityScore_ = baseRarity + wearableBonus;
    }

    function getNumericTraits(uint256 _tokenId) internal view returns (int16[NUMERIC_TRAITS_NUM] memory numericTraits_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        //Check if trait boosts from consumables are still valid
        int256 boostDecay = int256((block.timestamp - s.aavegotchis[_tokenId].lastTemporaryBoost) / 24 hours);
        for (uint256 i; i < NUMERIC_TRAITS_NUM; i++) {
            int256 number = s.aavegotchis[_tokenId].numericTraits[i];
            int256 boost = s.aavegotchis[_tokenId].temporaryTraitBoosts[i];

            if (boost > 0 && boost > boostDecay) {
                number += boost - boostDecay;
            } else if ((boost * -1) > boostDecay) {
                number += boost + boostDecay;
            }
            numericTraits_[i] = int16(number);
        }
    }

    function kinship(uint256 _tokenId) internal view returns (uint256 score_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Aavegotchi storage aavegotchi = s.aavegotchis[_tokenId];
        uint256 lastInteracted = aavegotchi.lastInteracted;
        uint256 interactionCount = aavegotchi.interactionCount;
        uint256 interval = block.timestamp - lastInteracted;

        uint256 daysSinceInteraction = interval / 24 hours;

        if (interactionCount > daysSinceInteraction) {
            score_ = interactionCount - daysSinceInteraction;
        }
    }

    function xpUntilNextLevel(uint256 _experience) internal pure returns (uint256 requiredXp_) {
        uint256 currentLevel = aavegotchiLevel(_experience);
        requiredXp_ = ((currentLevel ** 2) * 50) - _experience;
    }

    function aavegotchiLevel(uint256 _experience) internal pure returns (uint256 level_) {
        if (_experience > 490050) {
            return 99;
        }

        level_ = (sqrt(2 * _experience) / 10);
        return level_ + 1;
    }

    function interact(uint256 _tokenId) internal returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 lastInteracted = s.aavegotchis[_tokenId].lastInteracted;
        // if interacted less than 12 hours ago
        if (block.timestamp < lastInteracted + 12 hours) {
            return false;
        }

        uint256 interactionCount = s.aavegotchis[_tokenId].interactionCount;
        uint256 interval = block.timestamp - lastInteracted;
        uint256 daysSinceInteraction = interval / 1 days;
        uint256 l_kinship;
        if (interactionCount > daysSinceInteraction) {
            l_kinship = interactionCount - daysSinceInteraction;
        }

        uint256 hateBonus;

        if (l_kinship < 40) {
            hateBonus = 2;
        }
        l_kinship += 1 + hateBonus;
        s.aavegotchis[_tokenId].interactionCount = l_kinship;

        s.aavegotchis[_tokenId].lastInteracted = uint40(block.timestamp);
        emit AavegotchiInteract(_tokenId, l_kinship);
        return true;
    }

    //Calculates the base rarity score, including collateral modifier
    function baseRarityScore(int16[NUMERIC_TRAITS_NUM] memory _numericTraits) internal pure returns (uint256 _rarityScore) {
        for (uint256 i; i < NUMERIC_TRAITS_NUM; i++) {
            int256 number = _numericTraits[i];
            if (number >= 50) {
                _rarityScore += uint256(number) + 1;
            } else {
                _rarityScore += uint256(int256(100) - number);
            }
        }
    }

    // Need to ensure there is no overflow of _ghst
    function purchase(address _from, uint256 _ghst) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        //33% to burn address
        uint256 burnShare = (_ghst * 33) / 100;

        //17% to Pixelcraft wallet
        uint256 companyShare = (_ghst * 17) / 100;

        //40% to rarity farming rewards
        uint256 rarityFarmShare = (_ghst * 2) / 5;

        //10% to DAO
        uint256 daoShare = (_ghst - burnShare - companyShare - rarityFarmShare);

        // Using 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF as burn address.
        // GHST token contract does not allow transferring to address(0) address: https://etherscan.io/address/0x3F382DbD960E3a9bbCeaE22651E88158d2791550#code
        address ghstContract = s.ghstContract;
        LibERC20.transferFrom(ghstContract, _from, address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF), burnShare);
        LibERC20.transferFrom(ghstContract, _from, s.pixelCraft, companyShare);
        LibERC20.transferFrom(ghstContract, _from, s.rarityFarming, rarityFarmShare);
        LibERC20.transferFrom(ghstContract, _from, s.dao, daoShare);
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function validateAndLowerName(string memory _name) internal pure returns (string memory) {
        bytes memory name = abi.encodePacked(_name);
        uint256 len = name.length;
        require(len != 0, "LibAavegotchi: name can't be 0 chars");
        require(len < 26, "LibAavegotchi: name can't be greater than 25 characters");
        uint256 char = uint256(uint8(name[0]));
        require(char != 32, "LibAavegotchi: first char of name can't be a space");
        char = uint256(uint8(name[len - 1]));
        require(char != 32, "LibAavegotchi: last char of name can't be a space");
        for (uint256 i; i < len; i++) {
            char = uint256(uint8(name[i]));
            require(char > 31 && char < 127, "LibAavegotchi: invalid character in Aavegotchi name.");
            if (char < 91 && char > 64) {
                name[i] = bytes1(uint8(char + 32));
            }
        }
        return string(name);
    }

    // function addTokenToUser(address _to, uint256 _tokenId) internal {}

    // function removeTokenFromUser(address _from, uint256 _tokenId) internal {}

    function transfer(address _from, address _to, uint256 _tokenId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // remove
        uint256 index = s.ownerTokenIdIndexes[_from][_tokenId];
        uint256 lastIndex = s.ownerTokenIds[_from].length - 1;
        if (index != lastIndex) {
            uint32 lastTokenId = s.ownerTokenIds[_from][lastIndex];
            s.ownerTokenIds[_from][index] = lastTokenId;
            s.ownerTokenIdIndexes[_from][lastTokenId] = index;
        }
        s.ownerTokenIds[_from].pop();
        delete s.ownerTokenIdIndexes[_from][_tokenId];
        if (s.approved[_tokenId] != address(0)) {
            delete s.approved[_tokenId];
            emit LibERC721.Approval(_from, address(0), _tokenId);
        }
        // add
        s.aavegotchis[_tokenId].owner = _to;
        s.ownerTokenIdIndexes[_to][_tokenId] = s.ownerTokenIds[_to].length;
        s.ownerTokenIds[_to].push(uint32(_tokenId));
        emit LibERC721.Transfer(_from, _to, _tokenId);
    }
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

import {LibAppStorage, AppStorage, ERC721BuyOrder} from "./LibAppStorage.sol";
import {LibERC20} from "../../shared/libraries/LibERC20.sol";
import {LibAavegotchi} from "./LibAavegotchi.sol";
import {LibSharedMarketplace} from "./LibSharedMarketplace.sol";
import {IERC20} from "../../shared/interfaces/IERC20.sol";

library LibBuyOrder {
    function cancelERC721BuyOrder(uint256 _buyOrderId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        ERC721BuyOrder memory erc721BuyOrder = s.erc721BuyOrders[_buyOrderId];
        if (erc721BuyOrder.timeCreated == 0) {
            return;
        }
        if ((erc721BuyOrder.cancelled == true) || (erc721BuyOrder.timePurchased != 0)) {
            return;
        }

        removeERC721BuyOrder(_buyOrderId);
        s.erc721BuyOrders[_buyOrderId].cancelled = true;

        // refund GHST to buyer
        LibERC20.transfer(s.ghstContract, erc721BuyOrder.buyer, erc721BuyOrder.priceInWei);
    }

    function removeERC721BuyOrder(uint256 _buyOrderId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        ERC721BuyOrder memory erc721BuyOrder = s.erc721BuyOrders[_buyOrderId];
        uint256 _tokenId = erc721BuyOrder.erc721TokenId;
        address _tokenAddress = erc721BuyOrder.erc721TokenAddress;

        uint256 index = s.erc721TokenToBuyOrderIdIndexes[_tokenAddress][_tokenId][_buyOrderId];
        uint256 lastIndex = s.erc721TokenToBuyOrderIds[_tokenAddress][_tokenId].length - 1;
        if (index != lastIndex) {
            uint256 lastBuyOrderId = s.erc721TokenToBuyOrderIds[_tokenAddress][_tokenId][lastIndex];
            s.erc721TokenToBuyOrderIds[_tokenAddress][_tokenId][index] = lastBuyOrderId;
            s.erc721TokenToBuyOrderIdIndexes[_tokenAddress][_tokenId][lastBuyOrderId] = index;
        }
        s.erc721TokenToBuyOrderIds[_tokenAddress][_tokenId].pop();
        delete s.erc721TokenToBuyOrderIdIndexes[_tokenAddress][_tokenId][_buyOrderId];

        delete s.buyerToBuyOrderId[_tokenAddress][_tokenId][erc721BuyOrder.buyer];
    }

    function generateValidationHash(
        address _erc721TokenAddress,
        uint256 _erc721TokenId,
        bool[] memory _validationOptions
    ) internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        //Category is always validated
        uint256 category = LibSharedMarketplace.getERC721Category(_erc721TokenAddress, _erc721TokenId);
        bytes memory _params = abi.encode(_erc721TokenId, category);
        if (category == LibAavegotchi.STATUS_AAVEGOTCHI) {
            // Aavegotchi
            _params = abi.encode(_params, s.aavegotchis[_erc721TokenId].equippedWearables);
            if (_validationOptions[0]) {
                // BRS
                _params = abi.encode(_params, LibAavegotchi.baseRarityScore(s.aavegotchis[_erc721TokenId].numericTraits));
            }
            if (_validationOptions[1]) {
                // GHST
                _params = abi.encode(_params, IERC20(s.ghstContract).balanceOf(s.aavegotchis[_erc721TokenId].escrow));
            }
            if (_validationOptions[2]) {
                // skill points
                _params = abi.encode(_params, s.aavegotchis[_erc721TokenId].usedSkillPoints);
            }
        }
        return keccak256(_params);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import {LibAppStorage, AppStorage, ListingListItem, ERC721Listing} from "./LibAppStorage.sol";
import {LibMeta} from "../../shared/libraries/LibMeta.sol";

import "../../shared/interfaces/IERC721.sol";

// import "hardhat/console.sol";

library LibERC721Marketplace {
    event ERC721ListingCancelled(uint256 indexed listingId, uint256 category, uint256 time);
    event ERC721ListingRemoved(uint256 indexed listingId, uint256 category, uint256 time);
    event ERC721ListingPriceUpdate(uint256 indexed listingId, uint256 priceInWei, uint256 time);

    function cancelERC721Listing(uint256 _listingId, address _owner) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        ListingListItem storage listingItem = s.erc721ListingListItem[_listingId];
        if (listingItem.listingId == 0) {
            return;
        }
        ERC721Listing storage listing = s.erc721Listings[_listingId];
        if (listing.cancelled == true || listing.timePurchased != 0) {
            return;
        }
        require(listing.seller == _owner, "Marketplace: owner not seller");
        listing.cancelled = true;

        //Unlock Aavegotchis when listing is created
        if (listing.erc721TokenAddress == address(this)) {
            s.aavegotchis[listing.erc721TokenId].locked = false;
        }

        emit ERC721ListingCancelled(_listingId, listing.category, block.number);
        removeERC721ListingItem(_listingId, _owner);
    }

    function cancelERC721Listing(address _erc721TokenAddress, uint256 _erc721TokenId, address _owner) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 listingId = s.erc721TokenToListingId[_erc721TokenAddress][_erc721TokenId][_owner];
        if (listingId == 0) {
            return;
        }
        cancelERC721Listing(listingId, _owner);
    }

    function addERC721ListingItem(address _owner, uint256 _category, string memory _sort, uint256 _listingId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 headListingId = s.erc721OwnerListingHead[_owner][_category][_sort];
        if (headListingId != 0) {
            ListingListItem storage headListingItem = s.erc721OwnerListingListItem[headListingId];
            headListingItem.parentListingId = _listingId;
        }
        ListingListItem storage listingItem = s.erc721OwnerListingListItem[_listingId];
        listingItem.childListingId = headListingId;
        s.erc721OwnerListingHead[_owner][_category][_sort] = _listingId;
        listingItem.listingId = _listingId;

        headListingId = s.erc721ListingHead[_category][_sort];
        if (headListingId != 0) {
            ListingListItem storage headListingItem = s.erc721ListingListItem[headListingId];
            headListingItem.parentListingId = _listingId;
        }
        listingItem = s.erc721ListingListItem[_listingId];
        listingItem.childListingId = headListingId;
        s.erc721ListingHead[_category][_sort] = _listingId;
        listingItem.listingId = _listingId;
    }

    function removeERC721ListingItem(uint256 _listingId, address _owner) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        ListingListItem storage listingItem = s.erc721ListingListItem[_listingId];
        if (listingItem.listingId == 0) {
            return;
        }
        uint256 parentListingId = listingItem.parentListingId;
        if (parentListingId != 0) {
            ListingListItem storage parentListingItem = s.erc721ListingListItem[parentListingId];
            parentListingItem.childListingId = listingItem.childListingId;
        }
        uint256 childListingId = listingItem.childListingId;
        if (childListingId != 0) {
            ListingListItem storage childListingItem = s.erc721ListingListItem[childListingId];
            childListingItem.parentListingId = listingItem.parentListingId;
        }
        ERC721Listing storage listing = s.erc721Listings[_listingId];
        if (s.erc721ListingHead[listing.category]["listed"] == _listingId) {
            s.erc721ListingHead[listing.category]["listed"] = listingItem.childListingId;
        }
        listingItem.listingId = 0;
        listingItem.parentListingId = 0;
        listingItem.childListingId = 0;

        listingItem = s.erc721OwnerListingListItem[_listingId];

        parentListingId = listingItem.parentListingId;
        if (parentListingId != 0) {
            ListingListItem storage parentListingItem = s.erc721OwnerListingListItem[parentListingId];
            parentListingItem.childListingId = listingItem.childListingId;
        }
        childListingId = listingItem.childListingId;
        if (childListingId != 0) {
            ListingListItem storage childListingItem = s.erc721OwnerListingListItem[childListingId];
            childListingItem.parentListingId = listingItem.parentListingId;
        }
        listing = s.erc721Listings[_listingId];
        if (s.erc721OwnerListingHead[_owner][listing.category]["listed"] == _listingId) {
            s.erc721OwnerListingHead[_owner][listing.category]["listed"] = listingItem.childListingId;
        }
        listingItem.listingId = 0;
        listingItem.parentListingId = 0;
        listingItem.childListingId = 0;

        emit ERC721ListingRemoved(_listingId, listing.category, block.timestamp);
    }

    function updateERC721Listing(address _erc721TokenAddress, uint256 _erc721TokenId, address _owner) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 listingId = s.erc721TokenToListingId[_erc721TokenAddress][_erc721TokenId][_owner];
        if (listingId == 0) {
            return;
        }
        ERC721Listing storage listing = s.erc721Listings[listingId];
        if (listing.timePurchased != 0 || listing.cancelled == true) {
            return;
        }
        address owner = IERC721(listing.erc721TokenAddress).ownerOf(listing.erc721TokenId);
        if (owner != listing.seller) {
            LibERC721Marketplace.cancelERC721Listing(listingId, listing.seller);
        }
    }

    function updateERC721ListingPrice(uint256 _listingId, uint256 _priceInWei) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        ERC721Listing storage listing = s.erc721Listings[_listingId];
        require(listing.timeCreated != 0, "ERC721Marketplace: listing not found");
        require(listing.timePurchased == 0, "ERC721Marketplace: listing already sold");
        require(listing.cancelled == false, "ERC721Marketplace: listing already cancelled");
        require(listing.seller == LibMeta.msgSender(), "ERC721Marketplace: Not seller of ERC721 listing");

        //comment out until graph event is added
        // s.erc721Listings[_listingId].priceInWei = _priceInWei;

        emit ERC721ListingPriceUpdate(_listingId, _priceInWei, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import {LibAppStorage, AppStorage, GotchiLending, LendingListItem} from "./LibAppStorage.sol";
import "../../shared/interfaces/IERC721.sol";
import {LibERC20} from "../../shared/libraries/LibERC20.sol";
import {IERC20} from "../../shared/interfaces/IERC20.sol";
import {CollateralEscrow} from "../CollateralEscrow.sol";
import {LibAavegotchi} from "./LibAavegotchi.sol";
import {LibWhitelist} from "./LibWhitelist.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IRealmDiamond} from "../../shared/interfaces/IRealmDiamond.sol";

library LibGotchiLending {
    using EnumerableSet for EnumerableSet.UintSet;

    event GotchiLendingAdd(uint32 indexed listingId);
    event GotchiLendingExecute(uint32 indexed listingId);
    event GotchiLendingCancel(uint32 indexed listingId, uint256 time);
    event GotchiLendingClaim(uint32 indexed listingId, address[] tokenAddresses, uint256[] amounts);
    event GotchiLendingEnd(uint32 indexed listingId);
    event GotchiLendingAdded(
        uint32 indexed listingId,
        address indexed lender,
        uint32 indexed tokenId,
        uint96 initialCost,
        uint32 period,
        uint8[3] revenueSplit,
        address originalOwner,
        address thirdParty,
        uint32 whitelistId,
        address[] revenueTokens,
        uint256 timeCreated
    );
    event GotchiLendingExecuted(
        uint32 indexed listingId,
        address indexed lender,
        address indexed borrower,
        uint32 tokenId,
        uint96 initialCost,
        uint32 period,
        uint8[3] revenueSplit,
        address originalOwner,
        address thirdParty,
        uint32 whitelistId,
        address[] revenueTokens,
        uint256 timeAgreed
    );
    event GotchiLendingCanceled(
        uint32 indexed listingId,
        address indexed lender,
        uint32 indexed tokenId,
        uint96 initialCost,
        uint32 period,
        uint8[3] revenueSplit,
        address originalOwner,
        address thirdParty,
        uint32 whitelistId,
        address[] revenueTokens,
        uint256 timeCanceled
    );
    event GotchiLendingClaimed(
        uint32 indexed listingId,
        address indexed lender,
        address indexed borrower,
        uint32 tokenId,
        uint96 initialCost,
        uint32 period,
        uint8[3] revenueSplit,
        address originalOwner,
        address thirdParty,
        uint32 whitelistId,
        address[] revenueTokens,
        uint256[] amounts,
        uint256 timeClaimed
    );
    event GotchiLendingEnded(
        uint32 indexed listingId,
        address indexed lender,
        address indexed borrower,
        uint32 tokenId,
        uint96 initialCost,
        uint32 period,
        uint8[3] revenueSplit,
        address originalOwner,
        address thirdParty,
        uint32 whitelistId,
        address[] revenueTokens,
        uint256 timeEnded
    );

    function getListing(uint32 _listingId) internal view returns (GotchiLending memory listing_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        listing_ = s.gotchiLendings[_listingId];
        require(listing_.timeCreated != 0, "LibGotchiLending: Listing does not exist");
    }

    function whitelistExists(uint32 _whitelistId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.whitelists.length >= _whitelistId;
    }

    function tokenIdToListingId(uint32 _tokenId) internal view returns (uint32 listingId) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        listingId = s.aavegotchiToListingId[_tokenId];
        require(listingId != 0, "LibGotchiLending: Listing not found");
    }

    struct LibAddGotchiLending {
        address lender;
        uint32 tokenId;
        uint96 initialCost;
        uint32 period;
        uint8[3] revenueSplit;
        address originalOwner;
        address thirdParty;
        uint32 whitelistId;
        address[] revenueTokens;
    }

    function _addGotchiLending(LibAddGotchiLending memory _listing) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint32 oldListingId = s.aavegotchiToListingId[_listing.tokenId];
        if (oldListingId != 0) {
            cancelGotchiLending(oldListingId, _listing.lender);
        }
        verifyAddGotchiLendingParams(
            _listing.tokenId,
            _listing.period,
            _listing.revenueSplit,
            _listing.originalOwner,
            _listing.thirdParty,
            _listing.whitelistId,
            _listing.revenueTokens
        );
        uint32 listingId = ++s.nextGotchiListingId; //assigned value after incrementing

        s.aavegotchiToListingId[_listing.tokenId] = listingId;
        s.gotchiLendings[listingId] = GotchiLending({
            listingId: listingId,
            initialCost: _listing.initialCost,
            period: _listing.period,
            revenueSplit: _listing.revenueSplit,
            lender: _listing.lender,
            borrower: address(0),
            originalOwner: _listing.originalOwner,
            thirdParty: _listing.thirdParty,
            erc721TokenId: _listing.tokenId,
            whitelistId: _listing.whitelistId,
            revenueTokens: _listing.revenueTokens,
            timeCreated: uint40(block.timestamp),
            timeAgreed: 0,
            lastClaimed: 0,
            canceled: false,
            completed: false
        });
        addLendingListItem(_listing.lender, listingId, "listed");
        s.aavegotchis[_listing.tokenId].locked = true;

        emit GotchiLendingAdd(listingId);
        emit GotchiLendingAdded(
            listingId,
            _listing.lender,
            _listing.tokenId,
            _listing.initialCost,
            _listing.period,
            _listing.revenueSplit,
            _listing.originalOwner,
            _listing.thirdParty,
            _listing.whitelistId,
            _listing.revenueTokens,
            block.timestamp
        );
    }

    function _agreeGotchiLending(
        address _borrower,
        uint32 _listingId,
        uint32 _erc721TokenId,
        uint96 _initialCost,
        uint32 _period,
        uint8[3] calldata _revenueSplit
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        GotchiLending storage lending = s.gotchiLendings[_listingId];
        verifyAgreeGotchiLendingParams(_borrower, _listingId, _erc721TokenId, _initialCost, _period, _revenueSplit);
        // gas savings
        address lender = lending.lender;

        if (lending.initialCost > 0) {
            LibERC20.transferFrom(s.ghstContract, _borrower, lender, _initialCost);
        }
        lending.borrower = _borrower;
        lending.timeAgreed = uint40(block.timestamp);

        removeLendingListItem(lender, _listingId, "listed");
        addLendingListItem(lender, _listingId, "agreed");

        s.lentTokenIdIndexes[lender][_erc721TokenId] = uint32(s.lentTokenIds[lender].length);
        s.lentTokenIds[lender].push(_erc721TokenId);

        LibAavegotchi.transfer(lender, _borrower, _erc721TokenId);

        // set lender as pet operator
        s.petOperators[_borrower][lender] = true;

        EnumerableSet.UintSet storage whitelistBorrowerGotchiSet = s.whitelistGotchiBorrows[lending.whitelistId][_borrower];
        uint256 borrowLimit = lending.whitelistId == 0
            ? IRealmDiamond(s.realmAddress).balanceOf(_borrower) + 1
            : LibWhitelist.borrowLimit(lending.whitelistId);

        // Check if the whitelist allows multiple borrows
        // If not, register the gotchi id to the whitelist to prevent more borrows
        // We do not need to check for whitelistId = 0 since this whitelistId's borrow limit will always be 0, thus passing this check
        // There is a possibility of setting this borrow limit in an init function in the future for whitelist id 0 if desired
        require(
            borrowLimit == 0 || borrowLimit > whitelistBorrowerGotchiSet.length(),
            "LibGotchiLending: Borrower is over borrow limit for the limit set by whitelist owner"
        );
        whitelistBorrowerGotchiSet.add(_erc721TokenId);

        emit GotchiLendingExecute(_listingId);
        emit GotchiLendingExecuted(
            _listingId,
            lending.lender,
            _borrower,
            _erc721TokenId,
            lending.initialCost,
            lending.period,
            lending.revenueSplit,
            lending.originalOwner,
            lending.thirdParty,
            lending.whitelistId,
            lending.revenueTokens,
            block.timestamp
        );
    }

    function cancelGotchiLending(uint32 _listingId, address _lender) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        GotchiLending storage lending = s.gotchiLendings[_listingId];
        if (lending.canceled) {
            return;
        }
        require(lending.timeAgreed == 0, "LibGotchiLending: Listing already agreed");
        lending.canceled = true;

        removeLendingListItem(_lender, _listingId, "listed");

        //Unlock Aavegotchis when lending is created
        s.aavegotchis[lending.erc721TokenId].locked = false;
        s.aavegotchiToListingId[lending.erc721TokenId] = 0;

        emit GotchiLendingCancel(_listingId, block.timestamp);
        emit GotchiLendingCanceled(
            _listingId,
            lending.lender,
            lending.erc721TokenId,
            lending.initialCost,
            lending.period,
            lending.revenueSplit,
            lending.originalOwner,
            lending.thirdParty,
            lending.whitelistId,
            lending.revenueTokens,
            block.timestamp
        );
    }

    function cancelGotchiLendingFromToken(uint32 _erc721TokenId, address _lender) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        cancelGotchiLending(s.aavegotchiToListingId[_erc721TokenId], _lender);
    }

    function claimGotchiLending(uint32 listingId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        GotchiLending storage lending = s.gotchiLendings[listingId];

        uint256[] memory amounts = new uint256[](lending.revenueTokens.length);
        address escrow = s.aavegotchis[lending.erc721TokenId].escrow;

        require(escrow != address(0), "LibGotchiLending: Escrow is zero address");

        address collateralType = s.aavegotchis[lending.erc721TokenId].collateralType;
        for (uint256 i; i < lending.revenueTokens.length; ) {
            address revenueToken = lending.revenueTokens[i];
            uint256 balance = IERC20(revenueToken).balanceOf(escrow);

            if (collateralType == revenueToken || balance == 0) {
                amounts[i] = 0; //gotchi collateral can never be a revenue token
            } else {
                amounts[i] = balance;

                if (IERC20(revenueToken).allowance(escrow, address(this)) < balance) {
                    CollateralEscrow(escrow).approveAavegotchiDiamond(revenueToken);
                }

                uint256 ownerAmount = (balance * lending.revenueSplit[0]) / 100;
                uint256 borrowerAmount = (balance * lending.revenueSplit[1]) / 100;
                address owner = lending.originalOwner == address(0) ? lending.lender : lending.originalOwner;
                if (ownerAmount > 0) {
                    LibERC20.transferFrom(revenueToken, escrow, owner, ownerAmount);
                }
                if (borrowerAmount > 0) {
                    LibERC20.transferFrom(revenueToken, escrow, lending.borrower, borrowerAmount);
                }
                if (lending.thirdParty != address(0)) {
                    uint256 thirdPartyAmount = (balance * lending.revenueSplit[2]) / 100;
                    LibERC20.transferFrom(revenueToken, escrow, lending.thirdParty, thirdPartyAmount);
                }
            }
            unchecked {
                ++i;
            }
        }

        lending.lastClaimed = uint40(block.timestamp);

        emit GotchiLendingClaim(listingId, lending.revenueTokens, amounts);
        emit GotchiLendingClaimed(
            listingId,
            lending.lender,
            lending.borrower,
            lending.erc721TokenId,
            lending.initialCost,
            lending.period,
            lending.revenueSplit,
            lending.originalOwner,
            lending.thirdParty,
            lending.whitelistId,
            lending.revenueTokens,
            amounts,
            block.timestamp
        );
    }

    /// @dev Checks should be done before calling this function
    function endGotchiLending(GotchiLending storage lending) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // gas savings
        uint32 tokenId = lending.erc721TokenId;
        address lender = lending.lender;
        uint32 listingId = s.aavegotchiToListingId[tokenId];

        // STATE CHANGES
        s.aavegotchis[tokenId].locked = false;
        LibAavegotchi.transfer(lending.borrower, lender, tokenId);
        lending.completed = true;
        s.aavegotchiToListingId[tokenId] = 0;

        removeLentAavegotchi(tokenId, lender);
        removeLendingListItem(lender, lending.listingId, "agreed");
        // scope to avoid stack too deep
        {
            EnumerableSet.UintSet storage whitelistBorrowerGotchiSet = s.whitelistGotchiBorrows[lending.whitelistId][lending.borrower];
            // Remove token id from borrower's list of borrowed gotchis. Does not revert if it the element does not exist
            whitelistBorrowerGotchiSet.remove(lending.erc721TokenId);
        }
        emit GotchiLendingEnd(listingId);
        emit GotchiLendingEnded(
            listingId,
            lending.lender,
            lending.borrower,
            lending.erc721TokenId,
            lending.initialCost,
            lending.period,
            lending.revenueSplit,
            lending.originalOwner,
            lending.thirdParty,
            lending.whitelistId,
            lending.revenueTokens,
            block.timestamp
        );
    }

    function verifyAddGotchiLendingParams(
        uint32 _erc721TokenId,
        uint32 _period,
        uint8[3] memory _revenueSplit,
        address _originalOwner,
        address _thirdParty,
        uint32 _whitelistId,
        address[] memory _revenueTokens
    ) internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_originalOwner != address(0), "LibGotchiLending: Original owner cannot be zero address");
        require(checkPeriod(_period), "LibGotchiLending: Period is not valid");
        require(checkRevenueParams(_revenueSplit, _revenueTokens, _thirdParty), "LibGotchiLending: Revenue parameters are not valid");
        require(whitelistExists(_whitelistId) || (_whitelistId == 0), "LibGotchiLending: Whitelist not found");
        require(s.aavegotchis[_erc721TokenId].status == LibAavegotchi.STATUS_AAVEGOTCHI, "LibGotchiLending: Can only lend Aavegotchi");
        require(!s.aavegotchis[_erc721TokenId].locked, "LibGotchiLending: Only callable on unlocked Aavegotchis");
    }

    function verifyAgreeGotchiLendingParams(
        address _borrower,
        uint32 _listingId,
        uint32 _erc721TokenId,
        uint96 _initialCost,
        uint32 _period,
        uint8[3] calldata _revenueSplit
    ) internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        GotchiLending storage lending = s.gotchiLendings[_listingId];
        require(lending.timeCreated != 0, "LibGotchiLending: Listing not found");
        require(lending.timeAgreed == 0, "LibGotchiLending: Listing already agreed");
        require(lending.canceled == false, "LibGotchiLending: Listing canceled");
        require(lending.erc721TokenId == _erc721TokenId, "LibGotchiLending: Invalid token id");
        require(lending.initialCost == _initialCost, "LibGotchiLending: Invalid initial cost");
        require(lending.period == _period, "LibGotchiLending: Invalid lending period");
        for (uint256 i; i < 3; ) {
            require(lending.revenueSplit[i] == _revenueSplit[i], "LibGotchiLending: Invalid revenue split");
            unchecked {
                ++i;
            }
        }
        require(lending.lender != _borrower, "LibGotchiLending: Borrower can't be lender");
        if (lending.whitelistId > 0) {
            require(s.isWhitelisted[lending.whitelistId][_borrower] > 0, "LibGotchiLending: Not whitelisted address");
        }
        // Removed balance check for GHST since this will revert anyway if transferFrom is called
        //require(IERC20(s.ghstContract).balanceOf(_borrower) >= lending.initialCost, "GotchiLending: Not enough GHST");
    }

    function removeLentAavegotchi(uint32 _tokenId, address _lender) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Remove indexed data for lender
        uint32 index = s.lentTokenIdIndexes[_lender][_tokenId];
        uint32 lastIndex = uint32(s.lentTokenIds[_lender].length - 1);
        if (index != lastIndex) {
            uint32 lastTokenId = s.lentTokenIds[_lender][lastIndex];
            s.lentTokenIds[_lender][index] = lastTokenId;
            s.lentTokenIdIndexes[_lender][lastTokenId] = index;
        }
        s.lentTokenIds[_lender].pop();
        delete s.lentTokenIdIndexes[_lender][_tokenId];
    }

    function enforceAavegotchiNotInLending(uint32 _tokenId, address _sender) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint32 _listingId = s.aavegotchiToListingId[_tokenId];
        if (_listingId > 0) {
            GotchiLending storage _lending = s.gotchiLendings[_listingId];
            require(_lending.lender == _sender, "LibGotchiLending: Aavegotchi is in lending");
            if (_lending.timeAgreed > 0) {
                // revert if agreed lending
                revert("LibGotchiLending: Aavegotchi is in lending");
            } else {
                // cancel if not agreed lending
                cancelGotchiLending(_listingId, _sender);
            }
        }
    }

    function isAavegotchiListed(uint32 _tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint32 listingId = s.aavegotchiToListingId[_tokenId];
        GotchiLending memory lending = s.gotchiLendings[listingId];
        return listingId > 0 && lending.timeCreated > 0;
    }

    function isAavegotchiLent(uint32 _tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (!isAavegotchiListed(_tokenId)) return false;
        uint32 listingId = s.aavegotchiToListingId[_tokenId];
        GotchiLending storage listing_ = s.gotchiLendings[listingId];
        return (listing_.timeAgreed != 0 && !listing_.completed);
    }

    function checkPeriod(uint32 _period) internal pure returns (bool) {
        return _period > 0 && _period <= 2_592_000; //No reason to have a period longer than 30 days
    }

    function checkRevenueParams(uint8[3] memory _revenueSplit, address[] memory _revenueTokens, address _thirdParty) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_revenueSplit[0] + _revenueSplit[1] + _revenueSplit[2] == 100, "LibGotchiLending: Sum of revenue splits not 100");
        for (uint256 i = 0; i < _revenueTokens.length; ) {
            require(s.revenueTokenAllowed[_revenueTokens[i]], "LibGotchiLending: Revenue token not allowed");
            unchecked {
                ++i;
            }
        }
        if (_thirdParty == address(0)) {
            require(_revenueSplit[2] == 0, "LibGotchiLending: Third party revenue split must be 0 without a third party");
        }
        require(_revenueTokens.length <= 10, "LibGotchiLending: Too many revenue tokens"); //Prevent claimAndEnd from reverting due to Out of Gas

        return true;
    }

    function addLendingListItem(address _lender, uint32 _listingId, bytes32 _status) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint32 headListingId = s.aavegotchiLenderLendingHead[_lender][_status];
        if (headListingId != 0) {
            LendingListItem storage headLendingItem = s.aavegotchiLenderLendingListItem[_status][headListingId];
            headLendingItem.parentListingId = _listingId;
        }
        LendingListItem storage lendingItem = s.aavegotchiLenderLendingListItem[_status][_listingId];
        lendingItem.childListingId = headListingId;
        s.aavegotchiLenderLendingHead[_lender][_status] = _listingId;
        lendingItem.listingId = _listingId;

        headListingId = s.gotchiLendingHead[_status];
        if (headListingId != 0) {
            LendingListItem storage headLendingItem = s.gotchiLendingListItem[_status][headListingId];
            headLendingItem.parentListingId = _listingId;
        }
        lendingItem = s.gotchiLendingListItem[_status][_listingId];
        lendingItem.childListingId = headListingId;
        s.gotchiLendingHead[_status] = _listingId;
        lendingItem.listingId = _listingId;
    }

    function removeLendingListItem(address _lender, uint32 _listingId, bytes32 _status) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        LendingListItem storage lendingItem = s.gotchiLendingListItem[_status][_listingId];
        if (lendingItem.listingId == 0) {
            return;
        }
        uint32 parentListingId = lendingItem.parentListingId;
        if (parentListingId != 0) {
            LendingListItem storage parentLendingItem = s.gotchiLendingListItem[_status][parentListingId];
            parentLendingItem.childListingId = lendingItem.childListingId;
        }
        uint32 childListingId = lendingItem.childListingId;
        if (childListingId != 0) {
            LendingListItem storage childLendingItem = s.gotchiLendingListItem[_status][childListingId];
            childLendingItem.parentListingId = lendingItem.parentListingId;
        }

        if (s.gotchiLendingHead[_status] == _listingId) {
            s.gotchiLendingHead[_status] = lendingItem.childListingId;
        }
        lendingItem.listingId = 0;
        lendingItem.parentListingId = 0;
        lendingItem.childListingId = 0;

        lendingItem = s.aavegotchiLenderLendingListItem[_status][_listingId];
        parentListingId = lendingItem.parentListingId;
        if (parentListingId != 0) {
            LendingListItem storage parentLendingItem = s.aavegotchiLenderLendingListItem[_status][parentListingId];
            parentLendingItem.childListingId = lendingItem.childListingId;
        }
        childListingId = lendingItem.childListingId;
        if (childListingId != 0) {
            LendingListItem storage childLendingItem = s.aavegotchiLenderLendingListItem[_status][childListingId];
            childLendingItem.parentListingId = lendingItem.parentListingId;
        }

        if (s.aavegotchiLenderLendingHead[_lender][_status] == _listingId) {
            s.aavegotchiLenderLendingHead[_lender][_status] = lendingItem.childListingId;
        }
        lendingItem.listingId = 0;
        lendingItem.parentListingId = 0;
        lendingItem.childListingId = 0;
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

import {LibMeta} from "../../shared/libraries/LibMeta.sol";
import {LibAppStorage, AppStorage, Whitelist} from "../libraries/LibAppStorage.sol";

library LibWhitelist {
    event WhitelistAccessRightSet(uint32 indexed whitelistId, uint256 indexed actionRight, uint256 indexed accessRight);

    function getNewWhitelistId() internal view returns (uint32 whitelistId) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        whitelistId = uint32(s.whitelists.length + 1); //whitelistId 0 is reserved for "none" in GotchiLending struct
    }

    function _whitelistExists(uint32 whitelistId) internal view returns (bool exists) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        exists = (s.whitelists.length >= whitelistId) && (whitelistId > 0);
    }

    function getWhitelistFromWhitelistId(uint32 whitelistId) internal view returns (Whitelist storage whitelist) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_whitelistExists(whitelistId), "WhitelistFacet: Whitelist not found");
        whitelist = s.whitelists[whitelistId - 1];
    }

    function checkWhitelistOwner(uint32 whitelistId) internal view returns (bool isOwner) {
        Whitelist storage whitelist = getWhitelistFromWhitelistId(whitelistId);
        isOwner = whitelist.owner == LibMeta.msgSender();
    }

    function _addAddressToWhitelist(uint32 _whitelistId, address _whitelistAddress) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.isWhitelisted[_whitelistId][_whitelistAddress] == 0) {
            Whitelist storage whitelist = LibWhitelist.getWhitelistFromWhitelistId(_whitelistId);
            whitelist.addresses.push(_whitelistAddress);
            s.isWhitelisted[_whitelistId][_whitelistAddress] = whitelist.addresses.length; // Index of the whitelist entry + 1
        }
    }

    function _removeAddressFromWhitelist(uint32 _whitelistId, address _whitelistAddress) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.isWhitelisted[_whitelistId][_whitelistAddress] > 0) {
            Whitelist storage whitelist = LibWhitelist.getWhitelistFromWhitelistId(_whitelistId);
            uint256 index = s.isWhitelisted[_whitelistId][_whitelistAddress] - 1;
            uint256 lastIndex = whitelist.addresses.length - 1;
            // Replaces the element to be removed with the last element
            whitelist.addresses[index] = whitelist.addresses[lastIndex];
            // Store the last element in memory
            address lastElement = whitelist.addresses[lastIndex];
            // Remove the last element from storage
            whitelist.addresses.pop();
            // Update the index of the last element that was swapped. If this is the only element, updates to zero on the next line
            s.isWhitelisted[_whitelistId][lastElement] = index + 1;
            // Update the index of the removed element
            s.isWhitelisted[_whitelistId][_whitelistAddress] = 0;
        }
    }

    function _addAddressesToWhitelist(uint32 _whitelistId, address[] calldata _whitelistAddresses) internal {
        for (uint256 i; i < _whitelistAddresses.length; i++) {
            _addAddressToWhitelist(_whitelistId, _whitelistAddresses[i]);
        }
    }

    function _removeAddressesFromWhitelist(uint32 _whitelistId, address[] calldata _whitelistAddresses) internal {
        for (uint256 i; i < _whitelistAddresses.length; i++) {
            _removeAddressFromWhitelist(_whitelistId, _whitelistAddresses[i]);
        }
    }

    function setWhitelistAccessRight(
        uint32 _whitelistId,
        uint256 _actionRight,
        uint256 _accessRight
    ) internal {
        require(_isAccessRightValid(_actionRight, _accessRight), "LibWhitelist: Invalid Rights");
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.whitelistAccessRights[_whitelistId][_actionRight] = _accessRight;
        emit WhitelistAccessRightSet(_whitelistId, _actionRight, _accessRight);
    }

    function _isAccessRightValid(uint256 _actionRight, uint256 _accessRight) internal pure returns (bool) {
        // This action right limits borrowers in a whitelist to a number of borrowed gotchis. 0 is unlimited
        if (_actionRight == 0) {
            return true;
        } else {
            return false;
        }
    }

    function borrowLimit(uint32 _whitelistId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.whitelistAccessRights[_whitelistId][0];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/******************************************************************************\
* Author: Nick Mudge <[email protected]ctabstractions.com> (https://twitter.com/mudgen)
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

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
/* is ERC165 */
interface IERC721 {
    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata data
    ) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRealmDiamond {
    function balanceOf(address _owner) external view returns (uint256 balance_);
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

import "../interfaces/IERC721TokenReceiver.sol";

library LibERC721 {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

    function checkOnERC721Received(
        address _operator,
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_to)
        }
        if (size > 0) {
            require(
                ERC721_RECEIVED == IERC721TokenReceiver(_to).onERC721Received(_operator, _from, _tokenId, _data),
                "AavegotchiFacet: Transfer rejected/failed by _to"
            );
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