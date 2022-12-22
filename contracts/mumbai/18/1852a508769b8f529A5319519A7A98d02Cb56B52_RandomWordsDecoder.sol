// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract RandomWordsDecoder {
    function decodeRandomness(uint256 randomness, uint256 numWords)
        public
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256[] memory randomWords = new uint256[](numWords);
        for (uint256 i = 0; i < numWords; i++) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }
        return (randomWords[0], randomWords[1], randomWords[2]);
    }
}