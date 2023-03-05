/**
 *Submitted for verification at polygonscan.com on 2023-03-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

library QueueLib {
    struct Queue {
        uint256[] data;
        uint256 front;
        uint256 back;
        uint256 size;
    }

    function enque(Queue storage queue, uint256 data) public {
        queue.data.push(data);
        queue.size++;
        queue.back++;
    }

    function deque(Queue storage queue) public returns (uint256) {
        require(queue.size > 0, "queue is empty");
        queue.size--;
        queue.front++;
        uint256 value = queue.data[queue.front-1];
        delete queue.data[queue.front-1];
        return value;
    }

    function frontValue(Queue storage queue) public view returns (uint256) {
        if (queue.size == 0) {
            return 0;
        }
        return queue.data[queue.front];
    }

    function backValue(Queue storage queue) public view returns (uint256) {
        if (queue.size == 0) {
            return 0;
        }
        return queue.data[queue.back];
    }
}