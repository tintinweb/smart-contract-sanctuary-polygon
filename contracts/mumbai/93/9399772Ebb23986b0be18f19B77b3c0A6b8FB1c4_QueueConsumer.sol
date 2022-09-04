// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./QueueMock.sol";

contract QueueConsumer is Bytes32QueueMock {
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Queue.sol";

contract Bytes32QueueMock {
    using Queue for Queue.Bytes32Queue;

    Queue.Bytes32Queue private _queue;

    // to be consumed in tests since non-constant return values not accessible off-chain (refer to https://ethereum.stackexchange.com/questions/88119/i-see-no-way-to-obtain-the-return-value-of-a-non-view-function-ethers-js)
    event OperationResult(bytes32 data);

    constructor() {
        _queue.initialize();
    }

    function length() external view returns (uint256) {
        return _queue.length();
    }

    function isEmpty() external view returns (bool) {
        return _queue.isEmpty();
    }

    function enqueue(bytes32 data) external {
        _queue.enqueue(data);
    }

    function dequeue() external returns (bytes32 data) {
        data = _queue.dequeue();
        emit OperationResult(data);
    }

    function peek() external view returns (bytes32 data) {
        return _queue.peek();
    }

    function peekLast() external view returns (bytes32 data) {
        return _queue.peekLast();
    }
}

contract AddressQueueMock {
    using Queue for Queue.AddressQueue;

    Queue.AddressQueue private _queue;

    event OperationResult(address data);

    constructor() {
        _queue.initialize();
    }

    function length() external view returns (uint256) {
        return _queue.length();
    }

    function isEmpty() external view returns (bool) {
        return _queue.isEmpty();
    }

    function enqueue(address data) external {
        _queue.enqueue(data);
    }

    function dequeue() external returns (address data) {
        data = _queue.dequeue();
        emit OperationResult(data);
    }

    function peek() external view returns (address data) {
        return _queue.peek();
    }

    function peekLast() external view returns (address data) {
        return _queue.peekLast();
    }
}

contract Uint256QueueMock {
    using Queue for Queue.Uint256Queue;

    Queue.Uint256Queue private _queue;

    event OperationResult(uint256 data);

    constructor() {
        _queue.initialize();
    }

    function length() external view returns (uint256) {
        return _queue.length();
    }

    function isEmpty() external view returns (bool) {
        return _queue.isEmpty();
    }

    function enqueue(uint256 data) external {
        _queue.enqueue(data);
    }

    function dequeue() external returns (uint256 data) {
        data = _queue.dequeue();
        emit OperationResult(data);
    }

    function peek() external view returns (uint256 data) {
        return _queue.peek();
    }

    function peekLast() external view returns (uint256 data) {
        return _queue.peekLast();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Queue
 * @author Erick Dagenais (https://github.com/edag94)
 * @dev Implementation of the queue data structure, providing a library with struct definition for queue storage in consuming contracts.
 */
library Queue {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Queue type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.
    // Based off the pattern used in https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol[EnumerableSet.sol] by OpenZeppelin

    struct QueueStorage {
        mapping (uint256 => bytes32) _data;
        uint256 _first;
        uint256 _last;
    }

    modifier isNotEmpty(QueueStorage storage queue) {
        require(!_isEmpty(queue), "Queue is empty.");
        _;
    }

    /**
     * @dev Sets the queue's initial state, with a queue size of 0.
     * @param queue QueueStorage struct from contract.
     */
    function _initialize(QueueStorage storage queue) private {
        queue._first = 1;
        queue._last = 0;
    }

    /**
     * @dev Gets the number of elements in the queue. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function _length(QueueStorage storage queue) private view returns (uint256) {
        if (queue._last < queue._first) {
            return 0;
        }
        return queue._last - queue._first + 1;
    }

    /**
     * @dev Returns if queue is empty. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function _isEmpty(QueueStorage storage queue) private view returns (bool) {
        return _length(queue) == 0;
    }

    /**
     * @dev Adds an element to the back of the queue. O(1)
     * @param queue QueueStorage struct from contract.
     * @param data The added element's data.
     */
    function _enqueue(QueueStorage storage queue, bytes32 data) private {
        queue._data[++queue._last] = data;
    }

    /**
     * @dev Removes an element from the front of the queue and returns it. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function _dequeue(QueueStorage storage queue) private isNotEmpty(queue) returns (bytes32 data) {
        data = queue._data[queue._first];
        delete queue._data[queue._first++];
    }

    /**
     * @dev Returns the data from the front of the queue, without removing it. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function _peek(QueueStorage storage queue) private view isNotEmpty(queue) returns (bytes32 data) {
        return queue._data[queue._first];
    }

    /**
     * @dev Returns the data from the back of the queue. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function _peekLast(QueueStorage storage queue) private view isNotEmpty(queue) returns (bytes32 data) {
        return queue._data[queue._last];
    }

    // Bytes32Queue

    struct Bytes32Queue {
        QueueStorage _inner;
    }

    /**
     * @dev Sets the queue's initial state, with a queue size of 0.
     * @param queue Bytes32Queue struct from contract.
     */
    function initialize(Bytes32Queue storage queue) internal {
        _initialize(queue._inner);
    }

    /**
     * @dev Gets the number of elements in the queue. O(1)
     * @param queue Bytes32Queue struct from contract.
     */
    function length(Bytes32Queue storage queue) internal view returns (uint256) {
        return _length(queue._inner);
    }

    /**
     * @dev Returns if queue is empty. O(1)
     * @param queue Bytes32Queue struct from contract.
     */
    function isEmpty(Bytes32Queue storage queue) internal view returns (bool) {
        return _isEmpty(queue._inner);
    }

    /**
     * @dev Adds an element to the back of the queue. O(1)
     * @param queue Bytes32Queue struct from contract.
     * @param data The added element's data.
     */
    function enqueue(Bytes32Queue storage queue, bytes32 data) internal {
        _enqueue(queue._inner, data);
    }

    /**
     * @dev Removes an element from the front of the queue and returns it. O(1)
     * @param queue Bytes32Queue struct from contract.
     */
    function dequeue(Bytes32Queue storage queue) internal returns (bytes32 data) {
        return _dequeue(queue._inner);
    }

    /**
     * @dev Returns the data from the front of the queue, without removing it. O(1)
     * @param queue Bytes32Queue struct from contract.
     */
    function peek(Bytes32Queue storage queue) internal view returns (bytes32 data) {
        return _peek(queue._inner);
    }

    /**
     * @dev Returns the data from the back of the queue. O(1)
     * @param queue Bytes32Queue struct from contract.
     */
    function peekLast(Bytes32Queue storage queue) internal view returns (bytes32 data) {
        return _peekLast(queue._inner);
    }

    // AddressQueue

    struct AddressQueue {
        QueueStorage _inner;
    }

    /**
     * @dev Sets the queue's initial state, with a queue size of 0.
     * @param queue AddressQueue struct from contract.
     */
    function initialize(AddressQueue storage queue) internal {
        _initialize(queue._inner);
    }

    /**
     * @dev Gets the number of elements in the queue. O(1)
     * @param queue AddressQueue struct from contract.
     */
    function length(AddressQueue storage queue) internal view returns (uint256) {
        return _length(queue._inner);
    }

    /**
     * @dev Returns if queue is empty. O(1)
     * @param queue AddressQueue struct from contract.
     */
    function isEmpty(AddressQueue storage queue) internal view returns (bool) {
        return _isEmpty(queue._inner);
    }

    /**
     * @dev Adds an element to the back of the queue. O(1)
     * @param queue AddressQueue struct from contract.
     * @param data The added element's data.
     */
    function enqueue(AddressQueue storage queue, address data) internal {
        _enqueue(queue._inner, bytes32(uint256(uint160(data))));
    }

    /**
     * @dev Removes an element from the front of the queue and returns it. O(1)
     * @param queue AddressQueue struct from contract.
     */
    function dequeue(AddressQueue storage queue) internal returns (address data) {
        return address(uint160(uint256(_dequeue(queue._inner))));
    }

    /**
     * @dev Returns the data from the front of the queue, without removing it. O(1)
     * @param queue AddressQueue struct from contract.
     */
    function peek(AddressQueue storage queue) internal view returns (address data) {
        return address(uint160(uint256(_peek(queue._inner))));
    }

    /**
     * @dev Returns the data from the back of the queue. O(1)
     * @param queue AddressQueue struct from contract.
     */
    function peekLast(AddressQueue storage queue) internal view returns (address data) {
        return address(uint160(uint256(_peekLast(queue._inner))));
    }

    // Uint256Queue

    struct Uint256Queue {
        QueueStorage _inner;
    }

    /**
     * @dev Sets the queue's initial state, with a queue size of 0.
     * @param queue Uint256Queue struct from contract.
     */
    function initialize(Uint256Queue storage queue) internal {
        _initialize(queue._inner);
    }

    /**
     * @dev Gets the number of elements in the queue. O(1)
     * @param queue Uint256Queue struct from contract.
     */
    function length(Uint256Queue storage queue) internal view returns (uint256) {
        return _length(queue._inner);
    }

    /**
     * @dev Returns if queue is empty. O(1)
     * @param queue Uint256Queue struct from contract.
     */
    function isEmpty(Uint256Queue storage queue) internal view returns (bool) {
        return _isEmpty(queue._inner);
    }

    /**
     * @dev Adds an element to the back of the queue. O(1)
     * @param queue Uint256Queue struct from contract.
     * @param data The added element's data.
     */
    function enqueue(Uint256Queue storage queue, uint256 data) internal {
        _enqueue(queue._inner, bytes32(data));
    }

    /**
     * @dev Removes an element from the front of the queue and returns it. O(1)
     * @param queue Uint256Queue struct from contract.
     */
    function dequeue(Uint256Queue storage queue) internal returns (uint256 data) {
        return uint256(_dequeue(queue._inner));
    }

    /**
     * @dev Returns the data from the front of the queue, without removing it. O(1)
     * @param queue Uint256Queue struct from contract.
     */
    function peek(Uint256Queue storage queue) internal view returns (uint256 data) {
        return uint256(_peek(queue._inner));
    }

    /**
     * @dev Returns the data from the back of the queue. O(1)
     * @param queue Uint256Queue struct from contract.
     */
    function peekLast(Uint256Queue storage queue) internal view returns (uint256 data) {
        return uint256(_peekLast(queue._inner));
    }
}