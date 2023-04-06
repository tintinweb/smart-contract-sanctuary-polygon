/*
    SPDX-License-Identifier: Apache-2.0
    Copyright 2023 Reddit, Inc
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

error GlobalConfig__ZeroAddress();
error GlobalConfig__TokenIsNotAuthorized();
error GlobalConfig__TokenAlreadyAuthorized();
error GlobalConfig__AddressIsNotFiltered(address operator);
error GlobalConfig__AddressAlreadyFiltered(address operator);
error GlobalConfig__CodeHashIsNotFiltered(bytes32 codeHash);
error GlobalConfig__CodeHashAlreadyFiltered(bytes32 codeHash);
error GlobalConfig__CannotFilterEOAs();
/// @dev Following original Operator Filtering error signature to ensure compatibility
error AddressFiltered(address filtered);
/// @dev Following original Operator Filtering error signature to ensure compatibility
error CodeHashFiltered(address account, bytes32 codeHash);

/**
 * @title GlobalConfig
 * @notice One contract that maintains config values that other contracts read from - so if you need to change, only need to change here.
 * @dev Used by the [Splitter.sol] and [RedditCollectibleAvatars.sol].
 */
contract GlobalConfig is Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.Bytes32Set;

  event RedditRoyaltyAddressUpdated(address indexed oldAddress, address indexed newAddress);
  event AuthorizedERC20sUpdated(bool indexed removed, address indexed token, uint length);
  event FilteredOperatorUpdated(bool indexed filtered, address indexed operator, uint length);
  event FilteredCodeHashUpdated(bool indexed filtered, bytes32 indexed codeHash, uint length);
  event MinterUpdated(address current, address prevMinter, address removedMinter);
  event PreviousMinterCleared(address removedMinter);

  /// @dev Initialized accounts have a nonzero codehash (see https://eips.ethereum.org/EIPS/eip-1052)
  bytes32 constant private EOA_CODEHASH = keccak256("");

  // ------------------------------------------------------------------------------------
  // VARIABLES BLOCK, MAKE SURE ONLY ADD TO THE END

  /// @dev Referenced by the royalty splitter contract to withdraw reddit's share of NFT royalties
  address public redditRoyalty;

  /// @dev Set of ERC20 tokens authorized for royalty withdrawal by Reddit in the splitter contract
  EnumerableSet.AddressSet private authorizedERC20s;

  /// @dev Set of filtered (restricted/blocked) operator addresses
  EnumerableSet.AddressSet private filteredOperators;
  /// @dev Set of filtered (restricted/blocked) code hashes
  EnumerableSet.Bytes32Set private filteredCodeHashes;

  /// @dev Wallet address of the `minter` wallet
  address public minter;
  /// @dev Wallet address of the previous `minter` wallet to have no downtime during minter rotation
  address public prevMinter;

  // END OF VARS
  // ------------------------------------------------------------------------------------

  constructor(
    address _owner, 
    address _redditRoyalty, 
    address _minter,
    address[] memory _authorizedERC20s,
    address[] memory _filteredOperators,
    bytes32[] memory _filteredCodeHashes
  ) {
    _updateRedditRoyaltyAddress(_redditRoyalty);
    _updateMinter(_minter);

    for (uint i=0; i < _authorizedERC20s.length;) {
      authorizedERC20s.add(_authorizedERC20s[i]);
      unchecked { ++i; }
    }

    for (uint i=0; i < _filteredOperators.length;) {
      filteredOperators.add(_filteredOperators[i]);
      unchecked { ++i; }
    }

    for (uint i=0; i < _filteredCodeHashes.length;) {
      filteredCodeHashes.add(_filteredCodeHashes[i]);
      unchecked { ++i; }
    }

    if (_owner != _msgSender()) {
      Ownable.transferOwnership(_owner);
    }
  }

  /// @notice Update address of Reddit royalty receiver
  function updateRedditRoyaltyAddress(address newRedditAddress) external onlyOwner {
    _updateRedditRoyaltyAddress(newRedditAddress);
  }

  /// @notice Delete an authorized ERC20 token
  function deleteAuthorizedToken(address token) external onlyOwner {
    emit AuthorizedERC20sUpdated(true, token, authorizedERC20s.length() - 1);
    if (!authorizedERC20s.remove(token)) {
      revert GlobalConfig__TokenIsNotAuthorized();
    }
  }

  /// @notice Add an authorized ERC20 token
  function addAuthorizedToken(address token) external onlyOwner {
    emit AuthorizedERC20sUpdated(false, token, authorizedERC20s.length() + 1);
    if (!authorizedERC20s.add(token)) {
      revert GlobalConfig__TokenAlreadyAuthorized();
    }
  }

  /// @notice Array of authorized ERC20 tokens
  function authorizedERC20sArray() external view returns (address[] memory) {
    return authorizedERC20s.values();
  }

  /// @notice Checks if ERC20 token is authorized
  function authorizedERC20(address token) external view returns (bool) {
    return authorizedERC20s.contains(token);
  }

  /// @notice Add a filtered (restricted) operator address
  function addFilteredOperator(address operator) external onlyOwner {
    emit FilteredOperatorUpdated(true, operator, filteredOperators.length() + 1);
    if (!filteredOperators.add(operator)) {
      revert GlobalConfig__AddressAlreadyFiltered(operator);
    }
  }

  /// @notice Delete a filtered (restricted) operator address
  function deleteFilteredOperator(address operator) external onlyOwner {
    emit FilteredOperatorUpdated(false, operator, filteredOperators.length() - 1);
    if (!filteredOperators.remove(operator)) {
      revert GlobalConfig__AddressIsNotFiltered(operator);
    }
  }

  /// @notice Add a filtered (restricted) code hash
  /// @dev This will allow adding the bytes32(0) codehash, which could result in unexpected behavior,
  ///      since calling `isCodeHashFiltered` will return true for bytes32(0), which is the codeHash of any
  ///      un-initialized account. Since un-initialized accounts have no code, the registry will not validate
  ///      that an un-initalized account's codeHash is not filtered. By the time an account is able to
  ///      act as an operator (an account is initialized or a smart contract exclusively in the context of its
  ///      constructor), it will have a codeHash of EOA_CODEHASH, which cannot be filtered.
  function addFilteredCodeHash(bytes32 codeHash) external onlyOwner {
    if (codeHash == EOA_CODEHASH) {
      revert GlobalConfig__CannotFilterEOAs();
    }
    emit FilteredCodeHashUpdated(true, codeHash, filteredCodeHashes.length() + 1);
    if (!filteredCodeHashes.add(codeHash)) {
      revert GlobalConfig__CodeHashAlreadyFiltered(codeHash);
    }
  }

  /// @notice Delete a filtered (restricted) code hash
  function deleteFilteredCodeHash(bytes32 codeHash) external onlyOwner {
    if (codeHash == EOA_CODEHASH) {
      revert GlobalConfig__CannotFilterEOAs();
    }
    emit FilteredCodeHashUpdated(false, codeHash, filteredCodeHashes.length() - 1);
    if (!filteredCodeHashes.remove(codeHash)) {
      revert GlobalConfig__CodeHashIsNotFiltered(codeHash);
    }
  } 

  /// @notice Returns true if operator is not filtered, either by address or codeHash.
  /// @dev Will *revert* if an operator or its codehash is filtered with an error that is
  ///      more informational than a false boolean.
  function isOperatorAllowed(address operator) external view returns (bool) {
    if (filteredOperators.contains(operator)) {
      revert AddressFiltered(operator);
    }
    if (operator.code.length > 0) {
      bytes32 codeHash = operator.codehash;
      if (filteredCodeHashes.contains(codeHash)) {
        revert CodeHashFiltered(operator, codeHash);
      }
    }
    return true;
  }

  /**
   * @notice Updates the `minter` wallet address on the contract 
   * (note that only the `owner` wallet can execute this action)
   */
  function updateMinter(address account) public onlyOwner {
    _updateMinter(account);
  }

  function clearPreviousMinter() public onlyOwner {
    emit PreviousMinterCleared({removedMinter: prevMinter});
    prevMinter = address(0);
  }

  function _updateRedditRoyaltyAddress(address newRedditAddress) internal {
    if (newRedditAddress == address(0)) {
      revert GlobalConfig__ZeroAddress();
    }
    emit RedditRoyaltyAddressUpdated(redditRoyalty, newRedditAddress);
    redditRoyalty = newRedditAddress;
  }

  function _updateMinter(address newMinter) internal {
    if (newMinter == address(0)){
      revert GlobalConfig__ZeroAddress();
    }
    emit MinterUpdated({current: newMinter, prevMinter: minter, removedMinter: prevMinter});
    prevMinter = minter;
    minter = newMinter;
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