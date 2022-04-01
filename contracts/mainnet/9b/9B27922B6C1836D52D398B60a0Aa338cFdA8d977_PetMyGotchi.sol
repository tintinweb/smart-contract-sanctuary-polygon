/**
 *Submitted for verification at polygonscan.com on 2022-04-01
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
}






/**
 * @title TokenRecover
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Allows owner to recover any ERC20 sent into the contract
 */
contract TokenRecover is Ownable {
    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public virtual onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}


// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)


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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

        assembly {
            result := store
        }

        return result;
    }
}


// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)


/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}



uint256 constant EQUIPPED_WEARABLE_SLOTS = 16;
uint256 constant NUMERIC_TRAITS_NUM = 6;
uint256 constant TRAIT_BONUSES_NUM = 5;
uint256 constant PORTAL_AAVEGOTCHIS_NUM = 10;

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

interface IAavegotchiFacet {
    function interact(uint256[] calldata _tokenIds) external;

    function ownerOf(uint256 _id) external view returns (address);

    function isPetOperatorForAll(address _owner, address _operator) external view returns (bool);

    function getAavegotchi(uint256 id) external view returns (AavegotchiInfo memory);

    function tokenIdsOfOwner(address _owner) external view returns (uint32[] memory tokenIds_);

    function getOwnerGotchiLendings(
        address _lender,
        bytes32 _status,
        uint256 _length
    ) external view returns (GotchiLending[] memory listings_);

    function isAavegotchiLent(uint32 _erc721TokenId) external view returns (bool);

    function getGotchiLendingFromToken(uint32 _erc721TokenId) external view returns (GotchiLending memory listing_);
}







