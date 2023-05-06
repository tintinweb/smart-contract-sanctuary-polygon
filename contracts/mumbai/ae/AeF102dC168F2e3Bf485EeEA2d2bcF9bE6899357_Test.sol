// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Test {
    function random() private view returns (uint64) {
        return uint64(uint256(keccak256(abi.encodePacked(msg.sender))));
    }

    struct Flower {
        uint32 mutationMatrixSizeWord;
        mapping(uint => bytes32) mutationMatrix;
    }

    // struct FlowerArray {
    //     uint8 prout;
    //     uint32 mutationMatrixSizeWord;
    //     bytes32[100] mutationMatrix;
    // }

    mapping(uint => Flower) flowers;
    // mapping(uint => FlowerArray) flowers2;

    uint256 constant nWords = 1;

    constructor() {
        unchecked {
            for (uint i = 0; i < nWords; i++) {
                flowers[0].mutationMatrix[i] = bytes32(
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                );
                // flowers2[0].mutationMatrix[i] = bytes32(
                //     0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                // );
                // flowers2[0].mutationMatrix.push(
                //     bytes32(
                //         0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                //     )
                // );
            }
            //flowers2[0].mutationMatrixSizeWord = 100;
            flowers[0].mutationMatrixSizeWord = uint32(nWords);
        }
    }

    function unitairyCustomMutationBA(
        uint nMutations,
        uint8 pixelIndex
    ) public {
        unchecked {
            uint64 nonce = random();

            uint mutationMatrixSizeWords = flowers[0].mutationMatrixSizeWord;

            for (
                uint nMutationsLeft = nMutations;
                nMutationsLeft > 0;
                --nMutationsLeft
            ) {
                // We keep the 16 MSb from nonce because it has better randomness
                uint iWord = (nonce >> 48) % mutationMatrixSizeWords;

                // Applying the mutation color via a mask
                flowers[0].mutationMatrix[iWord] &= bytes32(
                    ~(0x1 << (pixelIndex + nMutationsLeft))
                );

                // Generating the next nonce using MMIX LGC parameters by Donald Knuth (used in RISC architecture)
                nonce = (nonce * 6364136223846793005 + 1442695040888963407); // Wrap-around on 64 bits
            }
        }
    }

    // function mutationBAstruct(uint nMutations, uint iFlower) public {
    //     unchecked {
    //         uint64 nonce = random();
    //         uint mutationMatrixSizeWord = flowers2[iFlower]
    //             .mutationMatrixSizeWord;

    //         bytes32[100] memory lol = flowers2[iFlower].mutationMatrix;

    //         for (
    //             uint nMutationsLeft = nMutations;
    //             nMutationsLeft > 0;
    //             --nMutationsLeft
    //         ) {
    //             // We keep the 16 MSb from nonce because it has better randomness
    //             uint iWord = (nonce >> 48) % mutationMatrixSizeWord;
    //             uint pixelIndex = (nonce >> 32) & 0xFF;

    //             bytes32 nullMask = bytes32(~(0x1 << pixelIndex));

    //             // Applying the mutation color via a mask
    //             lol[iWord] &= nullMask;

    //             // Generating the next nonce using MMIX LGC parameters by Donald Knuth (used in RISC architecture)
    //             nonce = (nonce * 6364136223846793005 + 1442695040888963407); // Wrap-around on 64 bits
    //         }
    //         flowers2[iFlower].mutationMatrix = lol;
    //     }
    // }

    // function mutationBAstructTight(uint32 nMutations, uint iFlower) public {
    //     unchecked {
    //         uint64 nonce = random();
    //         uint32 mutationMatrixSizeWord = flowers[iFlower]
    //             .mutationMatrixSizeWord;

    //         for (
    //             uint32 nMutationsLeft = nMutations;
    //             nMutationsLeft > 0;
    //             --nMutationsLeft
    //         ) {
    //             // We keep the 16 MSb from nonce because it has better randomness
    //             uint16 iWord = uint16((nonce >> 48) % mutationMatrixSizeWord);
    //             uint8 pixelIndex = uint8(nonce >> 32);

    //             bytes32 nullMask = bytes32(~(0x1 << pixelIndex));

    //             // Applying the mutation color via a mask
    //             flowers[iFlower].mutationMatrix[iWord] &= nullMask;

    //             // Generating the next nonce using MMIX LGC parameters by Donald Knuth (used in RISC architecture)
    //             nonce = (nonce * 6364136223846793005 + 1442695040888963407); // Wrap-around on 64 bits
    //         }
    //     }
    // }

    // BEST ONE
    // function mutationBA(uint nMutations) public {
    //     unchecked {
    //         uint64 nonce = random();
    //         uint mutationMatrixSizeWords = 100;

    //         for (
    //             uint nMutationsLeft = nMutations;
    //             nMutationsLeft > 0;
    //             --nMutationsLeft
    //         ) {
    //             // We keep the 16 MSb from nonce because it has better randomness
    //             uint iWord = (nonce >> 48) % mutationMatrixSizeWords;
    //             uint pixelIndex = (nonce >> 32) & 0xFF;

    //             // Applying the mutation color via a mask
    //             mutationMatrix2[iWord] &= bytes32(~(0x1 << pixelIndex));

    //             // Generating the next nonce using MMIX LGC parameters by Donald Knuth (used in RISC architecture)
    //             nonce = (nonce * 6364136223846793005 + 1442695040888963407); // Wrap-around on 64 bits
    //         }
    //     }
    // }

    // function mutationA(uint32 nMutations) public {
    //     unchecked {
    //         uint64 nonce = random();
    //         uint32 mutationMatrixSizeWords = 2;

    //         for (
    //             uint32 nMutationsLeft = nMutations;
    //             nMutationsLeft > 0;
    //             --nMutationsLeft
    //         ) {
    //             // We keep the 16 MSb from nonce because it has better randomness
    //             uint16 iWord = uint16((nonce >> 48) % mutationMatrixSizeWords);
    //             uint8 pixelIndex = uint8(nonce >> 32);

    //             // Applying the mutation color via a mask
    //             bytes32 nullMask = bytes32(~(0x1 << pixelIndex));

    //             mutationMatrix[iWord] &= nullMask;

    //             // Generating the next nonce using MMIX LGC parameters by Donald Knuth (used in RISC architecture)
    //             nonce = (nonce * 6364136223846793005 + 1442695040888963407); // Wrap-around on 64 bits
    //         }
    //     }
    // }

    // struct Toast {
    //     uint64 nonce;
    //     uint32 mutationMatrixSizeWords;
    //     uint32 nMutationsLeft;
    //     uint16 iWord;
    //     uint8 pixelIndex;
    //     bytes32 nullMask;
    // }

    // function mutationAB(uint32 nMutations) public {
    //     unchecked {
    //         Toast memory toast;
    //         toast.nonce = random();
    //         toast.mutationMatrixSizeWords = 100;

    //         for (
    //             toast.nMutationsLeft = nMutations;
    //             toast.nMutationsLeft > 0;
    //             --toast.nMutationsLeft
    //         ) {
    //             // We keep the 16 MSb from nonce because it has better randomness
    //             toast.iWord = uint16(
    //                 (toast.nonce >> 48) % toast.mutationMatrixSizeWords
    //             );
    //             toast.pixelIndex = uint8(toast.nonce >> 32);

    //             // Applying the mutation color via a mask
    //             toast.nullMask = bytes32(~(0x1 << toast.pixelIndex));

    //             mutationMatrix[toast.iWord] &= toast.nullMask;

    //             // Generating the next nonce using MMIX LGC parameters by Donald Knuth (used in RISC architecture)
    //             toast.nonce = (toast.nonce *
    //                 6364136223846793005 +
    //                 1442695040888963407); // Wrap-around on 64 bits
    //         }
    //     }
    // }

    // function mutationB(uint nMutations) public {
    //     unchecked {
    //         uint64 nonce = random();
    //         uint mutationMatrixSizeWords = 100;

    //         for (
    //             uint nMutationsLeft = nMutations;
    //             nMutationsLeft > 0;
    //             --nMutationsLeft
    //         ) {
    //             // We keep the 16 MSb from nonce because it has better randomness
    //             uint iWord = (nonce >> 48) % mutationMatrixSizeWords;
    //             uint pixelIndex = (nonce >> 32) & 0xFF;

    //             // Applying the mutation color via a mask
    //             bytes32 nullMask = bytes32(~(0x1 << pixelIndex));

    //             mutationMatrix2[iWord] &= nullMask;

    //             // Generating the next nonce using MMIX LGC parameters by Donald Knuth (used in RISC architecture)
    //             nonce = (nonce * 6364136223846793005 + 1442695040888963407); // Wrap-around on 64 bits
    //         }
    //     }
    // }

    // // = à BA
    // function mutationBAwhile(uint nMutations) public {
    //     unchecked {
    //         uint64 nonce = random();
    //         uint mutationMatrixSizeWords = 100;

    //         while (nMutations-- > 0) {
    //             // We keep the 16 MSb from nonce because it has better randomness
    //             uint iWord = (nonce >> 48) % mutationMatrixSizeWords;
    //             uint pixelIndex = (nonce >> 32) & 0xFF;

    //             // Applying the mutation color via a mask
    //             mutationMatrix2[iWord] &= bytes32(~(0x1 << pixelIndex));

    //             // Generating the next nonce using MMIX LGC parameters by Donald Knuth (used in RISC architecture)
    //             nonce = (nonce * 6364136223846793005 + 1442695040888963407); // Wrap-around on 64 bits
    //         }
    //     }
    // }

    // // = à BA
    // function mutationBinline(uint nMutations) public {
    //     unchecked {
    //         uint64 nonce = random();
    //         uint mutationMatrixSizeWords = 100;

    //         for (
    //             uint nMutationsLeft = nMutations;
    //             nMutationsLeft > 0;
    //             --nMutationsLeft
    //         ) {
    //             // Applying the mutation color via a mask
    //             mutationMatrix2[
    //                 (nonce >> 48) % mutationMatrixSizeWords
    //             ] &= bytes32(~(0x1 << ((nonce >> 32) & 0xFF)));

    //             // Generating the next nonce using MMIX LGC parameters by Donald Knuth (used in RISC architecture)
    //             nonce = (nonce * 6364136223846793005 + 1442695040888963407); // Wrap-around on 64 bits
    //         }
    //     }
    // }

    // function mutationBinlineWhile(uint nMutations) public {
    //     unchecked {
    //         uint64 nonce = random();
    //         uint mutationMatrixSizeWords = 2;

    //         while ((nMutations--) > 0) {
    //             // Applying the mutation color via a mask
    //             mutationMatrix2[
    //                 (nonce >> 48) % mutationMatrixSizeWords
    //             ] &= bytes32(~(0x1 << ((nonce >> 32) & 0xFF)));

    //             // Generating the next nonce using MMIX LGC parameters by Donald Knuth (used in RISC architecture)
    //             nonce = (nonce * 6364136223846793005 + 1442695040888963407); // Wrap-around on 64 bits
    //         }
    //     }
    // }

    // function mutationBB(uint nMutations) public {
    //     unchecked {
    //         uint64 nonce = random();
    //         uint mutationMatrixSizeWords = 2;
    //         uint iWord;
    //         uint pixelIndex;
    //         bytes32 nullMask;

    //         for (
    //             uint nMutationsLeft = nMutations;
    //             nMutationsLeft > 0;
    //             --nMutationsLeft
    //         ) {
    //             // We keep the 16 MSb from nonce because it has better randomness
    //             iWord = (nonce >> 48) % mutationMatrixSizeWords;
    //             pixelIndex = (nonce >> 32) & 0xFF;

    //             // Applying the mutation color via a mask
    //             nullMask = bytes32(~(0x1 << pixelIndex));

    //             mutationMatrix2[iWord] &= nullMask;

    //             // Generating the next nonce using MMIX LGC parameters by Donald Knuth (used in RISC architecture)
    //             nonce = (nonce * 6364136223846793005 + 1442695040888963407); // Wrap-around on 64 bits
    //         }
    //     }
    // }

    // function randomC() private view returns (uint) {
    //     return
    //         uint256(
    //             keccak256(
    //                 abi.encodePacked(
    //                     block.difficulty,
    //                     block.timestamp,
    //                     blockhash(block.number - 1),
    //                     msg.sender
    //                 )
    //             )
    //         );
    // }

    // function mutationC(uint nMutations) public {
    //     unchecked {
    //         uint nonce = randomC();
    //         uint mutationMatrixSizeWords = 2;

    //         for (
    //             uint nMutationsLeft = nMutations;
    //             nMutationsLeft > 0;
    //             --nMutationsLeft
    //         ) {
    //             // We keep the 16 MSb from nonce because it has better randomness
    //             uint iWord = (nonce >> 48) % mutationMatrixSizeWords;
    //             uint pixelIndex = (nonce >> 32) & 0xFF;

    //             // Applying the mutation color via a mask
    //             bytes32 nullMask = bytes32(~(0x1 << pixelIndex));

    //             mutationMatrix2[iWord] &= nullMask;

    //             // Generating the next nonce using MMIX LGC parameters by Donald Knuth (used in RISC architecture)
    //             nonce =
    //                 (nonce * 6364136223846793005 + 1442695040888963407) %
    //                 0xffffffffffffffff; // Wrap-around on 64 bits
    //         }
    //     }
    // }
}