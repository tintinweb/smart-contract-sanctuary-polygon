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

pragma solidity 0.8.4;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { Pagination } from "../../utils/Pagination.sol";

contract FriendsRegistry {
	using EnumerableSet for EnumerableSet.AddressSet;

	event FriendRequestSent(address indexed sender, address indexed recipient);
	event FriendRequestAccepted(
		address indexed sender,
		address indexed recipient
	);
	event FriendRequestRejected(
		address indexed sender,
		address indexed recipient
	);
	event FriendRequestCanceled(
		address indexed sender,
		address indexed recipient
	);
	event FriendRemoved(address indexed remover, address indexed otherFriend);

	mapping(address => EnumerableSet.AddressSet) internal friends;
	mapping(address => EnumerableSet.AddressSet)
		internal pendingIncomingFriendRequests;
	mapping(address => EnumerableSet.AddressSet)
		internal pendingOutgoingFriendRequests;
	mapping(address => EnumerableSet.AddressSet)
		internal rejectedIncomingFriendRequests;
	mapping(address => EnumerableSet.AddressSet)
		internal rejectedOutgoingFriendRequests;

	/**
	 * @notice Send friend request from `msg.sender` to `recipient`. Reverts if request is already sent
	 */
	function sendFriendRequest(address recipient) public virtual {
		_addFriendRequest(msg.sender, recipient);
	}

	/**
	 * @notice Accept friend request from `sender` to `msg.sender`. Reverts if there is no request
	 */
	function acceptFriendRequest(address sender) public virtual {
		_acceptFriendRequest(sender, msg.sender);
	}

	/**
	 * @notice Reject friend request from `sender` to `msg.sender`. Reverts if there is no request
	 */
	function rejectFriendRequest(address sender) public virtual {
		_rejectFriendRequest(sender, msg.sender);
	}

	/**
	 * @notice Cancel an already sent friend request `msg.sender` to `recipient`. Reverts if there is no request
	 */
	function cancelFriendRequest(address sender) public virtual {
		_cancelFriendRequest(msg.sender, sender);
	}

	/**
	 * @notice Remove friend from `msg.sender` friend list. Reverts account removed is not in friend list.
	 * @param friend Account address to remove from the friend list
	 */
	function removeFriend(address friend) public virtual {
		_removeFriend(msg.sender, friend);
	}

	/**
	 * @notice Check whether `maybeFriend` is in `account` friend list.
	 */
	function isFriendOf(address account, address maybeFriend)
		public
		view
		virtual
		returns (bool)
	{
		return friends[account].contains(maybeFriend);
	}

	/**
	 * @notice Get friend list of an `account`. Reverts if `startIndex` > `endIndex`.
	 * To get all friends, pass 0 and 2^256 as `startIndex` and `endIndex`.
	 * @param account Whose friend list to get
	 * @param startIndex Start index of a page
	 * @param endIndex End index of a page
	 */
	function getFriendsOf(
		address account,
		uint256 startIndex,
		uint256 endIndex
	) public view virtual returns (address[] memory) {
		return Pagination.paginate(friends[account], startIndex, endIndex);
	}

	/**
	 * @notice Get pending incoming friend requests list of an `account`. Reverts if `startIndex` > `endIndex`.
	 * To get all requests, pass 0 and 2^256 as `startIndex` and `endIndex`.
	 * @param account Whose friend requests list to get
	 * @param startIndex Start index of a page
	 * @param endIndex End index of a page
	 */
	function getPendingIncomingFriendRequestsOf(
		address account,
		uint256 startIndex,
		uint256 endIndex
	) public view virtual returns (address[] memory) {
		return
			Pagination.paginate(
				pendingIncomingFriendRequests[account],
				startIndex,
				endIndex
			);
	}

	/**
	 * @notice Get pending outgoing friend requests list of an `account`. Reverts if `startIndex` > `endIndex`.
	 * To get all requests, pass 0 and 2^256 as `startIndex` and `endIndex`.
	 * @param account Whose friend requests list to get
	 * @param startIndex Start index of a page
	 * @param endIndex End index of a page
	 */
	function getPendingOutgoingFriendRequestsOf(
		address account,
		uint256 startIndex,
		uint256 endIndex
	) public view virtual returns (address[] memory) {
		return
			Pagination.paginate(
				pendingOutgoingFriendRequests[account],
				startIndex,
				endIndex
			);
	}

	/**
	 * @notice Get rejected incoming friend requests list of an `account`. Reverts if `startIndex` > `endIndex`.
	 * To get all requests, pass 0 and 2^256 as `startIndex` and `endIndex`.
	 * @param account Whose friend requests list to get
	 * @param startIndex Start index of a page
	 * @param endIndex End index of a page
	 */
	function getRejectedIncomingFriendRequestsOf(
		address account,
		uint256 startIndex,
		uint256 endIndex
	) public view virtual returns (address[] memory) {
		return
			Pagination.paginate(
				rejectedIncomingFriendRequests[account],
				startIndex,
				endIndex
			);
	}

	/**
	 * @notice Get rejected outgoing friend requests list of an `account`. Reverts if `startIndex` > `endIndex`.
	 * To get all requests, pass 0 and 2^256 as `startIndex` and `endIndex`.
	 * @param account Whose friend requests list to get
	 * @param startIndex Start index of a page
	 * @param endIndex End index of a page
	 */
	function getRejectedOutgoingFriendRequestsOf(
		address account,
		uint256 startIndex,
		uint256 endIndex
	) public view virtual returns (address[] memory) {
		return
			Pagination.paginate(
				rejectedOutgoingFriendRequests[account],
				startIndex,
				endIndex
			);
	}

	function version() public view virtual returns (uint256) {
		return 1;
	}

	function _addFriendRequest(address sender, address recipient) internal {
		require(!isFriendOf(sender, recipient), "already a friend");

		_removeRejectedFriendRequests(sender, recipient);
		require(
			pendingOutgoingFriendRequests[sender].add(recipient),
			"friend request already sent"
		);
		require(
			pendingIncomingFriendRequests[recipient].add(sender),
			"friend request already sent 2"
		);
		emit FriendRequestSent(sender, recipient);
	}

	function _acceptFriendRequest(address sender, address recipient) internal {
		_removePendingFriendRequests(sender, recipient);
		require(friends[sender].add(recipient), "already a friend");
		require(friends[recipient].add(sender), "already a friend 2");
		emit FriendRequestAccepted(sender, recipient);
	}

	function _rejectFriendRequest(address sender, address recipient) internal {
		_removePendingFriendRequests(sender, recipient);
		rejectedOutgoingFriendRequests[sender].add(recipient);
		rejectedIncomingFriendRequests[recipient].add(sender);
		emit FriendRequestRejected(sender, recipient);
	}

	function _cancelFriendRequest(address sender, address recipient) internal {
		_removePendingFriendRequests(sender, recipient);
		emit FriendRequestCanceled(sender, recipient);
	}

	function _removeFriend(address remover, address otherFriend) internal {
		require(friends[remover].remove(otherFriend), "not a friend");
		require(friends[otherFriend].remove(remover), "not a friend 2");
		emit FriendRemoved(remover, otherFriend);
	}

	function _removePendingFriendRequests(address sender, address recipient)
		internal
	{
		require(!isFriendOf(sender, recipient), "already a friend");
		require(
			pendingOutgoingFriendRequests[sender].remove(recipient),
			"no friend request"
		);
		require(
			pendingIncomingFriendRequests[recipient].remove(sender),
			"no friend request 2"
		);
		pendingOutgoingFriendRequests[recipient].remove(sender);
		pendingIncomingFriendRequests[sender].remove(recipient);
	}

	function _removeRejectedFriendRequests(address sender, address recipient)
		internal
	{
		rejectedOutgoingFriendRequests[sender].remove(recipient);
		rejectedIncomingFriendRequests[recipient].remove(sender);
	}
}

pragma solidity 0.8.4;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library Pagination {
	using EnumerableSet for EnumerableSet.AddressSet;

	function paginate(
		EnumerableSet.AddressSet storage set,
		uint256 startIndex,
		uint256 endIndex
	) internal view returns (address[] memory) {
		require(startIndex <= endIndex, "startIndex > endIndex");
		uint256 len = set.length();
		if (len == 0 || startIndex >= len) {
			return new address[](0);
		}
		if (endIndex > len) {
			endIndex = len;
		}
		len = endIndex - startIndex;
		address[] memory page = new address[](len);
		for (uint256 i = 0; i < len; i++) {
			page[i] = set.at(startIndex + i);
		}
		return page;
	}
}