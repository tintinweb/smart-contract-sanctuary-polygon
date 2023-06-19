// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./constants.sol";

// For a full-fledged DLL see "@hq20/contracts/contracts/lists/DoubleLinkedList.sol"
// todo https://medium.com/%40hayeah/diving-into-the-ethereum-vm-the-hidden-costs-of-arrays-28e119f04a9b, not much impact though
// todo convert to library after https://github.com/ethereum/solidity/issues/13776
contract Queue {
    uint256[COUNT + 1] private prev;
    uint256[COUNT + 1] private next;

    constructor() {
        prev[COUNT] = COUNT;
        next[COUNT] = COUNT;
    }

    function dump() external view returns (uint256[COUNT] memory) {
        // generated with ChatGPT, don't use...
        // https://chat.openai.com/share/d1cb9bcd-2f54-40f1-943d-7fc2736caffd

        uint256[COUNT] memory result;
        uint256 index = 0;
        uint256 i = COUNT;
        do {
            i = next[COUNT];
            result[index++] = i;
        } while (i != COUNT);
        
        return result;
    }

    function empty() external view returns (bool) {
        return head() == COUNT;
    }

    function head() public view returns (uint256) {
        return next[COUNT];
    }

    function tail() internal view returns (uint256) {
        return prev[COUNT];
    }

    function unlink(uint256 i) public {
        prev[next[i]] = prev[i];
        next[prev[i]] = next[i];
    }

    function unshift() public returns (uint256) {
        uint256 _head = head();
        unlink(_head);
        return _head;
    }

    function insertBefore(uint256 _next, uint256 new_i) internal {
        uint256 _prev = prev[_next];
        next[new_i] = _next;
        prev[new_i] = _prev;
        next[_prev] = new_i;
        prev[_next] = new_i;
    }

    function push(uint256 i) public {
        insertBefore(COUNT, i);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

uint256 constant COUNT = 1000;