// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ISnowV1Program} from "./ISnowV1Program.sol";

/// @title  myFirstDeploy
/// @author andrewkingme
/// @notice My First Solidity Deploy
/// @dev Thank you, w1nt3r, for this opportunity to play!
contract myFirstDeploy is ISnowV1Program {
    address public owner = 0x863379Ab401d454834E1FE2eCe48F51a29eE9d7A;
    uint8 public savedIndex = 7;
    uint256 public savedSprite = 0x00000000000003c003c00030003003f003f00c300c3003f003f0000000000000;

    /// @notice My First Solidity Deploy
    /// @dev Thank you, w1nt3r, for this opportunity to play!
    function name() external pure returns (string memory) {
        return "myFirstDeploy";
    }

    /// @notice Transfer Ownership of Contract
    /// @dev This function can only be called by the current contract owner.
    /// @param newOwner Enter the address of the new owner.
    function transferOwnership(address newOwner) public {
        require(msg.sender == owner, "You are not the contract owner.");
        owner = newOwner;  
    }

    /// @notice Change SnowV1Program Index
    /// @dev The location of the sprite on screen, as displayed at https://snow.computer.
    /// @param newIndex Enter a uint8 index location. [0 (top-left)] - [63 (bottom-right)]
    function changeIndex(uint8 newIndex) public {
        require(msg.sender == owner, "You are not the contract owner.");
        savedIndex = newIndex;
    }

    /// @notice Change SnowV1Program Sprite
    /// @dev The sprite displayed on screen at https://snow.computer. Generate new sprites at https://snow.computer/operators.
    /// @param newSprite Enter a uint256 sprite.
    function changeSprite(uint256 newSprite) public {
        require(msg.sender == owner, "You are not the contract owner.");
        savedSprite = newSprite;
    }

    /// @notice Run SnowV1Program Program
    /// @dev Called by the parent contract (0xF53D926c13Af77C53AFAe6B33480DDd94B167610) tick function.
    /// @return index The location of the sprite on screen, as displayed at https://snow.computer.
    /// @return value The sprite displayed on screen at https://snow.computer.
    function run(uint256[64] calldata, uint8)
        external
        view
        returns (uint8 index, uint256 value)
    {
        index = savedIndex;
        value = savedSprite;
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