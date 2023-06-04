// SPDX-License-Identifier: GPL-3.0

/**
 * @title The RoboNounsToken pseudo-random seed generator
 * @author NounsDAO
 * @notice This contract generates a pseudo-random seed for a Noun using a block number and noun ID.
 * @dev This contract is used by the NounsToken contract to generate a pseudo-random seed for a Noun.
 */

pragma solidity ^0.8.6;

import { INounsSeeder } from "contracts/interfaces/INounsSeeder.sol";
import { INounsDescriptorMinimal } from "contracts/interfaces/INounsDescriptorMinimal.sol";

contract RoboNounsSeeder is INounsSeeder {
    /**
     * @notice Generate a pseudo-random Noun seed using the previous blockhash and noun ID. Use robo nouns for custom accessories.
     */
    function generateSeed(
        uint256 nounId,
        INounsDescriptorMinimal roboDescriptor,
        uint256 blockNumber
    ) external view override returns (Seed memory) {
        uint256 pseudorandomness = uint256(keccak256(abi.encodePacked(blockhash(blockNumber), nounId)));

        uint256 headCount = roboDescriptor.headCount();
        uint256 glassesCount = roboDescriptor.glassesCount();
        uint256 backgroundCount = roboDescriptor.backgroundCount();
        uint256 bodyCount = roboDescriptor.bodyCount();
        uint256 accessoryCount = roboDescriptor.accessoryCount();

        return
            Seed({
                background: uint48(uint48(pseudorandomness) % backgroundCount),
                body: uint48(uint48(pseudorandomness >> 48) % bodyCount),
                accessory: uint48(uint48(pseudorandomness >> 96) % accessoryCount),
                head: uint48(uint48(pseudorandomness >> 144) % headCount),
                glasses: uint48(uint48(pseudorandomness >> 192) % glassesCount)
            });
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsSeeder

pragma solidity ^0.8.6;

import { INounsDescriptorMinimal } from "contracts/interfaces/INounsDescriptorMinimal.sol";

interface INounsSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }

    function generateSeed(
        uint256 nounId,
        INounsDescriptorMinimal descriptor,
        uint256 blockNumber
    ) external view returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Common interface for NounsDescriptor versions, as used by NounsToken and NounsSeeder.

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { INounsSeeder } from "./INounsSeeder.sol";

interface INounsDescriptorMinimal {
    ///
    /// USED BY TOKEN
    ///

    function tokenURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view returns (string memory);

    ///
    /// USED BY SEEDER
    ///

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function glassesCount() external view returns (uint256);
}