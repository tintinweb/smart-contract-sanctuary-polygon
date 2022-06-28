// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

enum Workflow {
    Preparatory,
    Presale,
    SaleHold,
    SaleOpen
}

uint256 constant PRICE_PACK_LEVEL1_IN_USD = 50e6;
uint256 constant PRICE_PACK_LEVEL1_IN_MFS_FIRST_BB = 200e6;
uint256 constant TWO = 2e6;
uint256 constant OVERRLAP_TIME_ACTIVITY = 3 days;
uint256 constant PACK_ACTIVITY_PERIOD = 30 days;
uint256 constant SHARE_OF_MARKETING = 60e4;
uint256 constant SHARE_OF_REWARDS = 10e4;
uint256 constant SHARE_OF_LIQUIDITY_POOL = 10e4;
uint256 constant SHARE_OF_FORSAGE_PARTICIPANTS = 5e4;
uint256 constant SHARE_OF_META_DEVELOPMENT_AND_INCENTIVE = 5e4;
uint256 constant SHARE_OF_TEAM = 5e4;
uint256 constant SHARE_OF_LIQUIDITY_LISTING = 5e4;
uint256 constant LEVELS_COUNT = 8;
uint256 constant TRANSITION_PHASE_PERIOD = 30 days;
uint256 constant ACTIVATION_COST_RATIO_TO_RENEWAL = 5e6;
uint256 constant COEFF_INCREASE_COST_PACK_FOR_NEXT_LEVEL = 2e6;
uint256 constant COEFF_DECREASE_NEXT_BB = 2e6; //2
uint256 constant COEFF_DECREASE_COST_PACK_NEXT_BB = 2e6; //2
uint256 constant COEFF_DECREASE_COST_PACK_NEXT_MB = 6e4; //0.06
uint256 constant MB_COUNT = 10;
uint256 constant COEFF_FIRST_MB = 127e4; //1.27
uint256 constant START_COEFF_DECREASE_MICROBLOCK = 124e4;
uint256 constant MARKETING_REFERRALS_TREE_ARITY = 2;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./interfaces/IRequestMFSContract.sol";
import "./interfaces/IRegistryContract.sol";
import "./interfaces/ICoreContract.sol";
import "./interfaces/IMetaForceContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libraries/FixedPointMath.sol";

