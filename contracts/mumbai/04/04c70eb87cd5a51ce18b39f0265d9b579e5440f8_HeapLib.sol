/**
 *Submitted for verification at polygonscan.com on 2023-03-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

library HeapLib {
    struct Heap {
        uint256[] data;
        uint256 size;
    }

    function pop(Heap storage heap) external returns (uint256 _data) {
        require(heap.size > 0, "Heap is empty.");

        _data = heap.data[0];
        heap.size--;
        heap.data[0] = heap.data[heap.size];
        heap.data.pop();

        if (heap.size == 0) {
            return _data;
        }
        
        uint256 j;
        uint256 _pos = 0;
        while ((j = ((_pos + 1) << 1)) <= heap.size) {
            uint256 mci = heap.size > j ? heap.data[j] < heap.data[j-1] ? j : j-1 : j-1;

            if (heap.data[mci] >= heap.data[_pos]) {
                break;
            }

            (heap.data[_pos], heap.data[mci]) = (heap.data[mci], heap.data[_pos]);
            _pos = mci;
        }
    }

    function push(Heap storage heap, uint256 value) external {
        heap.data.push(value);
        uint256 _pos = heap.size;
        heap.size++;
        uint256 _pi;

        while (_pos > 0 && heap.data[_pos] < heap.data[_pi = ((_pos - 1)>>1)]) {
            (heap.data[_pos], heap.data[_pi]) = (heap.data[_pi], value);
            _pos = _pi;
        }
    }
}