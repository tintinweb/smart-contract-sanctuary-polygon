// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FelinosMatic is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint internal constant REFERRAL_LENGTH = 21;
    struct User {
        address user;
        address refferer;
        uint poolInvested;
        uint poolEarned;
        uint[REFERRAL_LENGTH] referrals;
    }

    uint[REFERRAL_LENGTH] internal REFERRAL_PERCENTS = [2000, 375, 375, 375, 375, 375, 375, 375, 375, 375, 375, 375, 375, 375, 375, 375, 375, 375, 375, 375, 375];
    uint internal constant PERCENT_DIVIDER = 10000;
    mapping(address => mapping(uint => uint)) public poolWithdrawals;
    uint public totalInvested;

    mapping(address => mapping(uint => uint)) public poolInvested;
    mapping(uint => EnumerableSet.AddressSet) internal poolUsers;
    mapping(address => mapping(uint => uint[REFERRAL_LENGTH])) public poolUserReferrals;
    uint internal constant minPool = 1;
    uint internal constant maxPool = 9;

    mapping(address => address) public referral;
    mapping(address => bool) public isInversor;
    mapping(uint => uint) public poolUsersCounts;

    address public ceo;
    address internal feeReceiver;

	address[5] public partners;
    mapping(uint => uint) public poolPrices;

    event Withdrawal(address indexed sender, uint amount);

    constructor(address _ceo, address _fee, address _p1, address _p2, address _p3, address _p4, address _p5) {
        ceo = _ceo;
        feeReceiver = _fee;
        partners[0] = _p1;
        partners[1] = _p2;
        partners[2] = _p3;
        partners[3] = _p4;
        partners[4] = _p5;
        poolPrices[1] = 70 ether;
        poolPrices[2] = 100 ether;
        poolPrices[3] = 200 ether;
        poolPrices[4] = 300 ether;
        poolPrices[5] = 400 ether;
        poolPrices[6] = 500 ether;
        poolPrices[7] = 700 ether;
        poolPrices[8] = 900 ether;
        poolPrices[9] = 1500 ether;
        initPools();
    }

    function invest(uint _pool, address _referral) external payable {
        require(isValidPool(_pool), "Invalid pool");
        require(isInversor[_referral], "Invalid referral");
        require(msg.value == poolPrices[_pool], "incorrect amount");
        if(_pool > minPool) {
            require(isPoolUser(_pool - 1, msg.sender), "Not in previous pool");
        }
        if(referral[msg.sender] == address(0)) {
            require(msg.sender != _referral, "You cant refer yourself");
            referral[msg.sender] = _referral;
            poolUsers[_pool].add(msg.sender);
        }
        isInversor[msg.sender] = true;
        poolInvested[msg.sender][_pool] += msg.value;
        totalInvested += msg.value;
        poolUsersCounts[_pool]++;
        address upline = referral[msg.sender];
        for(uint i; i < REFERRAL_LENGTH; i++) {
            if(upline == address(0) || !isPoolUser(_pool, upline)) {
                upline = feeReceiver;
            }
            uint _toWithdraw = (msg.value * REFERRAL_PERCENTS[i]) / PERCENT_DIVIDER;
            poolWithdrawals[upline][_pool] += _toWithdraw;
            payable(upline).transfer(_toWithdraw);
            poolUserReferrals[upline][_pool][i] += 1;
            upline = referral[upline];
        }
        payFees();
    }



    function isPoolUser(uint _pool, address _user) public view returns(bool) {
        return poolInvested[_user][_pool] > 0;
    }

    function isValidPool(uint _pool) public pure returns(bool) {
        return _pool >= minPool && _pool <= maxPool;
    }

    function payFees() internal {
        payable(ceo).transfer(getBalance());
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function userTotalInvested(address _user) public view returns(uint) {
        uint total;
        for(uint i = minPool; i <= maxPool; i++) {
            total += poolInvested[_user][i];
        }
        return total;
    }

    function userTotalWithdrawals(address _user) public view returns(uint) {
        uint total;
        for(uint i = minPool; i <= maxPool; i++) {
            total += poolWithdrawals[_user][i];
        }
        return total;
    }

    function getUserStruct(uint _pool, address _user) public view returns(User memory) {
        return User(_user, referral[_user], poolInvested[_user][_pool], poolWithdrawals[_user][_pool], poolUserReferrals[_user][_pool]);
    }
    function getPoolUsers(uint _pool) external view returns(address[] memory) {
        address[] memory result = new address[](poolUsers[_pool].length());
        for(uint i; i < poolUsers[_pool].length(); i++) {
            result[i] = poolUsers[_pool].at(i);
        }
        return result;
    }

    function getPoolUsersInRange(uint _pool, uint _min, uint _max) external view returns(address[] memory) {
        uint _length = _max - _min + 1;
        address[] memory result = new address[](_length);
        for(uint i = _min; i < _max; i++) {
            result[i] = poolUsers[_pool].at(i);
        }
        return result;
    }

    function getPoolUsersStruct(uint _pool) external view returns(User[] memory) {
        User[] memory result = new User[](poolUsers[_pool].length());
        for(uint i; i < poolUsers[_pool].length(); i++) {
            address _user = poolUsers[_pool].at(i);
            result[i] = User(_user, referral[_user], poolInvested[_user][_pool], poolWithdrawals[_user][_pool], poolUserReferrals[_user][_pool]);
        }
        return result;
    }

    function getPoolUsersStructInRange(uint _pool, uint _min, uint _max) external view returns(User[] memory) {
        uint _length = _max - _min + 1;
        User[] memory result = new User[](_length);
        for(uint i = _min; i < _max; i++) {
            address _user = poolUsers[_pool].at(i);
            result[i] = User(_user, referral[_user], poolInvested[_user][_pool], poolWithdrawals[_user][_pool], poolUserReferrals[_user][_pool]);
        }
        return result;
    }

    struct refStruct {
        uint[REFERRAL_LENGTH] referrals;
    }

    function getRefUser(address _user) public view returns(refStruct[maxPool]  memory) {
        refStruct[maxPool] memory result;
        for(uint i = minPool; i <= maxPool; i++) {
            result[i - 1] = refStruct(poolUserReferrals[_user][i]);
        }
        return result;
    }

    function getAllPoolUsers() public view returns(uint[maxPool] memory) {
        uint[maxPool] memory result;
        for(uint i = minPool; i <= maxPool; i++) {
            result[i - 1] = poolUsersCounts[i];
        }
        return result;
    }

    function initPools() internal {
        for(uint i = minPool; i <= maxPool; i++) {
            for(uint j; j < partners.length; j++) {
                poolUsers[i].add(partners[j]);
                poolInvested[partners[j]][i] = poolPrices[i];
                isInversor[partners[j]] = true;
            }
            poolUsersCounts[i] += partners.length;
        }
    }

    function registerUser1(address[] memory _user) public onlyOwner {
        uint[] memory newRegistered = new uint[](maxPool - minPool + 1);
        for(uint i = minPool; i <= maxPool; i++) {
            for(uint j; j < _user.length; j++) {
                if(_user[i] != address(0)) {
                    if(!isPoolUser(i, _user[j])) {
                        poolUsers[i].add(_user[j]);
                        poolInvested[_user[j]][i] += poolPrices[i];
                        if(i == minPool) {
                            isInversor[_user[j]] = true;
                            referral[_user[j]] = partners[0];
                        }
                        newRegistered[i - 1]++;
                    }
                }
            }
        }

        for(uint i = minPool; i <= maxPool; i++) {
            poolUsersCounts[i] += newRegistered[i - 1];
        }

    }

    function registerUser2(address[] memory _user, address _referrer) external onlyOwner {
        registerUser2(_user, _referrer, true);
    }

    function registerUser2(address[] memory _user, address _referrer, bool _regReff) internal {
        uint[] memory newRegistered = new uint[](maxPool - minPool + 1);
        for(uint i = minPool; i <= maxPool; i++) {
            if(_regReff && !isPoolUser(i, _referrer)) {
                poolUsers[i].add(_referrer);
                poolInvested[_referrer][i] += poolPrices[i];
                if(i == minPool) {
                    isInversor[_referrer] = true;
                    referral[_referrer] = partners[0];
                }
                newRegistered[i - 1]++;
            }
            for(uint j; j < _user.length; j++) {
                if(_user[j] != address(0)) {
                    if(!isPoolUser(i, _user[j])) {
                        poolUsers[i].add(_user[j]);
                        poolInvested[_user[j]][i] += poolPrices[i];
                        if(i == minPool) {
                            isInversor[_user[j]] = true;
                            if(_user[j] != _referrer && referral[_user[j]] == address(0) && _referrer != address(0)) {
                                referral[_user[j]] = _referrer;
                            }
                        }
                        newRegistered[i - 1]++;
                    }
                }
            }
        }

        for(uint i = minPool; i <= maxPool; i++) {
            poolUsersCounts[i] += newRegistered[i - 1];
        }
    }

    function registerUser3(address[][] memory lvl3, address[] memory lvl2, address lvl1) external onlyOwner {
        require(lvl3.length == lvl2.length);
        for(uint i; i < lvl3.length; i++) {
            registerUser2(lvl3[i], lvl2[i], false);
        }
        registerUser2(lvl2, lvl1, true);
    }

    function checkReferral(address[] memory lvl2, address lvl1) public view returns(bool) {
        for(uint i; i < lvl2.length; i++) {
            if(lvl2[i] != address(0)) {
                if(referral[lvl2[i]] != lvl1) {
                    return false;
                }
            }
        }
        return true;
    }

    function checkReferralv2(address[][] memory lvl3, address[] memory lvl2, address lvl1) external view returns(bool) {
        require(lvl3.length == lvl2.length);
        for(uint i; i < lvl3.length; i++) {
            if(!checkReferral(lvl3[i], lvl2[i])) {
                return false;
            }
        }
        return checkReferral(lvl2, lvl1);
    }

    function chekDefaultRefferral(address[] memory lvl1) external view returns(bool) {
        for(uint i; i < lvl1.length; i++) {
            if(lvl1[i] != address(0)) {
                if(referral[lvl1[i]] != partners[0]) {
                    return false;
                }
            }
        }
        return true;
    }

    function getDAte() public view returns(uint) {
        return block.timestamp;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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