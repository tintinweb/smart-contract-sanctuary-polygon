/**
 *Submitted for verification at polygonscan.com on 2023-04-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library Randomness {
    // memory struct for rand
    struct RNG {
        uint256 seed;
        uint256 nonce;
    }

    /// @dev get a random number
    function getRandom(RNG storage rng)
        external
        returns (uint256 randomness, uint256 random)
    {
        return _getRandom(rng, 0, 2**256 - 1, rng.seed);
    }

    /// @dev get a random number
    function getRandom(RNG storage rng, uint256 randomness)
        external
        returns (uint256 randomness_, uint256 random)
    {
        return _getRandom(rng, randomness, 2**256 - 1, rng.seed);
    }

    /// @dev get a random number passing in a custom seed
    function getRandom(
        RNG storage rng,
        uint256 randomness,
        uint256 seed
    ) external returns (uint256 randomness_, uint256 random) {
        return _getRandom(rng, randomness, 2**256 - 1, seed);
    }

    /// @dev get a random number in range (0, _max)
    function getRandomRange(RNG storage rng, uint256 max)
        external
        returns (uint256 randomness, uint256 random)
    {
        return _getRandom(rng, 0, max, rng.seed);
    }

    /// @dev get a random number in range (0, _max)
    function getRandomRange(
        RNG storage rng,
        uint256 randomness,
        uint256 max
    ) external returns (uint256 randomness_, uint256 random) {
        return _getRandom(rng, randomness, max, rng.seed);
    }

    /// @dev get a random number in range (0, _max) passing in a custom seed
    function getRandomRange(
        RNG storage rng,
        uint256 randomness,
        uint256 max,
        uint256 seed
    ) external returns (uint256 randomness_, uint256 random) {
        return _getRandom(rng, randomness, max, seed);
    }

    /// @dev fullfill a random number request for the given inputs, incrementing the nonce, and returning the random number
    function _getRandom(
        RNG storage rng,
        uint256 randomness,
        uint256 max,
        uint256 seed
    ) internal returns (uint256 randomness_, uint256 random) {
        // if the randomness is zero, we need to fill it
        if (randomness <= 0) {
            // increment the nonce in case we roll over
            unchecked {
                rng.nonce++;
            }
            randomness = uint256(
                keccak256(
                    abi.encodePacked(
                        seed,
                        rng.nonce,
                        block.timestamp,
                        msg.sender,
                        blockhash(block.number - 1)
                    )
                )
            );
        }
        // mod to the requested range
        random = randomness % max;
        // shift bits to the right to get a new random number
        randomness_ = randomness >>= 4;
    }
}