// SPDX-License-Identifier: GPL-2.0-or-later

//                 ____    ____
//                /\___\  /\___\
//       ________/ /   /_ \/___/
//      /\_______\/   /__\___\
//     / /       /       /   /
//    / /   /   /   /   /   /
//   / /   /___/___/___/___/
//  / /   /
//  \/___/

pragma solidity >=0.8.18;

/// @title EmissionLogic
contract EmissionLogic {
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    constructor() {
        // Constructor code goes here, if any
    }

    function determineTokenId(uint256 logicVersion) public view returns (uint8) {
        // Generate a pseudo-random number from blockchain state variables
        uint256 random = uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, msg.sender)));

        // Normalize the random number to [0, 1000)
        uint256 normalized = random % 1000;

        // Determine the token ID based on the normalized random number and the specified logic version
        if (logicVersion == 1) {
            return determineTokenIdV1(normalized);
        } else if (logicVersion == 2) {
            return determineTokenIdV2(normalized);
        } else {
            return determineTokenIdV3(normalized);
        }
    }

    function determineTokenIdV1(uint256 normalized) internal pure returns (uint8) {
        if (normalized < 300) {
            return 1;
        } else if (normalized < 500) {
            return 2;
        } else if (normalized < 700) {
            return 3;
        } else if (normalized < 850) {
            return 4;
        } else if (normalized < 950) {
            return 5;
        } else if (normalized < 999) {
            return 6;
        } else {
            return 7;
        }
    }

    function determineTokenIdV2(uint256 normalized) internal pure returns (uint8) {
        if (normalized < 250) {
            return 1;
        } else if (normalized < 450) {
            return 2;
        } else if (normalized < 600) {
            return 3;
        } else if (normalized < 750) {
            return 4;
        } else if (normalized < 900) {
            return 5;
        } else if (normalized < 990) {
            return 6;
        } else {
            return 7;
        }
    }

    function determineTokenIdV3(uint256 normalized) internal pure returns (uint8) {
        if (normalized < 200) {
            return 1;
        } else if (normalized < 350) {
            return 2;
        } else if (normalized < 500) {
            return 3;
        } else if (normalized < 650) {
            return 4;
        } else if (normalized < 800) {
            return 5;
        } else if (normalized < 950) {
            return 6;
        } else {
            return 7;
        }
    }
}