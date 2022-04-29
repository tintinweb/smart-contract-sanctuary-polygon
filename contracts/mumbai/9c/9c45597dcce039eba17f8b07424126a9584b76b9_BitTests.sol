/**
 *Submitted for verification at polygonscan.com on 2022-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library BitTools {

    struct BitMap {
        uint256 _data;
    }

    function asUint(BitMap storage bitmap) internal view returns(uint256) {
        return bitmap._data;
    }

    function get(BitMap storage bitmap, uint8 bit) internal view returns(bool) {
        uint256 mask = 1 << bit;
        return (bitmap._data & mask != 0);
    }

    function setTo(BitMap storage bitmap, uint8 bit, bool value) internal {
        if (value) {
            set(bitmap, bit);
        } else {
            unset(bitmap, bit);
        }
    }

    function set(BitMap storage bitmap, uint8 bit) internal {
        uint256 mask = 1 << bit;
        bitmap._data |= mask;
    }


    function unset(BitMap storage bitmap, uint8 bit) internal {
        uint256 mask = 1 << bit;
        bitmap._data &= ~mask;
    }
}

contract BitTests {
    using BitTools for BitTools.BitMap;

    BitTools.BitMap private bitmap;

    function set(uint8 bit) external {
        bitmap.set(bit);
    }

    function unset(uint8 bit) external {
        bitmap.unset(bit);
    }

    function get(uint8 bit) external view returns(bool) {
        return bitmap.get(bit);
    }

    function getBitmapAsUint() external view returns (uint256) {
        return bitmap.asUint();
    }
}