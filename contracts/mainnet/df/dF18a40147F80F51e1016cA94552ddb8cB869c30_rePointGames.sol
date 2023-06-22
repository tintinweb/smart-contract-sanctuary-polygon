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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
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
 * ```solidity
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
pragma solidity ^0.8.13;

interface IGame {
    function gameInfo() external view returns(string memory);
    function userGameInfo(address userAddr) external view returns(string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/PriceFeed.sol";
import "./utils/LiteralRegex.sol";
import "./interfaces/IGame.sol";

contract rePointGames is PriceFeed, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using LiteralRegex for string;

    uint256 public userCount;

    EnumerableSet.AddressSet _games;

    mapping(address => User) _users;
    mapping(string => address) _nameToAddr;
    mapping(address => address) _userRef;

    struct User{
        string username;
        bytes32 avatarId;
    }

    constructor(address aggregator) PriceFeed(aggregator) {
    }

// users -------------------------------------------------------------------------

    function register(
        string memory _username,
        string memory _referral,
        address _userAddr,
        bytes32 _avatarId
    ) public payable {
        require(
            _games.contains(msg.sender) || msg.sender == _userAddr,
            "rePointGames only games or users themselves can call register function"
        );
        require(
            _userAddr.code.length == 0,
            "rePointGames: onlyEOAs can register"
        );
        require(
            _avatarId != 0x00, 
            "rePointGames: unacceptable zero avatar id"
        );
        require(
            msg.value >= enterPriceMATIC() * 98/100,
            "rePointGames: insufficient fee"
        );
        uint256 usernameLen = bytes(_username).length;
        require(
            usernameLen >= 4 && usernameLen <= 16,
            "rePointGames: the username must be between 4 and 16 characters" 
        );
        require(
            _username.isLiteral(),
            "rePointGames: you can just use numbers(0-9) letters(a-zA-Z) and signs(-._)" 
        );
        require(
            _nameToAddr[_username] == address(0),
            "rePointGames: This username is taken!"
        );
        require(
            _users[_userAddr].avatarId == 0x00,
            "rePointGames: This address is already registered!"
        );
        payable(owner()).transfer(msg.value);
        if(bytes(_referral).length != 0) {
            address _refAddr = _nameToAddr[_referral];
            require(_refAddr != address(0), "rePointGames: unregistered referral");
            _userRef[_userAddr] = _refAddr;
        }
        _users[_userAddr] = User(_username, _avatarId);
        _nameToAddr[_username] = _userAddr;
        userCount ++;
    }

    function changeInfo(string memory _username, bytes32 _avatarId) public {
        uint256 usernameLen = bytes(_username).length;
        require(
            usernameLen >= 4 && usernameLen <= 16,
            "rePointGames: the username must be between 4 and 16 characters" 
        );
        require(
            _username.isLiteral(),
            "rePointGames: you can just use numbers(0-9) letters(a-zA-Z) and signs(-._)" 
        );
        require(
            _nameToAddr[_username] == address(0),
            "rePointGames: This username is taken!"
        );
        require(
            _users[msg.sender].avatarId != 0x00,
            "rePointGames: you have not registered yet"
        );

        string memory lastUsername = _users[msg.sender].username;
        _users[msg.sender] = User(_username, _avatarId);
        delete _nameToAddr[lastUsername];
        _nameToAddr[_username] = msg.sender;
    }

    function userAddrRegistered(address _userAddr) public view returns(bool) {
        return _users[_userAddr].avatarId != 0x00;
    }
    function usernameRegistered(string memory _username) public view returns(bool) {
        return _nameToAddr[_username] != address(0);
    }

    function userAddrInfo(address _userAddr) 
        public view 
        returns(string memory _username, bytes32 _avatarId)
    {
        _username = _users[_userAddr].username;
        _avatarId = _users[_userAddr].avatarId;
    }

    function usernameInfo(string memory _username) 
        public view 
        returns(address _userAddr, bytes32 _avatarId)
    {
        _userAddr = _nameToAddr[_username];
        _avatarId = _users[_userAddr].avatarId;
    }

    function username(string memory _username) 
        public view 
        returns(address _userAddr, bytes32 _avatarId)
    {
        _userAddr = _nameToAddr[_username];
        _avatarId = _users[_userAddr].avatarId;
    }

    function userAddr(string memory _username) 
        public view 
        returns(address _userAddr)
    {
        _userAddr = _nameToAddr[_username];
    }

    function usernameGamesInfo(string memory _username) 
        public view 
        returns(string[] memory infos)
    {
        address _userAddr = _nameToAddr[_username];
        infos = userAddrGamesInfo(_userAddr); 
    }

    function usernameGameInfo(string memory _username, address _gameAddr) 
        public view 
        returns(string memory info)
    {
        address _userAddr = _nameToAddr[_username];
        info = userAddrGameInfo(_userAddr, _gameAddr);
    }

    function userAddrGamesInfo(address _userAddr) 
        public view 
        returns(string[] memory infos)
    {
        uint256 len = _games.length();
        infos = new string[](len);

        for(uint256 i; i < len; i++) {
            infos[i] = IGame(_games.at(i)).userGameInfo(_userAddr);
        }
    }

    function userAddrGameInfo(address _userAddr, address _gameAddr) 
        public view 
        returns(string memory info)
    {
        info = IGame(_gameAddr).userGameInfo(_userAddr);
    }

    function userReferral(address _userAddr) public view returns(address _refAddr) {
        return _userRef[_userAddr];
    }

    function usernameReferral(string memory _username) public view returns(string memory) {
        return _users[_userRef[_nameToAddr[_username]]].username;
    }

// games -------------------------------------------------------------------------

    function addGame(address gameAddr) public onlyOwner {
        _games.add(gameAddr);
    }

    function removeGame(address gameAddr) public onlyOwner {
        _games.remove(gameAddr);
    }

    function gamesAddr() public view returns(address[] memory) {
        return _games.values();
    }

    function gamesInfo() public view returns(string[] memory infos) {
        uint256 len = _games.length();
        infos = new string[](len);

        for(uint256 i; i < len; i++) {
            infos[i] = IGame(_games.at(i)).gameInfo();
        }
    }

    function gameInfo(address gameAddr) public view returns(string memory info) {
        return IGame(gameAddr).gameInfo();
    }

    function games() public view returns(
        address[] memory addrs,
        string[] memory infos
    ) {
        addrs = gamesAddr();
        infos = gamesInfo();
    }


// prices -----------------------------------------------------------------------

    uint256 public enterPriceUSD;

    function setEnterPriceUSD(uint256 _enterPriceUSD) public onlyOwner {
        enterPriceUSD = _enterPriceUSD;
    }

    function enterPriceMATIC() public view returns(uint256) {
        return enterPriceUSD * USD_MATIC() / 10 ** 18;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library LiteralRegex {

    string constant regex = "[a-zA-Z0-9-._]";

    function isLiteral(string memory text) internal pure returns(bool) {
        bytes memory t = bytes(text);
        for (uint i = 0; i < t.length; i++) {
            if(!_isLiteral(t[i])) {return false;}
        }
        return true;
    }

    function _isLiteral(bytes1 char) private pure returns(bool status) {
        if (  
            char >= 0x30 && char <= 0x39 // `0-9`
            ||
            char >= 0x41 && char <= 0x5a // `A-Z`
            ||
            char >= 0x61 && char <= 0x7a // `a-z`
            ||
            char == 0x2d                 // `-`
            ||
            char == 0x2e                 // `.`
            ||
            char == 0x5f                 // `_`
        ) {
            status = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";

abstract contract PriceFeed {
    AggregatorInterface immutable AGGREGATOR_MATIC_USD;

    uint256 public chainId;

    constructor(
        address aggregatorAddr
    ) {
        AGGREGATOR_MATIC_USD = AggregatorInterface(aggregatorAddr);
        uint256 _chainId;
        assembly{
            _chainId := chainid()
        }
        chainId = _chainId;
    }

    function MATIC_USD() public view returns(uint256) {
        if(chainId == 31337) {
            return 10**18;
        } else {
            return uint256(AGGREGATOR_MATIC_USD.latestAnswer()) * 10 ** 10;
        }
    }

    function USD_MATIC() public view returns(uint256) {
        if(chainId == 31337) {
            return 10**18;
        } else {
            return 10 ** 26 / uint256(AGGREGATOR_MATIC_USD.latestAnswer());
        }
    }
}