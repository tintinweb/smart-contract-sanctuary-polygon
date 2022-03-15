// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./Collection.sol";

library SafeCollection {
    function safeAdd(
        mapping(address => Collection) storage collections,
        address who,
        uint256 itemId
    ) public {
        Collection collection = collections[who];
        if (address(collection) == address(0)) {
            collections[who] = collection = new Collection();
        }
        collection.append(itemId);
    }

    function safeRemove(Collection collection, uint256 itemId) public {
        if (address(collection) != address(0)) {
            collection.remove(itemId);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

contract Collection {
    struct Item {
        uint256 prev;
        uint256 next;
        uint256 itemId;
    }

    uint256 public size;
    uint256 private _head;
    uint256 private _tail;

    address private immutable _owner;

    mapping(uint256 => Item) private _items;

    constructor() {
        _owner = msg.sender;
    }

    function append(uint256 itemId) public onlyOwner {
        Item memory item;
        item.itemId = itemId;
        if (size++ == 0) {
            _head = _tail = itemId;
        } else {
            item.prev = _tail;
            _items[_tail].next = itemId;
            _tail = itemId;
        }
        _items[itemId] = item;
    }

    function remove(uint256 itemId) public onlyOwner {
        uint256 prev = _items[itemId].prev;
        uint256 next = _items[itemId].next;
        if (--size == 0) {
            _head = _tail = 0;
        } else {
            if (_head == itemId) {
                _head = _items[itemId].next;
            }
            if (_tail == itemId) {
                _tail = _items[itemId].prev;
            }
            _items[prev].next = next;
            _items[next].prev = prev;
        }
        delete _items[itemId];
    }

    function get(uint256 id) public view returns (Item memory) {
        return _items[id];
    }

    function getNext(Item memory current, bool ascending)
        public
        view
        returns (Item memory)
    {
        return get(ascending ? current.next : current.prev);
    }

    function head() public view returns (Item memory) {
        return _items[_head];
    }

    function tail() public view returns (Item memory) {
        return _items[_tail];
    }

    function first(bool ascending) public view returns (Item memory) {
        return ascending ? head() : tail();
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "caller is not the owner");
        _;
    }
}