// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Tracker Contract
/// @author Sleepn
/// @notice The Tracker Contract is used to track the NFTs
contract Tracker {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev Struct to store the NFT IDs of a user
    struct NftsID {
        EnumerableSet.UintSet bedroomNfts;
        EnumerableSet.UintSet upgradeNfts;
    }
    /// @dev Struct to store the amounts owned of a NFT ID
    struct UpgradeNft {
        uint256 amountOwned;
        uint256 amountUsed;
        EnumerableSet.UintSet bedroomNftIds;
    }

    /// @dev Set of Upgrade NFTs ID settled
    EnumerableSet.UintSet private upgradeNftIdsSettled;

    /// @dev Maps the NFTs ID Sets to an owner
    mapping(address => NftsID) private ownerToNftsID;
    /// @dev Maps the Upgrade NFTs amounts to an owner and an NFT ID
    mapping(uint256 => mapping(address => UpgradeNft)) private upgradeNftsOwned;
    /// @dev Maps a set of owners to an Upgrade NFT ID
    mapping(uint256 => EnumerableSet.AddressSet) private upgradeNftToOwners;
    /// @dev Maps a set of Upgrade NFT IDs to a Bedroom NFT ID
    mapping(uint256 => EnumerableSet.UintSet) private bedroomNftToUpgradeNfts;

    /// @notice Bedroom NFT Contract address
    address public immutable bedroomNftContract;
    /// @notice Upgrade NFT Contract address
    address public immutable upgradeNftContract;
    /// @notice Upgrader Contract address
    address public immutable upgraderContract;

    /// @notice Restricted Access Error - Wrong caller
    error RestrictedAccess(address caller);
    /// @notice Invalid NFT ID Error - NFT ID is invalid
    error IdAlreadyUsed(uint256 tokenId);

    /// @notice BedroomNft ID Linked To Wallet Event
    event BedroomNftLinkedToWallet(
        uint256 indexed bedroomNftId,
        address indexed owner
    );
    /// @notice BedroomNft ID Unlinked From Wallet Event
    event BedroomNftUnlinkedFromWallet(
        uint256 indexed bedroomNftId,
        address indexed owner
    );
    /// @notice UpgradeNft ID Linked To Wallet Event
    event UpgradeNftLinkedToWallet(
        uint256 indexed upgradeNftId,
        address indexed owner
    );
    /// @notice UpgradeNft ID Unlinked From Wallet Event
    event UpgradeNftUnlinkedFromWallet(
        uint256 indexed upgradeNftId,
        address indexed owner
    );
    /// @notice UpgradeNft ID Linked To BedroomNft ID Event
    event UpgradeNftLinkedToBedroomNft(
        uint256 indexed upgradeNftId,
        uint256 indexed bedroomNftId
    );
    /// @notice UpgradeNft ID Unlinked From BedroomNft ID Event
    event UpgradeNftUnlinkedFromBedroomNft(
        uint256 indexed upgradeNftId,
        uint256 indexed bedroomNftId
    );

    /// @notice Constructor
    /// @param _bedroomNftAddress Bedroom NFT Contract address
    /// @param _upgradeNftAddress Upgrade NFT Contract address
    constructor(address _bedroomNftAddress, address _upgradeNftAddress) {
        bedroomNftContract = _bedroomNftAddress;
        upgradeNftContract = _upgradeNftAddress;
        upgraderContract = msg.sender;
    }

    /// @notice Gets the NFTs owned by an address
    /// @param _owner The address of the owner
    /// @return _bedroomNfts The Bedroom NFTs owned by the address
    /// @return _upgradeNfts The Upgrade NFTs owned by the address
    function getNftsID(address _owner)
        external
        view
        returns (uint256[] memory _bedroomNfts, uint256[] memory _upgradeNfts)
    {
        _bedroomNfts = ownerToNftsID[_owner].bedroomNfts.values();
        _upgradeNfts = ownerToNftsID[_owner].upgradeNfts.values();
    }

    /// @notice Adds a Bedroom NFT ID to the tracker
    /// @param _owner The owner of the NFT
    /// @param _tokenId The NFT ID
    /// @return stateUpdated Returns true if the update worked
    function addBedroomNft(address _owner, uint256 _tokenId)
        external
        returns (bool)
    {
        if (msg.sender != bedroomNftContract) {
            revert RestrictedAccess(msg.sender);
        }
        emit BedroomNftLinkedToWallet(_tokenId, _owner);
        return ownerToNftsID[_owner].bedroomNfts.add(_tokenId);
    }

    /// @notice Remove a Bedroom NFT from the tracker
    /// @param _owner The owner of the Bedroom NFT
    /// @param _newOwner The new owner of the Bedroom NFT
    /// @param _tokenId The ID of the Bedroom NFT
    /// @return stateUpdated Returns true if the update worked
    function removeBedroomNft(
        address _owner,
        address _newOwner,
        uint256 _tokenId
    ) external returns (bool) {
        if (msg.sender != bedroomNftContract) {
            revert RestrictedAccess(msg.sender);
        }
        for (
            uint256 i = 0; i < bedroomNftToUpgradeNfts[_tokenId].length(); i++
        ) {
            uint256 upgradeNftId = bedroomNftToUpgradeNfts[_tokenId].at(i);
            bool isRemoved = removeUpgradeNft(_owner, upgradeNftId);
            bool idAdded = addUpgradeNft(_newOwner, upgradeNftId);
            if (!isRemoved || !idAdded) {
                return false;
            }
        }
        if (ownerToNftsID[_owner].bedroomNfts.remove(_tokenId)) {
            emit BedroomNftUnlinkedFromWallet(_tokenId, _owner);
            return true;
        }
        return false;
    }

    /// @notice Returns true if the owner of the bedroom NFT is the wallet address
    /// @param _tokenId The ID of the bedroom NFT
    /// @param _wallet The wallet address of the owner
    /// @return isOwner True if the owner of the bedroom NFT is the wallet address
    function isBedroomNftOwner(uint256 _tokenId, address _wallet)
        external
        view
        returns (bool isOwner)
    {
        isOwner = ownerToNftsID[_wallet].bedroomNfts.contains(_tokenId);
    }

    /// @notice Returns the amount of bedroom NFTs owned by an owner
    /// @param _owner The owner of the bedroom NFTs
    /// @return nftsAmount The amount of bedroom NFTs owned by the owner
    function getBedroomNftsAmount(address _owner)
        external
        view
        returns (uint256 nftsAmount)
    {
        nftsAmount = ownerToNftsID[_owner].bedroomNfts.length();
    }

    /// @notice Adds an upgrade NFT ID to the settled upgrade NFT IDs
    /// @param _tokenId The ID of the upgrade NFT
    function settleUpgradeNftData(uint256 _tokenId) external {
        if (msg.sender != upgradeNftContract) {
            revert RestrictedAccess(msg.sender);
        }
        if (upgradeNftIdsSettled.contains(_tokenId)) {
            revert IdAlreadyUsed(_tokenId);
        }
        upgradeNftIdsSettled.add(_tokenId);
    }

    /// @notice Returns the upgrade NFT IDs that have been settled
    /// @return nftIdsSettled The upgrade NFT IDs that have been settled
    function getUpgradeNftSettled()
        external
        view
        returns (uint256[] memory nftIdsSettled)
    {
        nftIdsSettled = upgradeNftIdsSettled.values();
    }

    /// @notice Returns true if the Upgrade NFT ID is settled
    /// @param _tokenId The ID of the Upgrade NFT
    /// @return isSettled True if the Upgrade NFT ID is settled
    function isIdSettled(uint256 _tokenId)
        external
        view
        returns (bool isSettled)
    {
        isSettled = upgradeNftIdsSettled.contains(_tokenId);
    }

    /// @notice Adds an upgrade NFT to the tracker
    /// @param _owner The owner of the upgrade NFT
    /// @param _tokenId The ID of the upgrade NFT
    /// @return stateUpdated Returns true if the update worked
    function addUpgradeNft(address _owner, uint256 _tokenId)
        public
        returns (bool)
    {
        if (
            msg.sender != upgradeNftContract
                && msg.sender != bedroomNftContract
        ) {
            revert RestrictedAccess(msg.sender);
        }
        ownerToNftsID[_owner].upgradeNfts.add(_tokenId);
        upgradeNftToOwners[_tokenId].add(_owner);
        ++upgradeNftsOwned[_tokenId][_owner].amountOwned;
        emit UpgradeNftLinkedToWallet(_tokenId, _owner);
        return true;
    }

    /// @notice Removes an upgrade NFT from the tracker
    /// @param _owner The owner of the upgrade NFT
    /// @param _tokenId The ID of the upgrade NFT
    /// @return stateUpdated Returns true if the update worked
    function removeUpgradeNft(address _owner, uint256 _tokenId)
        public
        returns (bool)
    {
        if (
            msg.sender != upgradeNftContract
                && msg.sender != bedroomNftContract
        ) {
            revert RestrictedAccess(msg.sender);
        }
        --upgradeNftsOwned[_tokenId][_owner].amountOwned;
        if (upgradeNftsOwned[_tokenId][_owner].amountOwned == 0) {
            bool isRemoved1 =
                ownerToNftsID[_owner].upgradeNfts.remove(_tokenId);
            bool isRemoved2 = upgradeNftToOwners[_tokenId].remove(_owner);
            if (!isRemoved1 || !isRemoved2) {
                return false;
            }
        }
        emit UpgradeNftUnlinkedFromWallet(_tokenId, _owner);
        return true;
    }

    /// @notice Returns true if the given address is the owner of the given Upgrade NFT
    /// @param _tokenId The ID of the Upgrade NFT to check
    /// @param _wallet The address to check
    /// @return isOwner True if the given address is the owner of the given Upgrade NFT
    function isUpgradeNftOwner(uint256 _tokenId, address _wallet)
        external
        view
        returns (bool isOwner)
    {
        isOwner = ownerToNftsID[_wallet].upgradeNfts.contains(_tokenId);
    }

    /// @notice Returns the amount of Upgrade NFTs owned by a wallet
    /// @param _owner The owner wallet address
    /// @return nftsAmount The amount of Upgrade NFTs owned by the wallet
    function getUpgradeNftsAmount(address _owner)
        external
        view
        returns (uint256 nftsAmount)
    {
        EnumerableSet.UintSet storage set = ownerToNftsID[_owner].upgradeNfts;
        for (uint256 i = 0; i < set.length(); ++i) {
            uint256 tokenId = set.at(i);
            nftsAmount += upgradeNftsOwned[tokenId][_owner].amountOwned;
        }
    }

    /// @notice Returns the amounts of a specific Upgrade NFT owned by a specific wallet
    /// @param _owner The owner wallet address
    /// @param _tokenId The ID of the Upgrade NFT
    /// @return amountOwned The amount of Upgrade NFTs owned by the wallet
    /// @return amountUsed The amount of Upgrade NFTs used by the wallet
    function getUpgradeNftAmounts(address _owner, uint256 _tokenId)
        external
        view
        returns (uint256 amountOwned, uint256 amountUsed)
    {
        amountOwned = upgradeNftsOwned[_tokenId][_owner].amountOwned;
        amountUsed = upgradeNftsOwned[_tokenId][_owner].amountUsed;
    }

    /// @notice Returns the owners of a specified Upgrade NFT
    /// @param _tokenId The upgrade NFT ID
    /// @return owners Owners of the specified Upgrade NFT
    function getUpgradeNftOwners(uint256 _tokenId)
        external
        view
        returns (address[] memory owners)
    {
        owners = upgradeNftToOwners[_tokenId].values();
    }

    /// @notice Links an upgrade NFT to a Bedroom NFT
    /// @param _owner The owner of the upgrade NFT
    /// @param _bedroomNftId The ID of the bedroom NFT
    /// @param _upgradeNftId The ID of the upgrade NFT
    /// @return stateUpdated Returns true if the update worked
    function linkUpgradeNft(
        address _owner,
        uint256 _bedroomNftId,
        uint256 _upgradeNftId
    ) external returns (bool) {
        if (msg.sender != upgraderContract) {
            revert RestrictedAccess(msg.sender);
        }
        bedroomNftToUpgradeNfts[_bedroomNftId].add(_upgradeNftId);
        ++upgradeNftsOwned[_upgradeNftId][_owner].amountUsed;
        emit UpgradeNftLinkedToBedroomNft(_upgradeNftId, _bedroomNftId);
        return true;
    }

    /// @notice Unlinks an upgrade NFT to a Bedroom NFT
    /// @param _owner The owner of the upgrade NFT
    /// @param _bedroomNftId The ID of the bedroom NFT
    /// @param _upgradeNftId The ID of the upgrade NFT
    /// @return stateUpdated Returns true if the update worked
    function unlinkUpgradeNft(
        address _owner,
        uint256 _bedroomNftId,
        uint256 _upgradeNftId
    ) external returns (bool) {
        if (msg.sender != upgraderContract) {
            revert RestrictedAccess(msg.sender);
        }
        --upgradeNftsOwned[_upgradeNftId][_owner].amountUsed;
        if (upgradeNftsOwned[_upgradeNftId][_owner].amountUsed == 0) {
            if (!bedroomNftToUpgradeNfts[_bedroomNftId].remove(_upgradeNftId))
            {
                return false;
            }
        }
        emit UpgradeNftUnlinkedFromBedroomNft(_upgradeNftId, _bedroomNftId);
        return true;
    }

    /// @notice Returns the upgrade NFTs linked to a Bedroom NFT
    /// @param _bedroomNftId The ID of the bedroom NFT
    /// @return upgradeNfts The upgrade NFTs linked to the Bedroom NFT
    function getUpgradeNfts(uint256 _bedroomNftId)
        external
        view
        returns (uint256[] memory upgradeNfts)
    {
        upgradeNfts = bedroomNftToUpgradeNfts[_bedroomNftId].values();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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