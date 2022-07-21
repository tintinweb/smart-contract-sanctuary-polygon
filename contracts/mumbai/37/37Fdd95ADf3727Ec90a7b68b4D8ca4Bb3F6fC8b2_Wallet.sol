/**
 *Submitted for verification at polygonscan.com on 2022-07-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Wallet {
    fallback () external payable {
      assembly {
                let _dataOffset := calldataload(0x64)
                let _dataLength := calldataload(0x144)
                // Invalid if:
                //   `_dataOffset != 0x140 || _dataLength > 0xffff`
                if or(
                    // _dataLength should always be 0x140 bytes after the first parameter.
                    // Make sure this is the case.
                    iszero(eq(0x140, _dataOffset)),

                    // Limit data length to a reasonable size so that
                    // we don't have to worry about overflow later.
                    gt(_dataLength, 0xffff)
                ) {
                    invalid()
                }

                // Set up EIP191 prefix.
                mstore8(0x80, 0x19)
                mstore8(0x81, 0x00)
                mstore(0x82, address())

                // Copy method signature + _identifier + _destination + _value to memory.
                calldatacopy(0xa2, 0, 0x64)

                // Copy _data (without offset or length) after that.
                calldatacopy(0x106, 0x164, _dataLength)

                // Hash all user data except the signatures.
                //
                // The second argument cannot overflow due to an
                // earlier check limiting the maximum value of the
                // length variable.
                // log0(0x80, add(0x86, _dataLength))
                let hash := keccak256(0x80, add(0x86, _dataLength))
                // log1(hash, 0x80, add(0x86, _dataLength))

                // First signature.
                let _sigV := calldataload(0x84)
                let _sigR := calldataload(0xa4)
                let _sigS := calldataload(0xc4)

                // Recover the first signer. Calling this function
                // is going to overwrite the first 4 memory slots,
                // but we haven't stored anything there.
                let signer := __ecrecover(hash, _sigV, _sigR, _sigS)

                stop()

                function __ecrecover(h, v, r, s) -> a {
                v := add(v, 27)

                mstore(0, h)
                mstore(0x20, v)
                mstore(0x40, r)
                mstore(0x60, s)

                a := mload(0)
            }
      }
    }
}