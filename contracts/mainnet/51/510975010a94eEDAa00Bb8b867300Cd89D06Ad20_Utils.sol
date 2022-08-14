// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

library Utils {

    function pseudorand(bytes calldata extra) external view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, extra)));
    }
 /**
     * @dev In the loop if ptr is less than 32 bites and tier does not equal 0,
     * adds a value to ptr.
     * Allocated memory is fixed in this function
     */
    function bytes32ToString(bytes32 tier) public pure returns (string memory) {
        uint8 ptr;
        while (ptr < 32 && tier[ptr] != 0) {
            ++ptr;
        }
        bytes memory tmp = new bytes(ptr);
        for (uint8 i; i != ptr; ++i) {
            tmp[i] = tier[i];
        }
        return string(tmp);
    }
}