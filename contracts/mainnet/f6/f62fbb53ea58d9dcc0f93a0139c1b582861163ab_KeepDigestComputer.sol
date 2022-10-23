/**
 *Submitted for verification at polygonscan.com on 2022-10-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

enum Operation {
    call,
    delegatecall,
    create,
    create2
}

/// @notice Keep execution digest computer.
contract KeepDigestComputer {
    function computeKeepDigest(
        address keep,
        Operation op,
        address to,
        uint256 value,
        bytes calldata data,
        uint120 nonce
    ) public view virtual returns (bytes32) {
        return 
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    computeKeepDomainSeparator(keep),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Execute(uint8 op,address to,uint256 value,bytes data,uint120 nonce)"
                            ),
                            op,
                            to,
                            value,
                            keccak256(data),
                            nonce
                        )
                    )
                )
            );
    }

    function computeKeepDomainSeparator(address keep) public view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    // `keccak256(
                    //     "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    // )`
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                    // `keccak256(bytes("Keep"))`
                    0x21d66785fec14e4da3d76f3866cf99a28f4da49ec8782c3cab7cf79c1b6fa66b,
                    // `keccak256("1")`
                    0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6,
                    block.chainid,
                    keep
                )
            );
    }
}