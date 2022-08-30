// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../ISnowV1Program.sol";

contract myFirstDeploy is ISnowV1Program {
    address public owner = 0x863379Ab401d454834E1FE2eCe48F51a29eE9d7A;
    uint8 public savedIndex = 8;
    uint256 public savedSprite = 0x00000000000003c003c00030003003f003f00c300c3003f003f0000000000000;

    function name() external pure returns (string memory) {
        // My first Solidity deploy. Thank you, w1nt3r, for this opportunity to play!
        return "myFirstDeploy";
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;  
    }

    function changeIndex(uint8 newIndex) public {
        require(msg.sender == owner);
        savedIndex = newIndex;
    }

    function changeSprite(uint256 newSprite) public {
        require(msg.sender == owner);
        // Sprites created with https://snow.computer/operators
        savedSprite = newSprite;
    }

    function run(uint256[64] calldata canvas, uint8 lastUpdatedIndex)
        external
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