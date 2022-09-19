//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ItemHeaderLib {
    function unpackHeader(uint256 itemHeader) public pure returns (uint8, uint64, uint16) {
        return (
            uint8((itemHeader >> (8 * 31)) & 0xff),
            uint64((itemHeader >> (8 * 23)) & 0xffffffffffffffff),
            uint16((itemHeader >> (8 * 21)) & 0xffff)
        );
    }

    function unpackVersion(uint256 itemHeader) public pure returns (uint8) {
        return uint8((itemHeader >> (8 * 31)) & 0xff);
    }

    function unpackTimestamp(uint256 itemHeader) public pure returns (uint64) {
        return uint64((itemHeader >> (8 * 23)) & 0xffffffffffffffff);
    }


    function unpackAction(uint256 itemHeader) public pure returns (uint16) {
        return uint16((itemHeader >> (8 * 21)) & 0xffff);
    }

    function packHeader(uint8 version, uint64 timestamp, uint16 action) public pure returns (uint256) {
        return (uint256(version) << (8 * 31)) + (uint256(timestamp) << (8 * 23)) + (uint256(action) << (8 * 21));
    }
}