contract PetMyGotchi is TokenRecover {

    using Math for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private parents;
    EnumerableSet.AddressSet private banned_parents;

    uint256 public pricePerPetPerDay; // in wei
    address public aavegotchiFacetAddress; // = 0x86935F11C86623deC8a25696E1C19a8659CbF95d;
    address public gelatoContractAddress; // = 0x527a819db1eb0e34426297b03bae11F2f8B3A19E;
    uint256 public feeEarned;
    uint256 public lastFeeChargedAt;
    uint256 public maxGasPriceAllowed; // in wei
    uint256 public maxPetAtOnce = 20;
    uint256 public maxLentPetCount = 99; // To get the maximum number of listings
    mapping(address => uint256) public parent_balance; // Parent => balance
    mapping(address => uint256) public parent_pricePerPetPerDay; // Parent => pricePerPetPerDay

    constructor(
        address _aavegotchiFacetAddress,
        address _gelatoContractAddress,
        uint256 _pricePerPetPerDay,
        uint256 _maxGasPriceAllowed
    ){
        aavegotchiFacetAddress = _aavegotchiFacetAddress;
        gelatoContractAddress = _gelatoContractAddress;
        pricePerPetPerDay = _pricePerPetPerDay;
        maxGasPriceAllowed = _maxGasPriceAllowed;
    }

    function setGotchiContractAddress(address _aavegotchiFacetAddress) public onlyOwner {
        aavegotchiFacetAddress = _aavegotchiFacetAddress;
    }

    function setGelatoContractAddress(address _gelatoContractAddress) public onlyOwner {
        gelatoContractAddress = _gelatoContractAddress;
    }

    function setMaxGasPriceAllowed(uint256 _gasPrice) public onlyOwner {
        maxGasPriceAllowed = _gasPrice;
    }

    function setMaxPetAtOnce(uint256 _maxPetAtOnce) public onlyOwner {
        maxPetAtOnce = _maxPetAtOnce;
    }

    function getPricePerPerDayForParent(address _parent) public view returns(uint256){
        uint _pricePerPetPerDay = pricePerPetPerDay;

        if(_parent == owner()){
            _pricePerPetPerDay = 0;
        }
        else if(parent_pricePerPetPerDay[_parent] > 0 && _pricePerPetPerDay <= parent_pricePerPetPerDay[_parent]){
            _pricePerPetPerDay = parent_pricePerPetPerDay[_parent];
        }

        return _pricePerPetPerDay;
    }

    function setPricePerPetPerDay(uint256 _pricePerPetPerDay) public onlyOwner{
        pricePerPetPerDay = _pricePerPetPerDay;
    }

    function setCustomPricePerPetPerDayForParent(address _parent, uint256 _pricePerPetPerDay) public onlyOwner{
        parent_pricePerPetPerDay[_parent] = _pricePerPetPerDay;
    }

    function setMaxLentPetCount(uint256 _maxLentPetCount) public onlyOwner{
        maxLentPetCount = _maxLentPetCount;
    }

    function getBalanceOf(address _parent) public view returns (uint256) {
        return parent_balance[_parent];
    }

    function getAavegotchi(uint256 _id) public view returns (AavegotchiInfo memory) {
        return IAavegotchiFacet(aavegotchiFacetAddress).getAavegotchi(_id);
    }

    function getLastInteractedAt(uint256 _id) public view returns (uint256) {
        return IAavegotchiFacet(aavegotchiFacetAddress).getAavegotchi(_id).lastInteracted;
    }

    function addParent() external payable{
        require(! EnumerableSet.contains(parents, msg.sender), "Already exists!");
        require(! EnumerableSet.contains(banned_parents, msg.sender), "Banned!");
        require(parent_balance[msg.sender] >= pricePerPetPerDay || msg.value >= pricePerPetPerDay, "Please send some funds!");

        EnumerableSet.add(parents, msg.sender);
        parent_balance[msg.sender] += msg.value;
    }

    function addCustomParent(address _parent) public onlyOwner payable{
        require(! EnumerableSet.contains(parents, _parent), "Already exists!");
        require(! EnumerableSet.contains(banned_parents, _parent), "Banned!");

        EnumerableSet.add(parents, _parent);
        parent_balance[_parent] += msg.value;
    }

    function removeParent() public {
        require(EnumerableSet.contains(parents, msg.sender), "Does not exists!");

        EnumerableSet.remove(parents, msg.sender);
        withdrawBalanceFor(msg.sender);
    }

    function removeCustomParent(address _parent) public onlyOwner{
        require(EnumerableSet.contains(parents, _parent), "Does not exists!");

        EnumerableSet.remove(parents, _parent);
        withdrawBalanceFor(_parent);
    }

    function banCustomParent(address _parent) external onlyOwner{
        require(! EnumerableSet.contains(banned_parents, _parent), "Already Banned!");

        EnumerableSet.add(banned_parents, _parent);

        if(EnumerableSet.contains(parents, _parent)){
            EnumerableSet.remove(parents, _parent);
            withdrawBalanceFor(_parent);
        }
    }

    function unbanCustomParent(address _parent) external onlyOwner{
        require(EnumerableSet.contains(banned_parents, _parent), "Not Banned!");

        EnumerableSet.remove(banned_parents, _parent);
    }

    function withdrawBalanceFor(address _parent) private {
        uint256 amount = parent_balance[_parent];

        if(amount > 0){
            parent_balance[_parent] = 0;
            payable(_parent).transfer(amount);
        }
    }

    function withdrawAmountFor(address _parent, uint256 _amount) private {
        require(parent_balance[_parent] >= _amount, "Insufficient balance!");

        parent_balance[_parent] -= _amount;
        payable(_parent).transfer(_amount);
    }

    function parentExists(address _parent) public view returns(bool) {
        return EnumerableSet.contains(parents, _parent);
    }

    function getParentAt(uint256 _index) public view returns(address) {
        return EnumerableSet.at(parents, _index);
    }

    function countParents() public view returns(uint256) {
        return EnumerableSet.length(parents);
    }

    function getBannedParentAt(uint256 _index) public view returns(address) {
        return EnumerableSet.at(banned_parents, _index);
    }

    function countBannedParents() public view returns(uint256) {
        return EnumerableSet.length(banned_parents);
    }

    function countChildrenOf(address _parent) public view returns(uint256){
        return IAavegotchiFacet(aavegotchiFacetAddress).tokenIdsOfOwner(_parent).length + IAavegotchiFacet(aavegotchiFacetAddress).getOwnerGotchiLendings(_parent, bytes32('agreed'), maxLentPetCount).length;
    }

    function childrenOf(address _parent) public view returns(uint32[] memory){
        uint32[] memory _childrenIds = new uint32[](countChildrenOf(_parent));

        uint32[] memory _ownedIds = IAavegotchiFacet(aavegotchiFacetAddress).tokenIdsOfOwner(_parent);
        GotchiLending[] memory _lendings = IAavegotchiFacet(aavegotchiFacetAddress).getOwnerGotchiLendings(_parent, bytes32('agreed'), maxLentPetCount);

        uint _counter = 0;
        for(uint i = 0; i < _ownedIds.length; i++){
            _childrenIds[_counter] = _ownedIds[i];
            _counter++;
        }

        for(uint j = 0; j < _lendings.length; j++){
            _childrenIds[_counter] = _lendings[j].erc721TokenId;
            _counter++;
        }

        return _childrenIds;
    }

    function nextPetTimeForChild(uint256 _child) public view returns(uint256){
        return IAavegotchiFacet(aavegotchiFacetAddress).getAavegotchi(_child).lastInteracted + 12 hours;
    }

    function nextPetTimeForChildrenOf(address _parent) public view returns(uint256){
        uint32[] memory children = childrenOf(_parent);
        uint256 nextPetTime = 0;

        for(uint i = 0; i < children.length; i++){
            uint256 nextPetTimeForThisChild = nextPetTimeForChild(children[i]);
            if(nextPetTimeForThisChild > 43200 && (nextPetTime == 0 || nextPetTime > nextPetTimeForThisChild)){
                nextPetTime = nextPetTimeForThisChild;
            }
        }

        return nextPetTime;
    }

    function depositFor(address _parent) public payable{
        parent_balance[_parent] += msg.value;
    }

    function whenNextDepositIsRequired() public view returns (uint256){
        return whenNextDepositIsRequiredFor(msg.sender);
    }

    function whenNextDepositIsRequiredFor(address _parent) public view returns (uint256){
        uint256 _totalChildren = countChildrenOf(_parent);

        require(_totalChildren > 0, "No funds required cause you don't own any gotchi!");

        uint _pricePerPetPerDay = getPricePerPerDayForParent(_parent);

        uint256 _feePerDay = _totalChildren * _pricePerPetPerDay;

        uint256 _enoughForDays = 0;

        if(_feePerDay > 0){
            _enoughForDays = Math.ceilDiv( parent_balance[_parent], _feePerDay ) * 1 days;

            return block.timestamp + _enoughForDays;
        }

        return _enoughForDays;
    }

    function isThisParentOwnsThisChild(address _parent, uint32 _child) public view returns(bool){
        bool status = false;

        if(IAavegotchiFacet(aavegotchiFacetAddress).isAavegotchiLent(_child)){
            status = IAavegotchiFacet(aavegotchiFacetAddress).getGotchiLendingFromToken(_child).lender == _parent;
        }
        else{
            status = IAavegotchiFacet(aavegotchiFacetAddress).ownerOf(_child) == _parent;
        }

        return status;
    }

    function getParentOfThisChild(uint256 _child) public view returns(address){

        if(IAavegotchiFacet(aavegotchiFacetAddress).isAavegotchiLent(uint32(_child))){
            return IAavegotchiFacet(aavegotchiFacetAddress).getGotchiLendingFromToken(uint32(_child)).lender;
        }

        return IAavegotchiFacet(aavegotchiFacetAddress).ownerOf(uint32(_child));
    }

    function takingCareOf() public view returns(uint256[] memory){
        uint256 _counter = 0;

        for (uint256 i = 0; i < EnumerableSet.length(parents); i++) {

            address _parent = EnumerableSet.at(parents, i);
            uint32[] memory _pets = childrenOf(_parent);
            uint256 _balance = parent_balance[_parent];
            uint256 _pricePerPetPerDay = getPricePerPerDayForParent(_parent);

            if(_pets.length > 0){
                for(uint256 j = 0; j < _pets.length; j++){
                    if (
                        _pets[j] > 0 &&
                        _balance >= _pricePerPetPerDay &&
                        IAavegotchiFacet(aavegotchiFacetAddress).getAavegotchi(_pets[j]).status == 3 &&
                        (IAavegotchiFacet(aavegotchiFacetAddress).isPetOperatorForAll(
                            getParentOfThisChild(_pets[j]),
                            gelatoContractAddress
                        ))
                    ) {
                        _balance -= _pricePerPetPerDay;
                        _counter++;
                    }
                }
            }
        }

        uint256[] memory _ids = new uint256[](_counter);

        if (_counter > 0) {
            uint256 _counter2 = 0;

            for (uint256 i = 0; i < EnumerableSet.length(parents); i++) {

                address _parent = EnumerableSet.at(parents, i);
                uint32[] memory _pets = childrenOf(_parent);
                uint256 _balance = parent_balance[_parent];
                uint256 _pricePerPetPerDay = getPricePerPerDayForParent(_parent);

                if(_pets.length > 0){
                    for(uint256 j = 0; j < _pets.length; j++){
                        if (
                            _pets[j] > 0 &&
                            _balance >= _pricePerPetPerDay &&
                            IAavegotchiFacet(aavegotchiFacetAddress).getAavegotchi(_pets[j]).status == 3 &&
                            IAavegotchiFacet(aavegotchiFacetAddress).isPetOperatorForAll(
                                getParentOfThisChild(_pets[j]),
                                gelatoContractAddress
                            )
                        ) {
                            _ids[_counter2] = _pets[j];
                            _counter2++;
                        }
                    }
                }
            }
        }

        return _ids;
    }

    function interactable() public view returns (uint256[] memory) {
        uint256 _counter = 0;

        for (uint256 i = 0; i < EnumerableSet.length(parents); i++) {

            if(_counter >= maxPetAtOnce){
                break;
            }

            address _parent = EnumerableSet.at(parents, i);
            uint32[] memory _pets = childrenOf(_parent);
            uint256 _balance = parent_balance[_parent];
            uint256 _pricePerPetPerDay = getPricePerPerDayForParent(_parent);

            if(_pets.length > 0){
                for(uint256 j = 0; j < _pets.length; j++){
                    if (
                        _pets[j] > 0 &&
                        _balance >= _pricePerPetPerDay &&
                        IAavegotchiFacet(aavegotchiFacetAddress).getAavegotchi(_pets[j]).status == 3 &&
                        IAavegotchiFacet(aavegotchiFacetAddress).isPetOperatorForAll(
                            getParentOfThisChild(_pets[j]),
                            gelatoContractAddress
                        )
                    ) {
                        uint256 _lastInteracted = IAavegotchiFacet(aavegotchiFacetAddress).getAavegotchi(_pets[j]).lastInteracted;

                        if (_lastInteracted + 12 hours <= block.timestamp) {
                            _balance -= _pricePerPetPerDay;
                            _counter++;

                            if(_counter >= maxPetAtOnce){
                                break;
                            }
                        }
                    }
                }
            }
        }

        uint256[] memory _ids = new uint256[](_counter);

        if (_counter > 0) {
            uint256 _counter2 = 0;

            for (uint256 i = 0; i < EnumerableSet.length(parents); i++) {

                address _parent = EnumerableSet.at(parents, i);
                uint32[] memory _pets = childrenOf(_parent);
                uint256 _balance = parent_balance[_parent];
                uint256 _pricePerPetPerDay = getPricePerPerDayForParent(_parent);

                if(_pets.length > 0){
                    for(uint256 j = 0; j < _pets.length; j++){
                        if (
                            _pets[j] > 0 &&
                            _balance >= _pricePerPetPerDay &&
                            IAavegotchiFacet(aavegotchiFacetAddress).getAavegotchi(_pets[j]).status == 3 &&
                            IAavegotchiFacet(aavegotchiFacetAddress).isPetOperatorForAll(
                                getParentOfThisChild(_pets[j]),
                                gelatoContractAddress
                            )
                        ) {
                            uint256 _lastInteracted = IAavegotchiFacet(aavegotchiFacetAddress).getAavegotchi(_pets[j]).lastInteracted;

                            if (_lastInteracted + 12 hours <= block.timestamp) {
                                _ids[_counter2] = _pets[j];
                                _counter2++;
                            }
                        }
                    }
                }
            }
        }

        return _ids;
    }

    function interactableWithTheChildrenOf(address _parent) public view returns (uint256[] memory) {
        uint256 _counter = 0;

        uint32[] memory _pets = childrenOf(_parent);
        uint256 _balance = parent_balance[_parent];
        uint256 _pricePerPetPerDay = getPricePerPerDayForParent(_parent);

        if(_pets.length > 0){
            for(uint256 i = 0; i < _pets.length; i++){
                if (
                    _pets[i] > 0 &&
                    _balance >= _pricePerPetPerDay &&
                    IAavegotchiFacet(aavegotchiFacetAddress).getAavegotchi(_pets[i]).status == 3 &&
                    IAavegotchiFacet(aavegotchiFacetAddress).isPetOperatorForAll(
                        getParentOfThisChild(_pets[i]),
                        gelatoContractAddress
                    )
                ) {
                    uint256 _lastInteracted = IAavegotchiFacet(aavegotchiFacetAddress).getAavegotchi(_pets[i]).lastInteracted;

                    if (_lastInteracted + 12 hours <= block.timestamp) {
                        _balance -= _pricePerPetPerDay;
                        _counter++;
                    }
                }
            }
        }

        uint256[] memory _ids = new uint256[](_counter);

        if (_counter > 0) {
            uint256 _counter2 = 0;

            for(uint256 i = 0; i < _pets.length; i++){
                if (
                    _pets[i] > 0 &&
                    _balance >= _pricePerPetPerDay &&
                    IAavegotchiFacet(aavegotchiFacetAddress).getAavegotchi(_pets[i]).status == 3 &&
                    IAavegotchiFacet(aavegotchiFacetAddress).isPetOperatorForAll(
                        getParentOfThisChild(_pets[i]),
                        gelatoContractAddress
                    )
                ) {
                    uint256 _lastInteracted = IAavegotchiFacet(aavegotchiFacetAddress).getAavegotchi(_pets[i]).lastInteracted;

                    if (_lastInteracted + 12 hours <= block.timestamp) {
                        _ids[_counter2] = _pets[i];
                        _counter2++;
                    }
                }
            }
        }

        return _ids;
    }

    function interact() external view returns (bool canExec, bytes memory execPayload) {
        canExec = false;
        uint256[] memory _ids = interactable();

        if (_ids.length > 0) {
            canExec = true;
        }

        if (maxGasPriceAllowed > 0 && tx.gasprice > maxGasPriceAllowed) {
            canExec = false;
        }

        execPayload = abi.encodeWithSelector(IAavegotchiFacet.interact.selector, _ids);

        return (canExec, execPayload);
    }

    function interactWithTheChildrenOf(address _parent) external view returns (bool canExec, bytes memory execPayload) {
        canExec = false;
        uint256[] memory _ids = interactableWithTheChildrenOf(_parent);

        if (_ids.length > 0) {
            canExec = true;
        }

        if (maxGasPriceAllowed > 0 && tx.gasprice > maxGasPriceAllowed) {
            canExec = false;
        }

        execPayload = abi.encodeWithSelector(IAavegotchiFacet.interact.selector, _ids);

        return (canExec, execPayload);
    }

    function withdraw(uint256 _amount) public {
        withdrawAmountFor(msg.sender, _amount);
    }

    function withdrawAll() public {
        withdrawBalanceFor(msg.sender);
    }

    function withdrawEarnings() public onlyOwner {
        uint256 amount = feeEarned;
        feeEarned = 0;
        payable(msg.sender).transfer(amount);
    }

    function refundAmountFromBalance(address _address, uint256 _amount) public onlyOwner {
        withdrawAmountFor(_address, _amount);
    }

    function shouldChargeDailyFee() external view returns (bool canExec, bytes memory execPayload) {
        canExec = false;

        if (block.timestamp >= lastFeeChargedAt + 1 days) {
            canExec = true;
        }

        if ( maxGasPriceAllowed > 0 && tx.gasprice > maxGasPriceAllowed) {
            canExec = false;
        }

        uint256[] memory ids = takingCareOf();

        if(ids.length == 0){
            canExec = false;
        }

        execPayload = abi.encodeWithSelector(this.chargeDailyFee.selector, ids);

        return (canExec, execPayload);
    }

    function chargeDailyFee(uint256[] calldata ids) external {
        require(block.timestamp >= lastFeeChargedAt + 1 days, "Fee can only be charged once per day!");
        require(ids.length > 0, "Invalid call");

        for (uint256 i = 0; i < ids.length; i++) {
            address _parent =  getParentOfThisChild(ids[i]);
            uint256 _pricePerPetPerDay = getPricePerPerDayForParent(_parent);

            if (_pricePerPetPerDay > 0 && parent_balance[_parent] >= _pricePerPetPerDay) {
                parent_balance[_parent] -= _pricePerPetPerDay;
                feeEarned += _pricePerPetPerDay;
            }
        }

        lastFeeChargedAt = block.timestamp;
    }

    function renounceOwnership() public virtual override onlyOwner {
        revert("An owner is required!");
    }

    receive() external payable {
        parent_balance[msg.sender] += msg.value;
    }

    fallback() external payable {
        parent_balance[msg.sender] += msg.value;
    }
}