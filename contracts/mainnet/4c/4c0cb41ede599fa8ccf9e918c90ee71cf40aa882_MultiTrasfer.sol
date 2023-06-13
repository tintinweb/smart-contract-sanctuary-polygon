/**
 *Submitted for verification at polygonscan.com on 2023-06-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

library SafeTransferLib {
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        bool success;

        assembly {
            let freeMemoryPointer := mload(0x40)

            mstore(
                freeMemoryPointer,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), from)
            mstore(add(freeMemoryPointer, 36), to)
            mstore(add(freeMemoryPointer, 68), amount)

            success := and(
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "STF");
    }
}

contract MultiTrasfer {
    function transfer(
        address recipient_,
        address tokenCollection_,
        uint256 endIndex_
    ) external payable {
        address sender = msg.sender;
        for (uint256 i = 1; i <= endIndex_; ) {
            SafeTransferLib.safeTransferFrom(tokenCollection_, sender, recipient_, i);
            unchecked {
                ++i;
            }
        }
    }
}