// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ISnowV1Program} from "./ISnowV1Program.sol";

contract TicTacToe is ISnowV1Program {
    function name() external view returns (string memory) {
        return "MultiTileProgram";
    }

    function run(uint256[64] calldata canvas, uint8 /* lastUpdatedIndex */) external returns (uint8 index, uint256 value) {
        // bottom left 3x3 tiles
        uint8[9] memory indices = [ 40, 41, 42, 48, 49, 50, 56, 57, 58 ];
        uint256[9] memory values = [
            0x0001000108090c11046106410281010107810c4118213011001100010001ffff,
            0x8001800183f18611841198099009b011a011a011a031906198c187818001ffff,
            0x80008000860c8308819880908070806080b081108318860c8c0480008000ffff,
            0xffff0001000118210c410481038102010701098118c13041002100010001ffff,
            0xffff8001800188118c31846182c181818101828186c18c61983180018001ffff,
            0xffff8000800083e086308c18880888088808880888108810847083c08000ffff,
            0xffff0001000101e107310411081908090809080908190831046107c100010001,
            0xffff8001800187e18c3188119011901190119011981188318fe1800180018001,
            0xffff8000800087c08460842086208020806080c0808080808000800080808000
        ];

        uint256 i = 0;
        unchecked {
            // look for tiles that have not been painted yet or have been stomped on
            // inspired by https://hackmd.io/@axic/snow-qr-nft
            while (canvas[indices[i]] == values[i] && i < 9) {
                ++i;
            }
        }

        return (indices[i], values[i]);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISnowV1Program {
    function name() external view returns (string memory);

    function run(uint256[64] memory canvas, uint8 lastUpdatedIndex)
        external
        returns (uint8 index, uint256 value);
}