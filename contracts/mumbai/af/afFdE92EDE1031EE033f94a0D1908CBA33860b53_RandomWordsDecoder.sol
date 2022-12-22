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
        return (
            expandRandomNumber(randomWords[0]),
            expandRandomNumber(randomWords[1]),
            expandRandomNumber(randomWords[2])
        );
    }

    function expandRandomNumber(uint256 randomValue)
        public
        pure
        returns (uint256 expandedValue)
    {
        // Expand random number
        expandedValue = (randomValue % 6) + 1;
    }
}