contract RequestMFSContract is Ownable, IRequestMFSContract {
    using FixedPointMath for uint256;

    struct Queue {
        mapping(uint256 => uint256) data;
        uint256 front;
        uint256 back;
    }

    struct Request {
        address requester;
        uint256 amountUSD;
    }

    struct PlaceInQueue {
        uint8 level;
        uint248 number;
    }

    IRegistryContract internal registry;

    mapping(uint256 => Queue) public queues;
    mapping(uint256 => Request) public requests;
    mapping(address => uint256[]) public ownersRequests;
    mapping(uint256 => PlaceInQueue) public requestInQueue;
    uint256 internal counter;

    modifier onlyMetaForceContract() {
        if (msg.sender != registry.getMetaForceContract()) {
            revert RMFSCSenderIsNotMetaForceContract();
        }
        _;
    }

    constructor(IRegistryContract _registry) {
        registry = _registry;
        counter = 1;
    }

    function setRegistryContract(IRegistryContract _registry) external onlyOwner {
        registry = _registry;
    }

    function createRequestMFS(uint256 _amountUSD) external override returns (uint256 requestId) {
        if (_amountUSD == 0) {
            revert RMFSCAmountUSDIsZero();
        }
        ICoreContract core = ICoreContract(registry.getCoreContract());
        IERC20 stableCoin = IERC20(registry.getStableCoin());
        requestId = counter;
        requests[requestId].requester = msg.sender;
        requests[requestId].amountUSD = _amountUSD;
        ownersRequests[msg.sender].push(requestId);
        stableCoin.transferFrom(msg.sender, registry.getRequestPool(), _amountUSD);
        pushQueue(queues[core.getUserLevel(msg.sender) - 1], requestId);
        requestInQueue[requestId].level = uint8(core.getUserLevel(msg.sender));
        requestInQueue[requestId].number = uint248(lengthQueue(queues[core.getUserLevel(msg.sender) - 1]));
        counter++;
    }

    function deleteRequestMFS(uint256 _requestId) external override {
        if (requests[_requestId].requester != msg.sender) {
            revert RMFSCSenderIsNotOwner();
        }
        IERC20 stableCoin = IERC20(registry.getStableCoin());
        stableCoin.transferFrom(registry.getRequestPool(), msg.sender, requests[_requestId].amountUSD);
        requests[_requestId].amountUSD = 0;
    }

    function realizeMFS(uint256 amountMFS) external override onlyMetaForceContract returns (uint256) {
        address user;
        uint256 levelQueue;
        uint256 requestId;
        uint256 amountUSD;
        uint256 amountUSDinMFS;
        uint256 priceMFS;
        IMetaForceContract mfc = IMetaForceContract(registry.getMetaForceContract());
        priceMFS = mfc.priceMFSInUSD();
        levelQueue = getNextLevel();
        requestId = getNextRequestId();
        while (amountMFS > 0 && requestId != 0) {
            user = requests[requestId].requester;
            amountUSD = requests[requestId].amountUSD;
            amountUSDinMFS = amountUSD.div(priceMFS);
            if (amountUSDinMFS <= amountMFS) {
                mfc.giveMFSFromPool(user, amountUSDinMFS);
                amountMFS -= amountUSDinMFS;
                requests[requestId].amountUSD = 0;
                deleteFirstElementInQueue(queues[levelQueue - 1]);
                requestId = getNextRequestId();
            } else {
                mfc.giveMFSFromPool(user, amountMFS);
                amountUSDinMFS -= amountMFS;
                amountMFS = 0;
                requests[requestId].amountUSD = amountUSDinMFS.mul(priceMFS);
            }
        }
        return amountMFS;
    }

    function getRequestsIdsForUser(address user) external view override returns (uint256[] memory) {
        return ownersRequests[user];
    }

    function getNumberInQueue(uint256 _requestId) external view override returns (uint256 numberInQueue) {
        uint8 level = requestInQueue[_requestId].level;
        uint256 number = uint256(requestInQueue[_requestId].number);
        for (uint8 i = 8; i > level; i--) {
            numberInQueue += lengthQueue(queues[i - 1]);
        }
        numberInQueue += number;
    }

    function getAddressRequester(uint256 requestId) external view override returns (address requester) {
        requester = requests[requestId].requester;
    }

    function getAmountUSDRequest(uint256 requestId) external view override returns (uint256 amount) {
        amount = requests[requestId].amountUSD;
    }

    function getNextLevel() public view override returns (uint256 levelQueue) {
        levelQueue = 8;
        while (levelQueue > 0 && lengthQueue(queues[levelQueue - 1]) == 0) {
            levelQueue--;
        }
    }

    function getNextRequestId() public view override returns (uint256 requestId) {
        uint256 levelQueue = getNextLevel();
        if (levelQueue == 0) {
            return 0;
        }
        requestId = searchNextInQueue(queues[levelQueue - 1]);
    }

    /// @dev push a new element to the back of the queue
    function pushQueue(Queue storage q, uint256 data) internal {
        q.data[q.back] = data;
        q.back = q.back + 1;
    }

    /// @dev remove and return the element at the front of the queue
    function deleteFirstElementInQueue(Queue storage q) internal {
        if (q.back == q.front) revert RMFSCQueueIsEmpty(); // throw;
        delete q.data[q.front];
        q.front = q.front + 1;
    }

    /// @dev the number of elements stored in the queue.
    function lengthQueue(Queue storage q) internal view returns (uint256) {
        return q.back - q.front;
    }

    function searchNextInQueue(Queue storage q) internal view returns (uint256) {
        if (q.back == q.front) return 0; // throw;
        return q.data[q.front];
    }
}

// SPDX-License-Identifier:  MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../Constants.sol";

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
    address referrer;
    address marketingReferrer;
    uint256 mfsFrozenAmount;
    mapping(uint256 => uint256) packs;
    uint256 registrationDate;
    EnumerableSet.AddressSet referrals;
    EnumerableSet.AddressSet marketingReferrals;
}

