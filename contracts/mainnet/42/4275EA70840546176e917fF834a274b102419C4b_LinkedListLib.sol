// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

library LinkedListLib {
    address public constant ZERO_ADDRESS = address(0);
    /// @dev uses as prev for the first item
    address constant HEAD = address(1);

    struct LinkedListStorage {
        /// @dev pointer on the next item
        mapping(address => address) next;
        /// @dev pointer on the previous item
        mapping(address => address) prev;
        /// @dev items count. In some cases, for complicated structures, size can not be equal to item count, so size can
        /// @dev be redefined (as function) in a child contract. But for most cases size = items count
        uint256 size;
        /// @dev pointer to the last item
        address last;
        /// @dev uses for iteration through list in iterateFirst/iterateNext functions
        address iterator;
        /// @dev max iteration limit for one call of clear_start\clear_next. It can happen if the list is huge and clear
        /// @dev all items for one call will be impossible because of the block gas limit. So, this variable regulates
        /// @dev iteration limit for a single call. The value depends on use-cases and can be set to different numbers for
        /// @dev different project (gas consumption of clear_start\clear_next is stable, but it is unknown gas-consumption
        /// @dev of a caller, so this value should be picked up individually for each project)

        uint256 iterationCountLimit;
    }

    function _addressHeadCheck(address _address) private pure {
        require(_address > HEAD, "e0");
    }

    /// @dev list doesn't accept reserved values (ZERO_ADDRESS and HEAD)
    /// @param _address - address to check
    modifier shouldntUseReservedValues(address _address) {
        _addressHeadCheck(_address);
        _;
    }

    /// @dev init the last element and point it to Head
    /// @param _iterationCountLimit - max iteration limit for one call of clear_start\clear_next
    function initBaseDoubleLinkedList(
        LinkedListStorage storage list,
        uint256 _iterationCountLimit
    ) public {
        list.last = HEAD;
        list.iterationCountLimit = _iterationCountLimit;
    }

    /// @dev add an item to the list with complexity O(1)
    /// @param _address - item
    /// @return true if an item was added, false otherwise
    function _put(LinkedListStorage storage list, address _address)
        public
        shouldntUseReservedValues(_address)
        returns (bool)
    {
        //new item always has prev[_address] equal ZERO_ADDRESS
        if (list.prev[_address] == ZERO_ADDRESS) {
            //set the next element to _address for the current last element
            list.next[list.last] = _address;
            //set prev element of _address to the current last element
            list.prev[_address] = list.last;
            //set last to _address
            list.last = _address;
            ++list.size;
            return true;
        }
        return false;
    }

    /// @dev remove an item from the list with complexity of O(1).
    /// @param _address - item to delete
    /// @return true if the item was deleted, false otherwise
    function _remove(LinkedListStorage storage list, address _address)
        public
        shouldntUseReservedValues(_address)
        returns (bool)
    {
        //existing item has prev[_address] non equal ZERO_ADDRESS.
        if (list.prev[_address] != ZERO_ADDRESS) {
            address prevAddress = list.prev[_address];
            address nextAddress = list.next[_address];
            delete list.next[_address];
            //set next of prevAddress to next of _address
            list.next[prevAddress] = nextAddress;
            //if iterateFirst\iterateNext iterator equal _address, it means that it pointed to the deleted item,
            //So, the iterator should be reset to the next item
            if (list.iterator == _address) {
                list.iterator = nextAddress;
            }
            //if removed the last (by order, not by size) item
            if (nextAddress == ZERO_ADDRESS) {
                //set the pointer of the last item to prevAddress
                list.last = prevAddress;
            } else {
                //else prev item of next address sets to prev address of deleted item
                list.prev[nextAddress] = prevAddress;
            }

            delete list.prev[_address];
            --list.size;
            return true;
        }
        return false;
    }

    /// @dev check if _address is in the list
    /// @param _address - address to check
    /// @return true if _address is in the list, false otherwise
    function exists(LinkedListStorage storage list, address _address)
        external
        view
        returns (bool)
    {
        //items in the list have prev which points to non ZERO_ADDRESS
        return list.prev[_address] != ZERO_ADDRESS;
    }

    /// @dev starts iterating through the list. The iterator will be saved inside contract
    /// @return address of first item or ZERO_ADDRESS if the list is empty
    function iterate_first(LinkedListStorage storage list)
        public
        returns (address)
    {
        list.iterator = list.next[HEAD];
        return list.iterator;
    }

    /// @dev gets the next item which is pointed by the iterator
    /// @return next item or ZERO_ADDRESS if the iterator is pointed to the last item
    function iterate_next(LinkedListStorage storage list)
        public
        returns (address)
    {
        //if the iterator is ZERO_ADDRES, it means that the list is empty or the iteration process is finished
        if (list.iterator == ZERO_ADDRESS) {
            return ZERO_ADDRESS;
        }
        list.iterator = list.next[list.iterator];
        return list.iterator;
    }

    /// @dev remove min(size, iterationCountLimit) of items
    /// @param _iterator - address, which is a start point of removing
    /// @return address of the item, which can be passed to _clear to continue removing items. If all items removed,
    /// ZERO_ADDRESS will be returned
    function _clear(LinkedListStorage storage list, address _iterator)
        public
        returns (address)
    {
        uint256 i = 0;
        while ((_iterator != ZERO_ADDRESS) && (i < list.iterationCountLimit)) {
            address nextIterator = list.next[_iterator];
            _remove(list, _iterator);
            _iterator = nextIterator;
            unchecked {
                i = i + 1;
            }
        }
        return _iterator;
    }

    /// @dev starts removing all items
    /// @return next item to pass into clear_next, if list's size > iterationCountLimit, ZERO_ADDRESS otherwise
    function clear_init(LinkedListStorage storage list)
        external
        returns (address)
    {
        return (_clear(list, list.next[HEAD]));
    }

    /// @dev continues to remove all items
    /// @param _startFrom - address which is a start point of removing
    /// @return next item to pass into clear_next, if current list's size > iterationCountLimit, ZERO_ADDRESS otherwise
    function clear_next(LinkedListStorage storage list, address _startFrom)
        external
        returns (address)
    {
        return (_clear(list, _startFrom));
    }

    /// @dev get the first item of the list
    /// @return first item of the list or ZERO_ADDRESS if the list is empty
    function getFirst(LinkedListStorage storage list)
        external
        view
        returns (address)
    {
        return (list.next[HEAD]);
    }

    /// @dev gets the next item following _prev
    /// @param _prev - current item
    /// @return the next item following _prev
    function getNext(LinkedListStorage storage list, address _prev)
        external
        view
        returns (address)
    {
        return (list.next[_prev]);
    }
}