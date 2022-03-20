// SPDX-License-Identifier: MIT
/// @author MrD 

pragma solidity >=0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./RentShares.sol";


contract GameCoordinator is Ownable {

  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;
    
    
  EnumerableSet.AddressSet private gameContracts;

	RentShares public rentShares;

  uint256 public activeTimeLimit;

	struct GameInfo {
		address contractAddress; // game contract
		uint256 minLevel; // min level for this game to be unlocked
		uint256 maxLevel; // max level this game can give
	}

	struct PlayerInfo {
      uint256 rewards; //pending rewards that are not rent shares
      uint256 level; //the current level for this player
      uint256 totalClaimed; //lifetime mnop claimed from the game
      uint256 totalPaid; //lifetime rent and taxes paid
      uint256 totalRolls; //total rolls for this player
      uint256 lastRollTime; // timestamp of the last roll on any board
    }

    mapping(uint256 => GameInfo) public gameInfo;
    mapping(address => PlayerInfo) public playerInfo;

    uint256 public totalPlayers;

    constructor(
        RentShares _rentSharesAddress, // rent share contract
        uint256 _activeTimeLimit 
    ) {

      	rentShares = _rentSharesAddress;
        activeTimeLimit = _activeTimeLimit;
      /*
      	for (uint i=0; i<_gameContracts.length; i++) {
      		setGame(i,_gameContracts[i],_minLevel[i],_maxLevel[i]);
      	} */
    }

    /** 
    * @notice Modifier to only allow updates by the VRFCoordinator contract
    */
    modifier onlyGame {
        require(gameContracts.contains(address(msg.sender)), 'Game Only');
        _;
    }

    function getRewards(address _address) external view returns(uint256) {
      return playerInfo[_address].rewards;
    }

    function getLevel(address _address) external view returns(uint256) {
    	return playerInfo[_address].level;
    }

    function getTotalRolls(address _address) external view returns(uint256) {
      return playerInfo[_address].totalRolls;
    }

    function getLastRollTime(address _address) external view returns(uint256) {
      return playerInfo[_address].lastRollTime;
    }

    function addTotalPlayers(uint256 _amount) public onlyGame {
      totalPlayers = totalPlayers.add(_amount);
    }    

    function addRewards(address _address, uint256 _amount) public onlyGame {
      playerInfo[_address].rewards = playerInfo[_address].rewards.add(_amount);
    }

    function setLevel(address _address, uint256 _level) public onlyGame {
      playerInfo[_address].level = _level;
    }

    function addTotalClaimed(address _address, uint256 _amount) public onlyGame {
      playerInfo[_address].totalClaimed = playerInfo[_address].totalClaimed.add(_amount);
    }

    function addTotalPaid(address _address, uint256 _amount) public onlyGame {
      playerInfo[_address].totalPaid = playerInfo[_address].totalPaid.add(_amount);
    }

    function addTotalRolls(address _address) public onlyGame {
      playerInfo[_address].totalRolls = playerInfo[_address].totalRolls.add(1);
    }

    function setLastRollTime(address _address, uint256 _lastRollTime) public onlyGame {
      playerInfo[_address].lastRollTime = _lastRollTime;
    }

    function setGame(uint256 _gameId, address _gameContract, uint256 _minLevel, uint256 _maxLevel) public onlyOwner {
    	
      if(!gameContracts.contains(address(_gameContract))){
        gameContracts.add(address(_gameContract));
      }
      gameInfo[_gameId].contractAddress = _gameContract;
    	gameInfo[_gameId].minLevel = _minLevel;
    	gameInfo[_gameId].maxLevel = _maxLevel;

    }

    function removeGame(uint256 _gameId) public onlyOwner {
    	require(gameInfo[_gameId].maxLevel > 0, 'Game Not Found');
      gameContracts.remove(address(gameInfo[_gameId].contractAddress));
    	delete gameInfo[_gameId];
    }

    function canPlay(address _player, uint256 _gameId)  external view returns(bool){
    	return _canPlay(_player, _gameId);
    }
    
    function _canPlay(address _player, uint256 _gameId)  internal view returns(bool){
    	if(playerInfo[_player].level >= gameInfo[_gameId].minLevel){
    		return true;
    	}

    	return false;
    }

    function playerActive(address _player) external view returns(bool){
        return _playerActive(_player);
    }

    function _playerActive(address _player) internal view returns(bool){
        if(block.timestamp <= playerInfo[_player].lastRollTime.add(activeTimeLimit)){
            return true;
        }
        return false;
    }

    // Hook rent claims into this contract
    // check for the last roll
    // after 1 day every day reduces it by 10% up until there is only 10% left

    function claimRent() public {
    	require(rentShares.canClaim(msg.sender,0) > 0, 'Nothing to Claim');

    	// claim the rent share
    	rentShares.claimRent(msg.sender,_getMod(msg.sender));
    }

    function getRentOwed(address _address) public view returns(uint256) {
    	return rentShares.canClaim(_address,_getMod(_address));
    }

    function _getMod(address _address) private view returns(uint256) {
    	uint256 mod = 100;
    	uint256 cutOff = playerInfo[_address].lastRollTime.add(activeTimeLimit);

    	if(cutOff > block.timestamp) {
    		// we need to adjust 
    		// see how many days
    		uint256 d = cutOff.sub(block.timestamp).div(activeTimeLimit);
    		//if over 10 days, force it to 10%
    		if(d > 10) {
    			mod = 10;
    		} else {
    			mod = mod.sub(d.mul(10));
    		}
    	}
    	return mod;
    }

    function setRentShares(RentShares _rentShares) public onlyOwner {
      rentShares = _rentShares;
    }

    function setActiveTimeLimi(uint256 _activeTimeLimit) public onlyOwner {
      activeTimeLimit = _activeTimeLimit;
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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
/// @author MrD 

pragma solidity >=0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract RentShares is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

	// each property has a unique total of "shares"
	// each time someone stakes an active property shares are given
	// each time someone un-stakes an active property shares are removed
	// shares should be tied to the NFT ids not the spot, so that old shares can be claimed


	// keeps a total for each user per property
	// time before they expire
	// if they haven't claimed in X it burns the excess on claim


	// game contract sends MNOP to rent shares contract instead of doing the math
	// rent shares contract only accepts from game contract 


	// The burn address
    address public constant burnAddress = address(0xdead);

    // array of all property nfts that get rent
    uint256[] public nfts;
    // a fast way to check if it's a registered nft
    mapping(uint256 => bool) public nftExists;

    IERC20 public token;
    address public gameCoordinator;

    mapping(address => bool) private canGive;

    mapping(uint256 => uint256) public totalRentSharePoints;
	//lock for the rent claim only 1 claim at a time
    bool private _isWithdrawing;
    //Multiplier to add some accuracy to profitPerShare
    uint256 private constant DistributionMultiplier = 2**64;
    //profit for each share a holder holds, a share equals a decimal.
    mapping(uint256 => uint256) private profitPerShare;
    //the total reward distributed through the vault, for tracking purposes
    mapping(uint256 => uint256) public totalShareRewards;
    //the total payout through the vault, for tracking purposes
    mapping(uint256 => uint256) public totalPayouts;
    uint256 public allTotalPayouts;
    uint256 public allTotalBurns;
    uint256 public allTotalPaid;
    mapping(address => mapping(uint256 => uint256)) private rentShares;
    //Mapping of the already paid out(or missed) shares of each staker
    mapping(address => mapping(uint256 => uint256)) private alreadyPaidShares;
    //Mapping of shares that are reserved for payout
    mapping(address => mapping(uint256 => uint256)) private toBePaid;
    //Mapping of static rewards pending for an address
    mapping(address => uint256) private pendingRewards;

    constructor (
        IERC20 _tokenAddress,
        address _gameCoordinator,
        uint256[] memory _nfts
    ) {
        token = _tokenAddress;
        gameCoordinator = _gameCoordinator;

        for (uint i=0; i<_nfts.length; i++) {
            addNft(_nfts[i]);
        }
        token.approve(address(gameCoordinator), type(uint256).max);
        token.approve(address(this), type(uint256).max);
    }

    modifier onlyCanGive {
      require(canGive[msg.sender], "Can't do this");
      _;
    }


    // add NFT
    function addNft(uint256 _nftId) public onlyOwner {
        if(!_isInArray(_nftId, nfts)){
            nfts.push(_nftId);
            nftExists[_nftId] = true;
        }
    }

    // bulk add NFTS
    function addNfts(uint256[] calldata _nfts) external onlyOwner {
        for (uint i=0; i<_nfts.length; i++) {
            addNft(_nfts[i]);
        }
    }

	// manage which contracts/addresses can give shares to allow other contracts to interact
    function setCanGive(address _addr, bool _canGive) public onlyOwner {
        canGive[_addr] = _canGive;
    }

    //gets shares of an address/nft
    function getRentShares(address _addr, uint256 _nftId) public view returns(uint256){
        return (rentShares[_addr][_nftId]);
    }

    //Returns the amount a player can still claim
    function getAllRentOwed(address _addr, uint256 _mod) public view returns (uint256){

    	uint256 amount;
        for (uint i=0; i<nfts.length; i++) {
        	amount += getRentOwed(_addr, nfts[i]);
        }

        if(_mod > 0){
       		// adjust with the no claim mod
	        amount = amount.mul(_mod).div(100);
        }

        return amount;
    }

    function getRentOwed(address _addr, uint256 _nftId) public view returns (uint256){
       return  _getRentOwed(_addr, _nftId) + toBePaid[_addr][_nftId];
    }

    function canClaim(address _addr, uint256 _mod) public view returns (uint256){

        uint256 amount;
        for (uint i=0; i<nfts.length; i++) {
            amount += _getRentOwed(_addr, nfts[i]) + toBePaid[_addr][nfts[i]];
        }

        if(_mod > 0){
            // adjust with the no claim mod
            amount = amount.mul(_mod).div(100);
        }

        return getAllRentOwed(_addr, _mod).add(pendingRewards[_addr]);
    }

    function collectRent(address _addr, uint256 _nftId, uint256 _amount) public onlyCanGive nonReentrant {
        allTotalPaid += _amount;
        _updatePorfitPerShare(_amount, _nftId);
        token.safeTransferFrom(address(msg.sender),address(this), _amount); 

    }
    
	// claim any pending rent, only allow 1 claim at a time
	//
	function claimRent(address _address, uint256 _mod) public nonReentrant {
		require(address(msg.sender) == address(gameCoordinator), 'Nope');
        require(!_isWithdrawing,'in progress');
        

        _isWithdrawing=true;

        // get everything to claim for this address
        uint256 amount;
        for (uint i=0; i<nfts.length; i++) {
            if(rentShares[_address][nfts[i]] > 0) {
            	uint256 amt = _getRentOwed(_address,nfts[i]);
            	if(amt > 0){
            		//Substracts the amount from the rent dividends
            		_updateClaimedRent(_address, nfts[i], amt);
            		totalPayouts[nfts[i]]+=amt;
                    amount += amt;
            	}
            }
        	
        }
        

        // adjust with the no claim mod
        uint256  claimAmount = amount.mul(_mod).div(100);
        uint256  burnAmount = amount.sub(claimAmount);

        // add any static rewards
        if(pendingRewards[_address] > 0){
            claimAmount = claimAmount.add(pendingRewards[_address]);
            pendingRewards[_address] = 0;
        }
        
        require(claimAmount!=0 || burnAmount!=0,"=0"); 

        allTotalPayouts+=claimAmount;
        allTotalBurns+=burnAmount;

        token.transferFrom(address(this),_address, claimAmount);

        if(burnAmount > 0){
			token.transferFrom(address(this),burnAddress, burnAmount);        	
        }

        _isWithdrawing=false;
//        emit OnClaimBNB(_address,amount);

    }

    function addPendingRewards(address _addr, uint256 _amount) public onlyCanGive {
      pendingRewards[_addr] = pendingRewards[_addr].add(_amount);
    }

    function giveShare(address _addr, uint256 _nftId) public onlyCanGive {
        require(nftExists[_nftId], 'Not a property');
        _addShare(_addr,_nftId);
    }

    function removeShare(address _addr, uint256 _nftId) public onlyCanGive {
        require(nftExists[_nftId], 'Not a property');
        _removeShare(_addr,_nftId);
    }

    function batchGiveShares(address _addr, uint256[] calldata _nftIds) external onlyCanGive {
      
        uint256 length = _nftIds.length;
        for (uint256 i = 0; i < length; ++i) {
            // require(nftExists[_nftId], 'Not a property');
            if(nftExists[_nftIds[i]]) {
                _addShare(_addr,_nftIds[i]);
            }
        }
    }

    function batchRemoveShares(address _addr, uint256[] calldata _nftIds) external onlyCanGive {
        
        uint256 length = _nftIds.length;
        for (uint256 i = 0; i < length; ++i) {
            // require(nftExists[_nftId], 'Not a property');
            if(nftExists[_nftIds[i]]) {
                _removeShare(_addr,_nftIds[i]);
            }
        }
    }



    //adds shares to balances, adds new Tokens to the toBePaid mapping and resets staking
    function _addShare(address _addr, uint256 _nftId) private {
        // the new amount of points
        uint256 newAmount = rentShares[_addr][_nftId].add(1);

        // update the total points
        totalRentSharePoints[_nftId]+=1;

        //gets the payout before the change
        uint256 payment = _getRentOwed(_addr, _nftId);

        //resets dividends to 0 for newAmount
        alreadyPaidShares[_addr][_nftId] = profitPerShare[_nftId].mul(newAmount);
        //adds dividends to the toBePaid mapping
        toBePaid[_addr][_nftId]+=payment; 
        //sets newBalance
        rentShares[_addr][_nftId]=newAmount;
    }

    //removes shares, adds Tokens to the toBePaid mapping and resets staking
    function _removeShare(address _addr, uint256 _nftId) private {
        //the amount of token after transfer
        uint256 newAmount=rentShares[_addr][_nftId].sub(1);
        totalRentSharePoints[_nftId] -= 1;

        //gets the payout before the change
        uint256 payment =_getRentOwed(_addr, _nftId);
        //sets newBalance
        rentShares[_addr][_nftId]=newAmount;
        //resets dividendss to 0 for newAmount
        alreadyPaidShares[_addr][_nftId] = profitPerShare[_nftId].mul(rentShares[_addr][_nftId]);
        //adds dividendss to the toBePaid mapping
        toBePaid[_addr][_nftId] += payment; 
    }



    //gets the rent owed to an address that aren't in the toBePaid mapping 
    function _getRentOwed(address _addr, uint256 _nftId) private view returns (uint256) {
        uint256 fullPayout = profitPerShare[_nftId].mul(rentShares[_addr][_nftId]);
        //if excluded from staking or some error return 0
        if(fullPayout<=alreadyPaidShares[_addr][_nftId]) return 0;
        return (fullPayout.sub(alreadyPaidShares[_addr][_nftId])).div(DistributionMultiplier);
    }


    //adjust the profit share with the new amount
    function _updatePorfitPerShare(uint256 _amount, uint256 _nftId) private {

        totalShareRewards[_nftId] += _amount;
        if (totalRentSharePoints[_nftId] > 0) {
            //Increases profit per share based on current total shares
            profitPerShare[_nftId] += ((_amount.mul(DistributionMultiplier)).div(totalRentSharePoints[_nftId]));
        }
    }

    //Substracts the amount from rent to claim, fails if amount exceeds dividends
    function _updateClaimedRent(address _addr, uint256 _nftId, uint256 _amount) private {
        if(_amount==0) return;
 
        require(_amount <= getRentOwed(_addr, _nftId),"exceeds amount");
        uint256 newAmount = _getRentOwed(_addr, _nftId);

        //sets payout mapping to current amount
        alreadyPaidShares[_addr][_nftId] = profitPerShare[_nftId].mul(rentShares[_addr][_nftId]);
        //the amount to be paid 
        toBePaid[_addr][_nftId]+=newAmount;
        toBePaid[_addr][_nftId]-=_amount;
    }

    function setContracts(IERC20 _tokenAddress, address _gameCoordinator) public onlyOwner {
        token = _tokenAddress;
        gameCoordinator = _gameCoordinator;
        token.approve(address(gameCoordinator), type(uint256).max);
    }
    /**
     * @dev Utility function to check if a value is inside an array
     */
    function _isInArray(uint256 _value, uint256[] memory _array) internal pure returns(bool) {
        uint256 length = _array.length;
        for (uint256 i = 0; i < length; ++i) {
            if (_array[i] == _value) {
                return true;
            }
        }
        return false;
    }

}