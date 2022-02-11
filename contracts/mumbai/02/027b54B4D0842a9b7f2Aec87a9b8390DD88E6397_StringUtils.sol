// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library StringUtils {

    function compareStrings(string memory a, string memory b) external pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // Substring indexing is done from left -> right
    // Example. str = 0003050040002061101
    // str[0]  = 0
    // str[5]  = 5
    // str[18] = 1
    function substring(string memory str, uint inclStartIndex, uint inclEndIndex) external pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(inclEndIndex-inclStartIndex+1);
        for(uint i = inclStartIndex; i <= inclEndIndex; i++) {
            result[i-inclStartIndex] = strBytes[i];
        }
        return string(result);
    }

    function append(string calldata a, string calldata b) external pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function strToUint(string memory _str) external pure returns(uint256 res, bool err) {
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if ((uint8(bytes(_str)[i]) - 48) < 0 || (uint8(bytes(_str)[i]) - 48) > 9) {
                return (0, false);
            }
            res += (uint8(bytes(_str)[i]) - 48) * 10**(bytes(_str).length - i - 1);
        }
        return (res, true);
    }

}