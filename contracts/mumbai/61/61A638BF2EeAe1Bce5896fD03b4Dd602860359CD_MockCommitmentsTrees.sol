// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

contract MockCommitmentsTrees {
    uint256 public leftLeafId = 0;
    uint256 private constant iTRIAD_SIZE = 4;

    address private zkp = 0x3F73371cFA58F338C479928AC7B4327478Cb859f;
    address private nft = 0x45c7650cbE485d3c85B739799A4D2eEF9FB46d60;

    event RewardGenerated(
        address indexed staker,
        uint256 firstLeafId,
        uint256 zkp,
        uint256 nft
    );

    event NewCommitments(
        uint256 indexed leftLeafId,
        uint256 creationTime,
        bytes32[3] commitments,
        bytes utxoData
    );

    function generate(
        uint256 loopCount,
        address staker,
        bytes32[3] memory commitments,
        bytes memory utxoData
    ) external {
        for (uint256 i = 0; i < loopCount; i++) {
            emit RewardGenerated(staker, leftLeafId, 100e18, 1);
            emit NewCommitments(
                leftLeafId,
                block.timestamp,
                commitments,
                utxoData
            );

            leftLeafId += iTRIAD_SIZE;
        }
    }

    function resetLeafIf() external {
        leftLeafId = 0;
    }
}