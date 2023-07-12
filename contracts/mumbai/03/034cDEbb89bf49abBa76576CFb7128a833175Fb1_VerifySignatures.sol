// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

contract VerifySignatures {
    uint256 internal constant Q =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    event CashingOut(address player, uint8 tableNumber, uint8 roundNumber);

    event BroadcastSignature(
        uint8 gameId,
        address player,
        bytes sig,
        bytes challenge
    );

    event RoundProofVerified(bytes sig, bool verified);

    event MerkleProofVerified(bytes32[] proof, bool verified);

    function VerifySchnorr(
        bytes32 hash,
        bytes memory sig
    ) public returns (address) {
        (bytes32 px, bytes32 e, bytes32 s, uint8 parity) = abi.decode(
            sig,
            (bytes32, bytes32, bytes32, uint8)
        );
        bytes32 sp = bytes32(Q - mulmod(uint256(s), uint256(px), Q));
        bytes32 ep = bytes32(Q - mulmod(uint256(e), uint256(px), Q));

        require(sp != 0);
        address R = ecrecover(sp, parity, px, ep);
        require(R != address(0), "ecrecover failed");
        emit RoundProofVerified(sig, true);
        return
            e == keccak256(abi.encodePacked(R, uint8(parity), px, hash))
                ? address(uint160(uint256(px)))
                : address(0);
    }

    function VerifyMerkleProof(
        bytes32 root,
        bytes32 leaf,
        bytes32[] memory proof
    ) public returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash < proofElement) {
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }
        emit MerkleProofVerified(proof, true);
        return computedHash == root;
    }

    function cashOut(address player, uint8 table, uint8 round) public {
        emit CashingOut(player, table, round);
    }

    function BroadcastMySignature(
        address player,
        uint8 gameId,
        bytes calldata signature,
        bytes calldata challenge
    ) public {
        emit BroadcastSignature(gameId, player, signature, challenge);
    }
}