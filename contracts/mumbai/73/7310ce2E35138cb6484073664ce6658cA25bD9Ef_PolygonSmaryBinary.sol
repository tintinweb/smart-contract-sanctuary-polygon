// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

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
pragma solidity ^0.8.9;

import "./EnumerableArrays.sol";
import "./PriceFeed.sol";

abstract contract DataStorage is EnumerableArrays, PriceFeed {

    address payable system;

// pools -------------------------------------------------------------------------
    uint256 public poolPoints;
    uint256 public poolLottery;
    uint256 public poolExtraReward;



// data and info -----------------------------------------------------------------

    struct NodeData {
        uint24 allLeftDirect;
        uint24 allRightDirect;
        uint16 leftVariance;
        uint16 rightVariance;
        uint16 depth;
        uint16 maxPoints;
        uint16 todayPoints;
        uint16 childs;
        uint16 isLeftOrRightChild;
    }

    struct NodeInfo {
        address uplineAddress;
        address leftDirectAddress;
        address rightDirectAddress;
    }

    mapping(address => NodeData) _userData;
    mapping(address => NodeInfo) _userInfo;
    mapping(uint256 => address) idToAddr;


    uint256 public allPayments;
    uint256 public lastReward24h;
    uint256 public lastReward7d;
    uint256 public lastReward30d;
    uint256 public userCount;
    uint256 public todayTotalPoint;
    uint256 public todayPointOverFlow;

    address public lastRewardWriter;

// checking -------------------------------------------------------------
    mapping(address => bool) public registered;






    function todayEveryPointValue() public view returns(uint256) {
        uint256 denominator = todayTotalPoint + todayPointOverFlow;
        denominator = denominator > 0 ? denominator : 1;
        return poolPoints / denominator;
    }

    function lotteryWinnersCount() public view returns(uint256) {
        return lotteryCandidatesCount() * 5/100 + 1;
    }

    function lotteryFractionValue() public view returns(uint256) {
        return poolLottery / lotteryWinnersCount();
    }

    function userData(address userAddr) public view returns(NodeData memory) {
        return _userData[userAddr];
    }

    function userInfo(address userAddr) public view returns(NodeInfo memory) {
        return _userInfo[userAddr];
    }


    function userUpAddr(address userAddr) public view returns(address) {
        return _userInfo[userAddr].uplineAddress;
    }

    function userChilds(address userAddr)
        public
        view
        returns (address left, address right)
    {
        left = _userInfo[userAddr].leftDirectAddress;
        right = _userInfo[userAddr].rightDirectAddress;        
    } 

    function userChildsCount(address userAddr)
        public
        view
        returns (uint256)
    {
        return _userData[userAddr].childs;        
    } 

    function userDepth(address userAddr)
        public
        view
        returns (uint256)
    {
        return _userData[userAddr].depth;        
    } 
    
    function userTodayPoints(address userAddr) public view returns (uint256) {
        return _userData[userAddr].todayPoints;
    }
    
    function userTodayDirectCount(address userAddr) public view returns (
        uint256 left,
        uint256 right
    ) {
        uint256 points = userTodayPoints(userAddr);

        left = _userData[userAddr].leftVariance + points;
        right = _userData[userAddr].rightVariance + points;
    }
    
    function userAllTimeDirectCount(address userAddr) public view returns (
        uint256 left,
        uint256 right
    ) {
        left = _userData[userAddr].allLeftDirect;
        right = _userData[userAddr].allRightDirect;
    }












// reward 30 days -------------------------------------------------------

    uint256 monthCounter;
    mapping(uint256 => mapping(address => uint256)) _monthPoints;

    function _resetMonthPoints() internal {
        monthCounter ++;
    }

    function monthPoints(address userAddr) public view returns(uint256) {
        return _monthPoints[monthCounter][userAddr];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract EnumerableArrays {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(uint256 => EnumerableSet.AddressSet) _extraRewardCandidates;
    mapping(uint256 => EnumerableSet.AddressSet) _rewardCandidates;
    mapping(uint256 => EnumerableSet.AddressSet) _lotteryCandidates;
    mapping(uint256 => EnumerableSet.AddressSet) _lotteryWinners;

    uint256 ecIndex;
    uint256 rcIndex;
    uint256 lcIndex;
    uint256 lwIndex;
    

    function _resetExtraRewardCandidates() internal {
        ecIndex++;
    }
    function _resetRewardCandidates() internal {
        rcIndex++;
    }
    function _resetLotteryCandidates() internal {
        lcIndex++;
    }
    function _resetLotteryWinners() internal {
        lwIndex++;
    }


    function extraRewardCandidates() public view returns(address[] memory) {
        return _extraRewardCandidates[ecIndex].values();
    }

    function todayRewardCandidates() public view returns(address[] memory) {
        return _rewardCandidates[rcIndex].values();
    }

    function lotteryCandidates() public view returns(address[] memory) {
        return _lotteryCandidates[lcIndex].values();
    }

    function lastLotteryWinners() public view returns(address[] memory) {
        return _lotteryWinners[lwIndex].values();
    }


    function extraRewardCandidatesCount() public view returns(uint256) {
        return _extraRewardCandidates[ecIndex].length();
    }

    function todayRewardCandidatesCount() public view returns(uint256) {
        return _rewardCandidates[rcIndex].length();
    }

    function lotteryCandidatesCount() public view returns(uint256) {
        return _lotteryCandidates[lcIndex].length();
    }

    function lastLotteryWinnersCount() public view returns(uint256) {
        return _lotteryWinners[lwIndex].length();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./DataStorage.sol";

// 100 => 1 point => 5 ta direct for Up => max point 50
// 60 => 0 point => 3 direct for up => max point 30
// 20 => 0 point => 1 direct for up => max point 10

// topUp 20 60 => no points => +2 direct for up => max point 30
// topUp 60 100 => no points => +2 direct for up => max point 50
// topUp 20 100 => no points => +4 direct for up => max point 50


// bayad check konam bebinam aggregator e MATIC/USD doroste ya USD/MATIC
// poolayi ke vaared mishe 70 darsad be direct ha mirese. 15 darsad be lottery. 10 darsad be award. 5 darsad be system.
// alave bar balance contract ma 4 ta pool darim. pointsPool, lotteryPool, awardPool, systemPool.
contract PolygonSmaryBinary is DataStorage {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    constructor(
        address _aggregator,
        address _system
    ) PriceFeed(_aggregator) {
        _updateMaticePrice();
        system = payable(_system);
    }


// register ---------------------------------------------------------------------------------
    function register(address upAddr) public payable {
        address userAddr = msg.sender;
        uint256 enterPrice = msg.value;

        checkCanRegister(userAddr, upAddr);
        (uint16 todayPoints, uint16 maxPoints, uint16 directUp) = checkEnterPrice(enterPrice);
        registered[userAddr] = true;

        _payShares(enterPrice);

        _newUserId(userAddr);
        _newNode(userAddr, upAddr, maxPoints, todayPoints);
        _setChilds(userAddr, upAddr, todayPoints);
        _setDirects(userAddr, upAddr, directUp);
    }

    function checkCanRegister(
        address userAddr, 
        address upAddr
    ) public view returns(bool) {
        require(
            _userData[upAddr].childs < 2,
            "This address have two directs and could not accept new members!"
        );
        require(
            userAddr != upAddr,
            "You can not enter your own address!"
        );
        require(
            !registered[userAddr],
            "This address is already registered!"
        );
        require(
            registered[upAddr],
            "This Upline address does Not Exist!"
        );
        return true;
    }

    function checkEnterPrice(uint256 enterPrice) public view returns(
        uint16 todayPoints, uint16 maxPoints, uint16 directUp
    ) {
        if(enterPrice == 20 * MATIC_USD) {
            maxPoints = 10;
            directUp = 1;
        } else if(enterPrice == 60 * MATIC_USD) {
            maxPoints = 30;
            directUp = 3;
        } else if(enterPrice == 100 * MATIC_USD) {
            todayPoints = 1;
            maxPoints = 50;
            directUp = 5;
        } else {
            revert("Wrong enter price");
        }
    }

    function _payShares(uint256 enterPrice) internal {
        allPayments += enterPrice;

        poolPoints += enterPrice * 70/100;
        poolLottery += enterPrice * 15/100;
        poolExtraReward += enterPrice * 10/100;
        system.transfer(enterPrice * 5/100);
    }

    function _newUserId(address userAddr) internal {
        idToAddr[userCount] = userAddr;
        userCount++;
    }

    function _newNode(address userAddr, address upAddr, uint16 maxPoints, uint16 todayPoints) internal {
        _userData[userAddr] = NodeData (
            0,
            0,
            0,
            0,
            _userData[upAddr].depth + 1,
            maxPoints,
            todayPoints,
            0,
            _userData[upAddr].childs
        );
        _userInfo[userAddr] = NodeInfo (
            upAddr,
            address(0),
            address(0)
        );
    }

    function _setChilds(address userAddr, address upAddr, uint16 todayPoints) internal {

        if (_userData[upAddr].childs == 0) {
            _userInfo[upAddr].leftDirectAddress = userAddr;
        } else {
            _userInfo[upAddr].rightDirectAddress = userAddr;
        }
        _userData[upAddr].childs++;

        if(todayPoints != 0) {
            _userData[userAddr].todayPoints++;
            _rewardCandidates[rcIndex].add(userAddr);
        }
    }

    function _setDirects(address userAddr, address upAddr, uint16 directUp) internal { 

        EnumerableSet.AddressSet storage rewardCandidates = _rewardCandidates[rcIndex];

        uint256 depth = _userData[userAddr].depth;
        uint16 _pointsOverFlow;
        uint16 _totalPoints;
        for (uint256 i; i < depth; i++) {
            uint16 points;
            if (_userData[userAddr].isLeftOrRightChild == 0) {
                if(_userData[upAddr].rightVariance == 0){
                    _userData[upAddr].leftVariance += directUp;
                } else {
                    if(_userData[upAddr].rightVariance < directUp) {
                        uint16 v = _userData[upAddr].rightVariance;
                        _userData[upAddr].rightVariance = 0;
                        _userData[upAddr].leftVariance += directUp - v;
                        points = v;
                    } else {
                        _userData[upAddr].rightVariance -= directUp;
                        points = directUp;
                    }
                }
                _userData[upAddr].allLeftDirect += directUp;
            } else {
                if(_userData[upAddr].leftVariance == 0){
                    _userData[upAddr].rightVariance += directUp;
                } else {
                    if(_userData[upAddr].leftVariance < directUp) {
                        uint16 v = _userData[upAddr].leftVariance;
                        _userData[upAddr].leftVariance = 0;
                        _userData[upAddr].rightVariance += directUp - v;
                        points = v;
                    } else {
                        _userData[upAddr].leftVariance -= directUp;
                        points = directUp;
                    }
                }
                _userData[upAddr].allRightDirect += directUp;
            }

            uint16 userNeededPoints = _userData[upAddr].maxPoints - _userData[upAddr].todayPoints;
            if(userNeededPoints >= points) {
                _userData[upAddr].todayPoints += points;
                _totalPoints += points;
                rewardCandidates.add(upAddr);
            } else {
                _userData[upAddr].todayPoints += userNeededPoints;
                _totalPoints += userNeededPoints;
                _pointsOverFlow += points - userNeededPoints;
            }

            _monthPoints[monthCounter][upAddr] += points;
            if(monthPoints(upAddr) >= 1000) {
                _extraRewardCandidates[ecIndex].add(upAddr);
            }

            userAddr = upAddr;
            upAddr = _userInfo[upAddr].uplineAddress;
        }

        todayTotalPoint += _totalPoints;
        todayPointOverFlow += _pointsOverFlow;
    }

// topUp --------------------------------------------------------------------------------------

    function topUp() public payable {
        address userAddr = msg.sender;
        uint256 topUpPrice = msg.value;

        address upAddr = _userInfo[userAddr].uplineAddress;
        (uint16 maxPoints, uint16 directUp) = _checkTopUpPrice(userAddr, topUpPrice);

        _payShares(topUpPrice);
        _setDirects(userAddr, upAddr, directUp);
                        
        _userData[userAddr].maxPoints += maxPoints;
    }

    function _checkTopUpPrice(address userAddr, uint256 topUpPrice) internal view returns(
        uint16 maxPoints, uint16 directUp
    ) {
        require(
            registered[userAddr],
            "You have not registered!"
        );

        if(topUpPrice == 40 * MATIC_USD) {
            require(
                _userData[userAddr].maxPoints != 50,
                "the highest max point is 50"
            );
            maxPoints = 20;
            directUp = 2;
        } else if(topUpPrice == 80 * MATIC_USD) {
            require(
                _userData[userAddr].maxPoints == 10,
                "the highest max point is 50"
            );
            maxPoints = 40;
            directUp = 4;
        } else {
            revert("Wrong TopUp price");
        }
    }

// reward24 -----------------------------------------------------------------------------------

    function trigger() public {
        require(
            block.timestamp >= lastReward24h + 24 hours,
            "The Reward_24 Time Has Not Come"
        );
        _reward24h();

        if(block.timestamp >= lastReward7d + 7 days) {
            _reward7d();
        }
        if(block.timestamp >= lastReward30d + 30 days) {
            _reward30d();
        }
        _updateMaticePrice();
    }

// writer o call lottery ro azash keshidam biroon. bayad ba noskhe qabli moqayese konam bebinam bedone bug bashe.
    function _reward24h() internal {
        lastReward24h = block.timestamp;

        uint256 pointValue = todayEveryPointValue();

        EnumerableSet.AddressSet storage rewardCandidates = _rewardCandidates[rcIndex];

        address userAddr;
        for(uint256 i; i < rewardCandidates.length(); i++) {
            userAddr = rewardCandidates.at(i);
            uint256 userPoints = _userData[userAddr].todayPoints;

            payable(userAddr).transfer(userPoints * pointValue);

            delete _userData[userAddr].todayPoints;
        }
        system.transfer(todayPointOverFlow * pointValue);
        delete todayTotalPoint;
        delete todayPointOverFlow;
        _resetRewardCandidates();
    }

    function _reward7d() internal {
        EnumerableSet.AddressSet storage lotteryCandidates = _lotteryCandidates[lcIndex];
        EnumerableSet.AddressSet storage lotteryWinners = _lotteryWinners[lwIndex];

        uint256 winnersCount = lotteryWinnersCount();
        uint256 candidatesCount = lotteryCandidatesCount();
        uint256 lotteryFraction = lotteryFractionValue();
        address winner;

        uint256 randIndex;
        for(uint256 i; i < winnersCount; i++) {
            randIndex = uint256(keccak256(abi.encodePacked(
                block.timestamp, msg.sender, i
            ))) % candidatesCount;
            winner = lotteryCandidates.at(randIndex);
            lotteryCandidates.remove(winner);
            lotteryWinners.add(winner);
            payable(winner).transfer(lotteryFraction);
        }
        
        delete poolLottery;
        _resetLotteryCandidates();
    }

// hes mikonam be andaze kafi efficient nist
    function _reward30d() internal {
        uint256 count = extraRewardCandidatesCount();
        if(count > 0) {
            uint256 exPointCount;
            for(uint256 i; i < count; i++) {
                exPointCount += _monthPoints[monthCounter][_extraRewardCandidates[ecIndex].at(i)] / 1000;
            }
            uint256 exPointValue = poolExtraReward / exPointCount;
            for(uint256 i; i < count; i++) {
                address userAddr = _extraRewardCandidates[ecIndex].at(i);
                payable(userAddr).transfer(_monthPoints[monthCounter][userAddr] / 1000 * exPointValue);
            }
        } else {
            system.transfer(poolExtraReward);
        }
        lastReward30d = block.timestamp;
        _resetMonthPoints();
        _resetExtraRewardCandidates();
        delete poolExtraReward;
    }

    function registerInLottery() public payable {
        address userAddr = msg.sender;
        require(
            registered[userAddr],
            "This address is not registered in Smart Binary Contract!"
        );
        require(
            _userData[userAddr].todayPoints == 0,
            "You Have Points Today"
        );
        require(
            msg.value == 1 * MATIC_USD,
            "lottery enter price is 1 USD in MATIC"
        );

        poolLottery += msg.value;

        _lotteryCandidates[lcIndex].add(userAddr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";

abstract contract PriceFeed {
    AggregatorInterface immutable AGGREGATOR_MATIC_USD;

    uint256 public MATIC_USD;

    constructor(
        address aggregatorAddr
    ) {
        AGGREGATOR_MATIC_USD = AggregatorInterface(aggregatorAddr);
        _updateMaticePrice();
    }

    function _updateMaticePrice() internal {
        MATIC_USD = uint256(AGGREGATOR_MATIC_USD.latestAnswer()) * 10 ** 10;
    }
}