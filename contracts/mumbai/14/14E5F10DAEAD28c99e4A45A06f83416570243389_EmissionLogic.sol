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

    function determineTokenId(uint256 logic) public view returns (uint256 tokenid) {
        // Generate a pseudo-random number from blockchain state variables
        uint256 random = uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, tx.origin)));

        // Normalize the random number to [0, 1000)
        uint256 normalized = random % 1000;

        // Determine the token ID based on the normalized random number and the specified logic
        if (logic == 1) {
            return determineTokenIdV1(normalized);
        } else if (logic == 2) {
            return determineTokenIdV2(normalized);
        } else if (logic == 3) {
            return determineTokenIdV3(normalized);
        } else {
            revert("Invalid logic value");
        }
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                           　　DetermineTokenId                              */
    /* -------------------------------------------------------------------------- */

    function determineTokenIdV1(uint256 normalized) internal pure returns (uint256) {
        if (normalized < 300) {
            return 100001;
        } else if (normalized < 500) {
            return 100002;
        } else if (normalized < 700) {
            return 100003;
        } else if (normalized < 850) {
            return 100004;
        } else if (normalized < 950) {
            return 100005;
        } else if (normalized < 999) {
            return 100006;
        } else {
            return 100007;
        }
    }

    function determineTokenIdV2(uint256 normalized) internal pure returns (uint256) {
        if (normalized < 250) {
            return 100001;
        } else if (normalized < 450) {
            return 100002;
        } else if (normalized < 600) {
            return 100003;
        } else if (normalized < 750) {
            return 100004;
        } else if (normalized < 900) {
            return 100005;
        } else if (normalized < 990) {
            return 100006;
        } else {
            return 100007;
        }
    }

    function determineTokenIdV3(uint256 normalized) internal pure returns (uint256) {
        if (normalized < 200) {
            return 100001;
        } else if (normalized < 350) {
            return 100002;
        } else if (normalized < 500) {
            return 100003;
        } else if (normalized < 650) {
            return 100004;
        } else if (normalized < 800) {
            return 100005;
        } else if (normalized < 950) {
            return 100006;
        } else {
            return 100007;
        }
    }
}