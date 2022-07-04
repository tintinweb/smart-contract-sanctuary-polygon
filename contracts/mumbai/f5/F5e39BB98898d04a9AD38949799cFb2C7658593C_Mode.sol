//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
library Mode {
    function findMostOccurringString(string[] memory arr)
        public
        pure
        returns (string memory)
    {
        string memory mode = "";

        uint256 maxCount = 0;

        for (uint256 i = 0; i < arr.length; i++) {
            uint256 count = getCount(arr, arr[i]);
            if (count > maxCount) {
                maxCount = count;
                mode = arr[i];
            }
        }

        return mode;
    }

    function getCount(string[] memory arr, string memory element)
        public
        pure
        returns (uint256 count)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (compareStrings(arr[i], element)) {
                count++;
            }
        }
    }

    function compareStrings(string memory a, string memory b)
        private
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }
}