enum TypeReward {
    ONLY_MFS,
    MFS_AND_USD,
    ONLY_USD
}

interface ICoreContract {
    event ReferrerChanged(address indexed account, address indexed referrer);
    event MarketingReferrerChanged(address indexed account, address indexed marketingReferrer);
    event TimestampEndPackSet(address indexed account, uint256 level, uint256 timestamp);
    event WorkflowStageMove(Workflow workflowstage);
    event RewardsReferrerSetted();
    event UserIsRegistered(address indexed user, address indexed referrer);

    //Set referrer in referral tree
    function setReferrer(address user, address referrer) external;

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

    function registration() external;

    function registration(address referer) external;

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
    function getReferrals(
        address user,
        uint256 indexStart,
        uint256 amount
    ) external view returns (address[] memory);

    // Request user some referrers (father, grandfather, great-grandfather and etc.) in referral tree
    function getReferrers(address user, uint256 amount) external view returns (address[] memory);

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

    function getReferralsAmount(address user) external view returns (uint256);

    function getRegistrationDate(address user) external view returns (uint256);

    function getFrozenMFSTotalAmount() external view returns (uint256);

    function root() external view returns (address);

    function isPackActive(address user, uint256 level) external view returns (bool);

    function getWorkflowStage() external view returns (Workflow);

    function getRewardsDirectReferrers() external view returns (uint256[] memory);

    function getRewardsMarketingReferrers() external view returns (uint256[] memory);

    function getDateStartSaleOpen() external view returns (uint256);

    function getEnergyConversionFactor() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IRegistryContract.sol";

error MFCUserNotRegisteredYet();
error MFCMaxPackLevelIs8();
error MFCPackLevelIs0();
error MFCEarlyStageForActivatePack();
error MFCNeedActivatePack(uint256 level);
error MFCNeedRenewalPack(uint256 level);
error MFCPackIsActive(uint256 level);

error MFCSenderIsNotRequestMFSContract();
error MFCNotFirstActivationPack();
error MFCBuyLimitOfMFSExceeded(uint256 requested, uint256 available);
error MFCEarlyStageForRenewalPack();
error MFCUserIsNotRegistredInMarketing();
error MFCRefererNotCantBeSelf();
error MFCEarlyStageForRenewalPackInHMFS();
error MFCRenewalPaymentIsOnlyPossibleInHMFS();
error MFCNeedPayOnlyHMFSLevel(TypeRenewalCurrency);
error MFCNoFundsOnAccount();
error MFCToEarlyToCashing();
error MFCRenewalInThisStageOnlyForMFS();
error MFCEmissionCommitted();
error MFCLateForBuyMFS();

enum TypeRenewalCurrency {
    MFS,
    hMFS1,
    hMFS2,
    hMFS3,
    hMFS4,
    hMFS5,
    hMFS6,
    hMFS7,
    hMFS8
}

interface IMFS is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;

    function cap() external view returns (uint256);
}

interface IHMFS is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;

    function cap() external view returns (uint256);
}

interface IEnergy is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;
}

interface IMetaForceContract {
    event MFCSmallBlockMove(uint256 nowNumberSmallBlock);
    event MFCBigBlockMove(uint256 nowNumberBigBlock);
    event MFCMintMFS(address indexed to, uint256 amount);
    event MFCTransferMFS(address indexed from, address indexed to, uint256 amount);
    event MFCPackIsRenewed(address indexed user, uint256 level, uint256 timestampEndPack);
    event MFCPackIsActivated(address indexed user, uint256 level, uint256 timestampEndPack);

    event MFCPoolMFSBurned();
    event MFCRegistryContractAddressSetted(address registry);

    function setRegistryContract(IRegistryContract _registry) external;

    function buyMFS(uint256 amount) external;

    function activationPack(uint256 level) external;

    function firstActivationPack(address marketinReferrer) external;

    function firstActivationPackWithReplace(address replace) external;

    function renewalPack(uint256 level, TypeRenewalCurrency typeCurrency) external;

