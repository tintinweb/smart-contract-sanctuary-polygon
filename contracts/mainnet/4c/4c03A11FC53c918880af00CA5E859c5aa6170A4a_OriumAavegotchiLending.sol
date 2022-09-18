// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { IERC721 } from "./interfaces/IERC721.sol";
import { IGotchiLendingFacet, AddGotchiListing } from "./interfaces/IGotchiLendingFacet.sol";
import { ILendingGetterAndSetterFacet } from "./interfaces/ILendingGetterAndSetterFacet.sol";
import { IAavegotchiFacet } from "./interfaces/IAavegotchiFacet.sol";
import { AavegotchiInfo, GotchiLending } from "./libraries/LibAavegotchiStorage.sol";

uint8 constant STATUS_AAVEGOTCHI = 3;

contract OriumAavegotchiLending is OwnableUpgradeable {
    using EnumerableSet for EnumerableSet.UintSet;

    uint32 public constant _30_DAYS = 30*24*60*60;

    uint8 public _fee;
    address[] public _tokens;
    address public _aavegotchiDiamondAddress;
    address public _gelatoAddress;
    uint256 public _maxActions;
    EnumerableSet.UintSet private _tokenIds;
    mapping(uint256 => AddGotchiListing) public _listingsParameters;

    event BatchSchedule(
        address indexed owner, uint32[] tokenIds, uint96 initialCost, uint32 period,
        uint8 lenderSplit, uint8 borrowerSplit, uint32 indexed whitelistId
    );
    event BatchUnschedule(address indexed owner, uint32[] tokenIds);

    modifier onlyGelato() {
        require(msg.sender == _gelatoAddress, "Only Gelato can invoke this function");
        _;
    }

    // @notice Proxy initializer function. Should be only callable once
    // @param aavegotchiDiamondContract The aavegotchi diamond contract
    // @param gelatoOps address for gelato executors smart contracts
    function initialize(
        address aavegotchiDiamondContract, address gelatoAddress, uint8 fee, uint256 maxActions, address[] memory tokens
    ) public initializer {
        _fee = fee;
        _maxActions = maxActions;
        _tokens = tokens;
        _gelatoAddress = gelatoAddress;
        _aavegotchiDiamondAddress = aavegotchiDiamondContract;
        __Ownable_init_unchained();
    }

    // == Owner Only Functions =========================================================================================

    // @notice Allow owner to update third-party share-profit fees
    // @param fees New fee schedule
    function updateFeeSchedule(uint8 fee) external onlyOwner {
        _fee = fee;
    }

    // @notice Allow owner to update Gelato address
    // @param gelato New Gelato address
    function updateGelatoAddress(address gelato) external onlyOwner {
        _gelatoAddress = gelato;
    }

    // @notice Allow owner to update Aavegotchi Diamond address
    // @param aavegotchiDiamondAddress New Aavegotchi Diamond address
    function updateAavegotchiDiamondAddress(address aavegotchiDiamondAddress) external onlyOwner {
        _aavegotchiDiamondAddress = aavegotchiDiamondAddress;
    }

    // @notice Allow owner to update token address list
    // @param tokens New token address list
    function updateTokenAddressList(address[] memory tokens) external onlyOwner {
        _tokens = tokens;
    }

    // @notice Allow owner to update max number of actions processed at a time
    // @param max_actions Number of actions
    function updateMaxNumberOfActions(uint256 max_actions) external onlyOwner {
        _maxActions = max_actions;
    }

    function withdrawTokens(address to) external onlyOwner {
        for (uint256 i ; i < _tokens.length; i++) {
            IERC20 token = IERC20(_tokens[i]);
            uint256 balance = token.balanceOf(address(this));
            if (balance > 0) {
                token.transfer(to, balance);
            }
        }
    }

    // == Gelato Only Functions ========================================================================================

    // @notice Batch create lendings based on their scheduled parameters
    // @param tokenIds List of tokenIds to be listed
    function createLendings(uint32[] calldata tokenIds) private {
        AddGotchiListing[] memory listings = new AddGotchiListing[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; i++) {
            listings[i] = _listingsParameters[tokenIds[i]];
        }
        IGotchiLendingFacet(_aavegotchiDiamondAddress).batchAddGotchiListing(listings);
    }

    // @notice Remove lendings from the list. Only called when Lending Operator approval is revoked
    // @param tokenIds List of tokenIds to be removed
    function removeLendings(uint32[] calldata tokenIds) private {
        ILendingGetterAndSetterFacet lendingGetterAndSetterFacet = ILendingGetterAndSetterFacet(_aavegotchiDiamondAddress);
        for (uint256 i; i < tokenIds.length; i++) {
            uint32 tokenId = tokenIds[i];
            address owner = IERC721(_aavegotchiDiamondAddress).ownerOf(tokenId);
            bool isLendingOperator = lendingGetterAndSetterFacet.isLendingOperator(owner, address(this), tokenId);
            if (isLendingOperator == false) {
                EnumerableSet.remove(_tokenIds, tokenId);
                delete _listingsParameters[tokenId];
            }
        }
    }

    // @notice Claims, list and remove Nft lendings
    // @param listNfts Ids of the tokens to be listed
    // @param claimAndListNfts Ids of the Nfts to be claimed and relisted
    // @param removeNfts Ids of the Nfts to be removed
    function manageLendings(
        uint32[] calldata listNfts, uint32[] calldata claimAndListNfts, uint32[] calldata removeNfts
    ) external onlyGelato {
        createLendings(listNfts);
        IGotchiLendingFacet(_aavegotchiDiamondAddress).batchClaimAndEndAndRelistGotchiLending(claimAndListNfts);
        removeLendings(removeNfts);
    }

    // == Public Functions =============================================================================================

    // @notice Get list of token addresses
    // @return List of token addresses
    function getTokens() external view returns (address[] memory) {
        return _tokens;
    }

    // @notice Retrieve all tokenIds of Aavegotchis scheduled
    // @return The list of tokenIds
    function getAllTokenIds() external view returns (uint256[] memory) {
        return EnumerableSet.values(_tokenIds);
    }

    // @notice Retrieves all listing parameters of an NFT
    // @return Returns all listing parameters
    function getListingByTokenId(uint256 tokenId) external view returns (AddGotchiListing memory) {
        return _listingsParameters[tokenId];
    }

    function getListingsByTokenIds(uint256[] memory tokenIds) external view returns (AddGotchiListing[] memory listings_) {
        listings_ = new AddGotchiListing[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            listings_[i] = _listingsParameters[tokenId];
        }
    }

    // @notice Retrieves all GotchiListing scheduled in the contract
    // @return listings_ Returns all listing schedules stored in the contract
    function getListings() external view returns (AddGotchiListing[] memory listings_) {
        uint256[] memory tokenIds = EnumerableSet.values(_tokenIds);
        listings_ = new AddGotchiListing[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = EnumerableSet.at(_tokenIds, i);
            listings_[i] = _listingsParameters[tokenId];
        }
    }

    // @notice Includes tokenIds on scheduling list, so that Gelato manages its listings
    // @param tokenIds tokenIds of the NFTs
    // @param initialCost Upfront GHST charge to borrowers
    // @param period Duration of the lending in seconds
    // @param revenueSplit Split of tokens. Should be revenueSplit[0] + revenueSplit[1] + revenueSplit[2] + fee = 100
    function batchSchedule(
        uint32[] memory tokenIds, uint96 initialCost, uint32 period, uint8 lenderSplit, uint8 borrowerSplit,
        uint32 whitelistId
    ) external {
        require(period > 0 && period <= _30_DAYS, "Period needs to be greater than 0, and lower or equal to 30 days");
        require(_fee + lenderSplit + borrowerSplit == 100, "Invalid split distribution");
        uint8[3] memory revenueSplit = [ lenderSplit, borrowerSplit, _fee ];
        for (uint256 i; i < tokenIds.length; i++) {
            uint32 tokenId = tokenIds[i];
            AavegotchiInfo memory info = IAavegotchiFacet(_aavegotchiDiamondAddress).getAavegotchi(tokenId);
            require(info.owner == msg.sender, "Sender must be the owner of the NFT");
            require(info.locked == false, "NFT cannot be locked");
            require(info.status == STATUS_AAVEGOTCHI, "NFT is a portal");
            bool isLendingOperator = ILendingGetterAndSetterFacet(_aavegotchiDiamondAddress).isLendingOperator(msg.sender, address(this), tokenId);
            require(isLendingOperator, "Contract is not approved to manage this NFT");
            EnumerableSet.add(_tokenIds, tokenId);
            _listingsParameters[tokenId] = AddGotchiListing(
                tokenId, initialCost, period, revenueSplit, msg.sender, address(this), whitelistId, _tokens
            );
        }
        emit BatchSchedule(msg.sender, tokenIds, initialCost, period, lenderSplit, borrowerSplit, whitelistId);
    }

    // @notice Remove tokenIds from scheduling list
    // @param tokenIds The ids of the Aavegotchis ti be removed
    function batchUnschedule(uint32[] memory tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            uint32 tokenId = tokenIds[i];
            address originalOwner = getAavegotchiOriginalOwner(tokenId);
            require(originalOwner == msg.sender, "Sender must be the owner of the NFT");
            EnumerableSet.remove(_tokenIds, tokenId);
            delete _listingsParameters[tokenId];
            cancelListingIfPossible(tokenId);
        }
        emit BatchUnschedule(msg.sender, tokenIds);
    }

    function getAavegotchiOriginalOwner(uint32 tokenId) private view returns (address) {
        ILendingGetterAndSetterFacet lendingGetterAndSetterFacet = ILendingGetterAndSetterFacet(_aavegotchiDiamondAddress);
        if (lendingGetterAndSetterFacet.isAavegotchiLent(tokenId) == false) {
            return IERC721(_aavegotchiDiamondAddress).ownerOf(tokenId);
        } else {
            GotchiLending memory lending = lendingGetterAndSetterFacet.getGotchiLendingFromToken(tokenId);
            return lending.originalOwner;
        }
    }

    function cancelListingIfPossible(uint32 tokenId) private {
        ILendingGetterAndSetterFacet lendingGetterAndSetterFacet = ILendingGetterAndSetterFacet(_aavegotchiDiamondAddress);
        if (lendingGetterAndSetterFacet.isAavegotchiListed(tokenId) == true && lendingGetterAndSetterFacet.isAavegotchiLent(tokenId) == false) {
             IGotchiLendingFacet(_aavegotchiDiamondAddress).cancelGotchiLendingByToken(tokenId);
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    // @dev Gets the balance of the specified address.
    // @param _owner The address to query the balance of.
    // @return An uint256 representing the amount owned by the passed address.
    function balanceOf(address _owner) external view returns (uint256);

    // @dev Transfer token for a specified address
    // @param _to The address to transfer to.
    // @param _value The amount to be transferred.
    function transfer(address _to, uint256 _value) external returns (bool);

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

interface IERC721 {

    // @notice Find the owner of an NFT
    // @dev NFTs assigned to zero address are considered invalid, and queries about them do throw.
    // @param _tokenId The identifier for an NFT
    // @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

// @param _erc721TokenId The identifier of the NFT to lend
// @param _initialCost The lending fee of the aavegotchi in $GHST
// @param _period The lending period of the aavegotchi, unit: second
// @param _revenueSplit The revenue split of the lending, 3 values, sum of the should be 100
// @param _originalOwner The account for original owner, can be set to another address if the owner wishes to have profit split there.
// @param _thirdParty The 3rd account for receive revenue split, can be address(0)
// @param _whitelistId The identifier of whitelist for agree lending, if 0, allow everyone
struct AddGotchiListing {
    uint32 tokenId;
    uint96 initialCost;
    uint32 period;
    uint8[3] revenueSplit;
    address originalOwner;
    address thirdParty;
    uint32 whitelistId;
    address[] revenueTokens;
}

interface IGotchiLendingFacet {

    // @notice Allow aavegotchi lenders (msg sender) or their lending operators to add request for lending
    // @dev If the lending request exist, cancel it and replaces it with the new one
    // @dev If the lending is active, unable to cancel
    function batchAddGotchiListing(AddGotchiListing[] memory listings) external;

    // @notice Claim and end and relist gotchi lendings in batch by token ID
    function batchClaimAndEndAndRelistGotchiLending(uint32[] calldata _tokenIds) external;

    // @notice Allow a borrower to agree an lending for the NFT
    // @dev Will throw if the NFT has been lent or if the lending has been canceled already
    // @param _listingId The identifier of the lending to agree
    function agreeGotchiLending(
        uint32 _listingId, uint32 _erc721TokenId, uint96 _initialCost, uint32 _period, uint8[3] calldata _revenueSplit
    ) external;

    // @notice Allow an aavegotchi lender to cancel his NFT lending by providing the NFT contract address and identifier
    // @param _erc721TokenId The identifier of the NFT to be delisted from lending
    function cancelGotchiLendingByToken(uint32 _erc721TokenId) external;

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import { AavegotchiInfo, GotchiLending } from "../libraries/LibAavegotchiStorage.sol";

struct LendingOperatorInputs {
    uint32 _tokenId;
    bool _isLendingOperator;
}

interface ILendingGetterAndSetterFacet {

    function batchSetLendingOperator(address _lendingOperator, LendingOperatorInputs[] calldata _inputs) external;

    function isLendingOperator(address _lender, address _lendingOperator, uint32 _tokenId) external view returns (bool);

    // @notice Get an aavegotchi lending details through an identifier
    // @dev Will throw if the lending does not exist
    // @param _listingId The identifier of the lending to query
    // @return listing_ A struct containing certain details about the lending like timeCreated etc
    // @return aavegotchiInfo_ A struct containing details about the aavegotchi
    function getGotchiLendingListingInfo(uint32 _listingId) external view returns (GotchiLending memory listing_, AavegotchiInfo memory aavegotchiInfo_);

    // @notice Get an ERC721 lending details through an identifier
    // @dev Will throw if the lending does not exist
    // @param _listingId The identifier of the lending to query
    // @return listing_ A struct containing certain details about the ERC721 lending like timeCreated etc
    function getLendingListingInfo(uint32 _listingId) external view returns (GotchiLending memory listing_);

    // @notice Get an aavegotchi lending details through an NFT
    // @dev Will throw if the lending does not exist
    // @param _erc721TokenId The identifier of the NFT associated with the lending
    // @return listing_ A struct containing certain details about the lending associated with an NFT of contract identifier `_erc721TokenId`
    function getGotchiLendingFromToken(uint32 _erc721TokenId) external view returns (GotchiLending memory listing_);

    function getGotchiLendingIdByToken(uint32 _erc721TokenId) external view returns (uint32);

    function isAavegotchiLent(uint32 _erc721TokenId) external view returns (bool);

    function isAavegotchiListed(uint32 _erc721TokenId) external view returns (bool);

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import { AavegotchiInfo } from "../libraries/LibAavegotchiStorage.sol";

interface IAavegotchiFacet {

    // @notice Query all details relating to an NFT
    // @param _tokenId the identifier of the NFT to query
    // @return aavegotchiInfo_ a struct containing all details about
    function getAavegotchi(uint256 _tokenId) external view returns (AavegotchiInfo memory aavegotchiInfo_);

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

uint256 constant EQUIPPED_WEARABLE_SLOTS = 16;
uint256 constant NUMERIC_TRAITS_NUM = 6;

// @notice Define what action gelato needs to perform with the lending
enum LendingAction {
    DO_NOTHING,     // Don't do anything
    REMOVE,         // Remove Nft from Scheduling
    LIST,           // List NFT for rent
    CLAIM_AND_LIST  // Claim and end current rent, and list NFT for rent again
}

struct NftLendingAction {
    uint32 tokenId;
    LendingAction action;
}

struct GotchiLending {
    address lender;
    uint96 initialCost;
    address borrower;
    uint32 listingId;
    uint32 erc721TokenId;
    uint32 whitelistId;
    address originalOwner;
    uint40 timeCreated;
    uint40 timeAgreed;
    bool canceled;
    bool completed;
    address thirdParty;
    uint8[3] revenueSplit;
    uint40 lastClaimed;
    uint32 period;
    address[] revenueTokens;
}

struct Dimensions {
    uint8 x;
    uint8 y;
    uint8 width;
    uint8 height;
}

struct ItemType {
    string name;
    string description;
    string author;
    int8[NUMERIC_TRAITS_NUM] traitModifiers;
    bool[EQUIPPED_WEARABLE_SLOTS] slotPositions;
    uint8[] allowedCollaterals;
    Dimensions dimensions;
    uint256 ghstPrice;
    uint256 maxQuantity;
    uint256 totalQuantity;
    uint32 svgId;
    uint8 rarityScoreModifier;
    bool canPurchaseWithGhst;
    uint16 minLevel;
    bool canBeTransferred;
    uint8 category;
    int16 kinshipBonus;
    uint32 experienceBonus;
}

struct ItemTypeIO {
    uint256 balance;
    uint256 itemId;
    ItemType itemType;
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
    uint256 kinship;
    uint256 lastInteracted;
    uint256 experience;
    uint256 toNextLevel;
    uint256 usedSkillPoints;
    uint256 level;
    uint256 hauntId;
    uint256 baseRarityScore;
    uint256 modifiedRarityScore;
    bool locked;
    ItemTypeIO[] items;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}