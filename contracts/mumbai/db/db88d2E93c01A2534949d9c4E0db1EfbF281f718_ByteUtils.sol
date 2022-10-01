// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

library ByteUtils {
  function bytesToBytes32Array(bytes memory b, uint256 offset) public pure returns (bytes32[] memory arr) {
    arr = new bytes32[]((b.length - offset) / 32);

    for (uint256 i = offset; i < b.length; i++) {
      arr[(i - offset) / 32] |= bytes32(b[i] & 0xFF) >> (((i - offset) % 32) * 8);
    }
  }

  function bytesToAddress(bytes memory b, uint256 offset) public pure returns (address account) {
    bytes32 raw;

    for (uint256 i = 0; i < 20; i++) {
      raw |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
    }

    account = address(uint160(uint256(raw >> 96)));
  }

  /**
   * @notice
   * 
   * @param _b Byte array to process.
   * @param _offset Offset to start at, in bytes.
   * @param _length Length to parse, in bytes.
   */
  function bytesToUint(bytes memory _b, uint256 _offset, uint8 _length) public pure returns (uint256 number) {
    for (uint256 i = 0; i < _length; i++) {
      number = number + uint256(uint8(_b[_offset + i])) * (2**(8 * (_length - (i + 1))));
    }
  }

  function bytesToBool(bytes memory _b, uint256 _offset, uint8 _index) public pure returns (bool flag) {
    flag = (uint8(_b[_offset]) >> _index & 1) == 1;
  }
}