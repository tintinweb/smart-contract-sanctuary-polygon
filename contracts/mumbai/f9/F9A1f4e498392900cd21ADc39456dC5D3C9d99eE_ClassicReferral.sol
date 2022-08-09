// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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

// SPDX-License-Identifier:  MIT
pragma solidity 0.8.15;

import "./interfaces/ICoreContract.sol";

error ClassicReferralReferrerNotRegistered();
error ClassicReferralUserAlreadyRegistered();

contract ClassicReferral is IClassicReferal {
    struct ClassicUser {
        address referrer;
        address[] referrals;
        uint256 registrationDate;
    }

    address public immutable root;
    mapping(address => ClassicUser) internal classicUsers;

    constructor(address _root) {
        root = _root;
        ClassicUser storage r = classicUsers[_root];
        r.referrer = _root;
    }

    function registration() public {
        registration(root);
    }

    function registration(address referrerAddress) public {
        ClassicUser storage user = classicUsers[msg.sender];
        ClassicUser storage referrer = classicUsers[referrerAddress];

        if (referrer.referrer == address(0)) {
            revert ClassicReferralReferrerNotRegistered();
        }
        if (user.referrer != address(0)) {
            revert ClassicReferralUserAlreadyRegistered();
        }

        user.referrer = referrerAddress;
        user.registrationDate = block.timestamp;
        referrer.referrals.push(msg.sender);
    }

    function parent(address user) public view returns (address) {
        return classicUsers[user].referrer;
    }

    function childs(address user) public view returns (address[] memory) {
        return classicUsers[user].referrals;
    }

    function getRegistrationDate(address user) public view returns (uint256) {
        return classicUsers[user].registrationDate;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

enum Workflow {
    Preparatory,
    Presale,
    SaleHold,
    SaleOpen
}

uint256 constant PRICE_PACK_LEVEL1_IN_USD = 50e18;
uint256 constant PRICE_PACK_LEVEL1_IN_MFS_FIRST_BB = 200e18;
uint256 constant TWO = 2e18;
uint256 constant OVERRLAP_TIME_ACTIVITY = 3 days;
uint256 constant PACK_ACTIVITY_PERIOD = 30 days;
uint256 constant PURCHASE_TIME_LIMIT_PERIOD = 30 days;
uint256 constant SHARE_OF_MARKETING = 60e16;
uint256 constant SHARE_OF_REWARDS = 10e16;
uint256 constant SHARE_OF_LIQUIDITY_POOL = 10e16;
uint256 constant SHARE_OF_FORSAGE_PARTICIPANTS = 5e16;
uint256 constant SHARE_OF_META_DEVELOPMENT_AND_INCENTIVE = 5e16;
uint256 constant SHARE_OF_TEAM = 5e16;
uint256 constant SHARE_OF_LIQUIDITY_LISTING = 5e16;
uint256 constant LEVELS_COUNT = 9;
uint256 constant HMFS_COUNT = 8;
uint256 constant TRANSITION_PHASE_PERIOD = 30 days;
uint256 constant ACTIVATION_COST_RATIO_TO_RENEWAL = 5e18;
uint256 constant COEFF_INCREASE_COST_PACK_FOR_NEXT_LEVEL = 2e18;
uint256 constant COEFF_DECREASE_NEXT_BB = 2e18; //2
uint256 constant COEFF_DECREASE_COST_PACK_NEXT_BB = 2e18; //2
uint256 constant COEFF_DECREASE_COST_PACK_NEXT_MB = 6e16; //0.06
uint256 constant MB_COUNT = 10;
uint256 constant COEFF_FIRST_MB = 127e16; //1.27
uint256 constant START_COEFF_DECREASE_MICROBLOCK = 124e16;
uint256 constant MARKETING_REFERRALS_TREE_ARITY = 2;

// SPDX-License-Identifier:  MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../Constants.sol";
import "./IRegistryContract.sol";

error MetaForceSpaceCoreNotAllowed();
error MetaForceSpaceCoreNoMoreSpaceInTree();
error MetaForceSpaceCoreInvalidCursor();
error MetaForceSpaceCoreActiveUser();
error MetaForceSpaceCoreReplaceSameAddress();
error MetaForceSpaceCoreNotEnoughFrozenMFS();
error MetaForceSpaceCoreSaleOpenIsLastWorkflowStep();
error MetaForceSpaceCoreSumRewardsMustBeHundred();
error MetaForceSpaceCoreRewardsIsNotChange();
error MetaForceSpaceCoreUserAlredyRegistered();

struct User {
    TypeReward rewardType;
    //address referrer;
    address marketingReferrer;
    uint256 mfsFrozenAmount;
    mapping(uint256 => uint256) packs;
    //uint256 registrationDate;
    //EnumerableSet.AddressSet referrals;
    EnumerableSet.AddressSet marketingReferrals;
}

enum TypeReward {
    ONLY_MFS,
    MFS_AND_USD,
    ONLY_USD
}

interface IClassicReferal {
    function parent(address user) external view returns (address);

    function childs(address user) external view returns (address[] memory);

    function getRegistrationDate(address user) external view returns (uint256);
}

interface ICoreContract {
    event ReferrerChanged(address indexed account, address indexed referrer);
    event MarketingReferrerChanged(address indexed account, address indexed marketingReferrer);
    event TimestampEndPackSet(address indexed account, uint256 level, uint256 timestamp);
    event WorkflowStageMove(Workflow workflowstage);
    event RewardsReferrerSetted();
    event UserIsRegistered(address indexed user, address indexed referrer);
    event PoolMFSBurned();

    //Set referrer in referral tree
    //function setReferrer(address user, address referrer) external;

    //Set referrer in Marketing tree
    function setMarketingReferrer(address user, address marketingReferrer) external;

    //Set users type reward
    function setTypeReward(address user, TypeReward typeReward) external;

    //Increase timestamp end pack of the corresponding level
    function increaseTimestampEndPack(
        address user,
        uint256 level,
        uint256 time
    ) external;

    //Set timestamp end pack of the corresponding level
    function setTimestampEndPack(
        address user,
        uint256 level,
        uint256 timestamp
    ) external;

    //increase user frozen MFS in mapping
    function increaseFrozenMFS(address user, uint256 amount) external;

    //decrease user frozen MFS in mapping
    function decreaseFrozenMFS(address user, uint256 amount) external;

    //delete user in referral tree and marketing tree
    function clearInfo(address user) external;

    // replace user (place in referral and marketing tree(refer and all referrals), frozenMFS, and packages)
    function replaceUser(address to) external;

    //replace user in marketing tree(refer and all referrals)
    function replaceUserInMarketingTree(address from, address to) external;

    function nextWorkflowStage() external;

    function setEnergyConversionFactor(uint256 _energyConversionFactor) external;

    function setRewardsDirectReferrers(uint256[] calldata _rewardsRefers) external;

    function setRewardsMarketingReferrers(uint256[] calldata _rewardsMarketingRefers) external;

    function setRewardsReferrers(uint256[] calldata _rewardsRefers, uint256[] calldata _rewardsMarketingRefers)
        external;

    //function registration() external;

    //function registration(address referer) external;

    // Check have referrer in referral tree
    function checkRegistration(address user) external view returns (bool);

    // Request user type reward
    function getTypeReward(address user) external view returns (TypeReward);

    // request user frozen MFS in mapping
    function getAmountFrozenMFS(address user) external view returns (uint256);

    // Request timestamp end pack of the corresponding level
    function getTimestampEndPack(address user, uint256 level) external view returns (uint256);

    // Request user referrer in referral tree
    function getReferrer(address user) external view returns (address);

    // Request user referrer in marketing tree
    function getMarketingReferrer(address user) external view returns (address);

    //Request user some referrals starting from indexStart in referral tree
    /*function getReferrals(
        address user,
        uint256 indexStart,
        uint256 amount
    ) external view returns (address[] memory);*/

    // Request user some referrers (father, grandfather, great-grandfather and etc.) in referral tree
    function getReferrers(
        address user,
        uint256 level,
        uint256 amount
    ) external view returns (address[] memory);

    /*Request user's some referrers (father, grandfather, great-grandfather and etc.)
    in marketing tree having of the corresponding level*/
    function getMarketingReferrers(
        address user,
        uint256 level,
        uint256 amount
    ) external view returns (address[] memory);

    //Request user referrals starting from indexStart in marketing tree
    function getMarketingReferrals(address user) external view returns (address[] memory);

    //get user level (maximum active level)
    function getUserLevel(address user) external view returns (uint256);

    //function getReferralsAmount(address user) external view returns (uint256);

    function getFrozenMFSTotalAmount() external view returns (uint256);

    function root() external view returns (address);

    function isPackActive(address user, uint256 level) external view returns (bool);

    function getWorkflowStage() external view returns (Workflow);

    function getRewardsDirectReferrers() external view returns (uint256[] memory);

    function getRewardsMarketingReferrers() external view returns (uint256[] memory);

    function getDateStartSaleOpen() external view returns (uint256);

    function getEnergyConversionFactor() external view returns (uint256);

    function getRegistrationDate(address user) external view returns (uint256);

    function getLevelForNFT(address _user) external view returns (uint256);
}

// SPDX-License-Identifier:  MIT
pragma solidity 0.8.15;

interface IRegistryContract {
    function setHoldingContract(address _holdingContract) external;

    function setMetaForceContract(address _metaForceContract) external;

    function setCoreContract(address _coreContract) external;

    function setMFS(address _mfs) external;

    function setHMFS(uint256 level, address _hMFS) external;

    function setStableCoin(address _stableCoin) external;

    function setRequestMFSContract(address _requestMFSContract) external;

    function setReferalClassicContract(address _referalClassicContract) external;

    function setEnergyCoin(address _energyCoin) external;

    function setRewardsFund(address addresscontract) external;

    function setLiquidityPool(address addresscontract) external;

    function setForsageParticipants(address addresscontract) external;

    function setMetaDevelopmentAndIncentiveFund(address addresscontract) external;

    function setTeamFund(address addresscontract) external;

    function setLiquidityListingFund(address addresscontract) external;

    function setMetaPool(address) external;

    function setRequestPool(address) external;

    function getHoldingContract() external view returns (address);

    function getMetaForceContract() external view returns (address);

    function getCoreContract() external view returns (address);

    function getMFS() external view returns (address);

    function getHMFS(uint256 level) external view returns (address);

    function getStableCoin() external view returns (address);

    function getEnergyCoin() external view returns (address);

    function getRequestMFSContract() external view returns (address);

    function getReferalClassicContract() external view returns (address);

    function getRewardsFund() external view returns (address);

    function getLiquidityPool() external view returns (address);

    function getForsageParticipants() external view returns (address);

    function getMetaDevelopmentAndIncentiveFund() external view returns (address);

    function getTeamFund() external view returns (address);

    function getLiquidityListingFund() external view returns (address);

    function getMetaPool() external view returns (address);

    function getRequestPool() external view returns (address);
}