    function giveMFSFromPool(address to, uint256 amount) external;

    function cashingFrozenMFS() external;

    function distibuteEmission() external;

    function priceMFSInUSD() external view returns (uint256);
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

    function getRewardsFund() external view returns (address);

    function getLiquidityPool() external view returns (address);

    function getForsageParticipants() external view returns (address);

    function getMetaDevelopmentAndIncentiveFund() external view returns (address);

    function getTeamFund() external view returns (address);

    function getLiquidityListingFund() external view returns (address);

    function getMetaPool() external view returns (address);

    function getRequestPool() external view returns (address);
}

// SPDX-License-Identifier:  MIT
pragma solidity 0.8.15;

error RMFSCAmountUSDIsZero();
error RMFSCSenderIsNotOwner();
error RMFSCQueueIsEmpty();
error RMFSCSenderIsNotMetaForceContract();

interface IRequestMFSContract {
    function createRequestMFS(uint256 _amountUSD) external returns (uint256 requestId);

    function deleteRequestMFS(uint256 _requestId) external;

    function getNextLevel() external returns (uint256 levelQueue);

    function getNextRequestId() external returns (uint256 requestId);

    function getNumberInQueue(uint256 _requestId) external returns (uint256 numberInQueue);

    function getAddressRequester(uint256 _requestId) external returns (address requester);

    function getAmountUSDRequest(uint256 _requestId) external returns (uint256 amount);

    function realizeMFS(uint256 _amountMFS) external returns (uint256 amount);

    function getRequestsIdsForUser(address _user) external returns (uint256[] memory requestsIds);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./Math.sol";

error FixedPointMathMulDivOverflow(uint256 prod1, uint256 denominator);
error FixedPointMathExpArgumentTooBig(uint256 a);
error FixedPointMathExp2ArgumentTooBig(uint256 a);
error FixedPointMathLog2ArgumentTooBig(uint256 a);

/// @title Fixed point math implementation
library FixedPointMath {
    uint256 internal constant SCALE = 1e6;
    uint256 internal constant HALF_SCALE = 5e5;
    /// @dev Largest power of two divisor of scale.
    uint256 internal constant SCALE_LPOTD = 64;
    /// @dev Scale inverted mod 2**256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661508869554232690281;

    function mul(uint256 a, uint256 b) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert FixedPointMathMulDivOverflow(prod1, SCALE);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(a, b, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            assembly {
                result := add(div(prod0, SCALE), roundUpUnit)
            }
            return result;
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 result) {
        result = mulDiv(a, SCALE, b);
    }

    /// @notice Calculates ⌊a × b ÷ denominator⌋ with full precision.
    /// @dev Credit to Remco Bloemen under MIT license https://2π.com/21/muldiv.
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= denominator) {
            revert FixedPointMathMulDivOverflow(prod1, denominator);
        }

        if (prod1 == 0) {
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)

            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        unchecked {
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                denominator := div(denominator, lpotdod)
                prod0 := div(prod0, lpotdod)
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }
            prod0 |= prod1 * lpotdod;

            uint256 inverse = (3 * denominator) ^ 2;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;

            result = prod0 * inverse;
        }
    }

    function exp2(uint256 x) internal pure returns (uint256 result) {
        if (x >= 192e18) {
            revert FixedPointMathExp2ArgumentTooBig(x);
        }

        unchecked {
            x = (x << 64) / SCALE;

            result = 0x800000000000000000000000000000000000000000000000;
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert FixedPointMathLog2ArgumentTooBig(x);
        }
        unchecked {
            uint256 n = Math.mostSignificantBit(x / SCALE);

            result = n * SCALE;

            uint256 y = x >> n;

            if (y == SCALE) {
                return result;
            }

            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                if (y >= 2 * SCALE) {
                    result += delta;

                    y >>= 1;
                }
            }
        }
    }

    function convertIntToFixPoint(uint256 integer) internal pure returns (uint256 result) {
        result = integer * SCALE;
    }

    function convertFixPointToInt(uint256 integer) internal pure returns (uint256 result) {
        result = integer / SCALE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library Math {
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }
}