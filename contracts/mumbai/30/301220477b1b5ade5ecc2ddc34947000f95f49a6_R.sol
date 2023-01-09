// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract R {
    bytes32 private _x;
    bytes32 private _y;

    constructor() {
        bytes32 x;
        bytes32 y;
        assembly {
            mstore(0x00, caller())
            mstore(0x20, timestamp())
            mstore(0x40, number())
            mstore(0x60, origin())
            let s := keccak256(0x00, 0x80)
            mstore(0x20, 0x01)
            mstore(0x40, 0x02)
            mstore(0x60, s)
            if iszero(staticcall(gas(), 0x07, 0x20, 0x60, 0x00, 0x40)) {
                revert(0x00, 0x00)
            }
            x := mload(0x00)
            y := mload(0x20)
        }
        _x = x;
        _y = y;
    }

    function r() external view returns (uint8 res) {
        bytes32[3] memory input;
        input[0] = _x;
        input[1] = _y;
        bytes32 s;
        assembly {
            mstore(0x00, caller())
            mstore(0x20, timestamp())
            mstore(0x40, number())
            mstore(0x60, origin())
            s := keccak256(0x00, 0x80)
        }
        input[2] = s;
        assembly {
            if iszero(staticcall(gas(), 0x07, input, 0x60, 0x00, 0x40)) {
                revert(0x00, 0x00)
            }
            res := mod(xor(mload(0x00), mload(0x20)), 100)
        }
    }
}