// SPDX-License-Identifier: MIT

//                 ____    ____
//                /\___\  /\___\
//       ________/ /   /_ \/___/
//      /\_______\/   /__\___\
//     / /       /       /   /
//    / /   /   /   /   /   /
//   / /   /___/___/___/___/
//  / /   /
//  \/___/

pragma solidity 0.8.19;

/*
|         | Logic1 : Drop rate (%) | Logic2 : Drop rate (%) | Logic3 : Drop rate (%) |
|---------|------------------------|------------------------|------------------------|
| Stone   | 30                     | 25                     | 20                     |
| Water   | 20                     | 20                     | 15                     |
| Coal    | 20                     | 15                     | 15                     |
| Copper  | 15                     | 15                     | 15                     |
| Steel   | 10                     | 15                     | 15                     |
| Gold    | 4.9                    | 9                      | 15                     |
| Diamond | 0.1                    | 1                      | 5                      |
*/

/// @title EmissionLogic
/// @dev The EmissionLogic.sol contract controls the emission logic of MaterialObjects, defining their frequency and
/// quantity. This logic can potentially be modified by the management.
contract EmissionLogic {
    /* --------------------------------- ****** --------------------------------- */
    // Define constants for token IDs
    uint256 public constant STONE_ID = 100_001;
    uint256 public constant WATER_ID = 100_002;
    uint256 public constant COAL_ID = 100_003;
    uint256 public constant COPPER_ID = 100_004;
    uint256 public constant STEEL_ID = 100_005;
    uint256 public constant GOLD_ID = 100_006;
    uint256 public constant DIAMOND_ID = 100_007;

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    /// @dev This function uses the specified logic to determine the token ID to be emitted.
    /// @param logic The logic version to use (1, 2, or 3).
    /// @return tokenid to be emitted.
    function determineTokenByLogic(uint16 logic) external view returns (uint256 tokenid) {
        // Generate a pseudo-random number from blockchain state variables
        uint256 random = uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, tx.origin)));

        // Normalize the random number to [0, 1000)
        uint256 normalized = random % 1000;

        if (logic == 1) {
            return _determineTokenIdV1(normalized);
        } else if (logic == 2) {
            return _determineTokenIdV2(normalized);
        } else if (logic == 3) {
            return _determineTokenIdV3(normalized);
        } else {
            revert("Invalid logic value");
        }
    }

    /// @dev Logic version 1 for determining token ID.
    function _determineTokenIdV1(uint256 normalized) internal pure returns (uint256) {
        if (normalized < 300) {
            return STONE_ID;
        } else if (normalized < 500) {
            return WATER_ID;
        } else if (normalized < 700) {
            return COAL_ID;
        } else if (normalized < 850) {
            return COPPER_ID;
        } else if (normalized < 950) {
            return STEEL_ID;
        } else if (normalized < 999) {
            return GOLD_ID;
        } else {
            return DIAMOND_ID;
        }
    }

    /// @dev Logic version 2 for determining token ID.
    function _determineTokenIdV2(uint256 normalized) internal pure returns (uint256) {
        if (normalized < 250) {
            return STONE_ID;
        } else if (normalized < 450) {
            return WATER_ID;
        } else if (normalized < 600) {
            return COAL_ID;
        } else if (normalized < 750) {
            return COPPER_ID;
        } else if (normalized < 900) {
            return STEEL_ID;
        } else if (normalized < 990) {
            return GOLD_ID;
        } else {
            return DIAMOND_ID;
        }
    }

    /// @dev Logic version 3 for determining token ID.
    function _determineTokenIdV3(uint256 normalized) internal pure returns (uint256) {
        if (normalized < 200) {
            return STONE_ID;
        } else if (normalized < 350) {
            return WATER_ID;
        } else if (normalized < 500) {
            return COAL_ID;
        } else if (normalized < 650) {
            return COPPER_ID;
        } else if (normalized < 800) {
            return STEEL_ID;
        } else if (normalized < 950) {
            return GOLD_ID;
        } else {
            return DIAMOND_ID;
        }
    }
}