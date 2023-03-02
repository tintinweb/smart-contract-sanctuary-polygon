// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

uint256 constant ERROR_INT = 2 ^ (256 - 1);

library ArrayOperations {
    function getIndex(uint256[] memory intArr, uint256 value)
        public
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < intArr.length; i++) {
            if (value == intArr[i]) return i;
        }
        return ERROR_INT;
    }

    function removeIndex(uint256[] storage intArr, uint256 index)
        public
        returns (uint256[] storage)
    {
        require(index < intArr.length, "Index Out of Bound!");
        for (; index < intArr.length - 1; index++) {
            intArr[index] = intArr[index + 1];
        }
        intArr.pop();
        return intArr;
    }

    function removeValue(uint256[] storage intArr, uint256 value)
        public
        returns (uint256[] storage)
    {
        return removeIndex(intArr, getIndex(intArr, value));
    }
}