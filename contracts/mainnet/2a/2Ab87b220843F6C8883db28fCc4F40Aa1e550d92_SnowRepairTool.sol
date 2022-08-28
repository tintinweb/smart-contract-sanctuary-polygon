// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "./ISnowV1Program.sol";

/// This contract attempts to maintain the exact state of the canvas it sees during its first run.
/// Because of the gas limit, it actually logs 1 index per run
/// I'm not even sure the gas limit will allow this to entirely run
/// But I'm curious to see how this macro-adversary repair tool will hold up
/// Thanks to axic.eth for his awesome write ups on this https://twitter.com/alexberegszaszi
/// and thank you w1nt3r :)
/// Stay tuned for a v2! https://twitter.com/spencerobsitnik

/// @author 0xspencer.eth
contract SnowRepairTool is ISnowV1Program {
    uint256 private constant count = 64;
    uint256 private canvasLoggedCount;
    uint256[64] private targetCanvas;
    bool private yielded;

    address private constant me = 0x8F4359D1C2166452b5e7a02742D6fe9ca5448FDe;
    address private constant w1nt3r = 0x9d2fc39c2bE15d1F6cdA8E8Ca0Ae1ab61152Ad80;

    function name() external pure returns (string memory) {
        return "SnowRepairTool";
    }

    // canvas repair tool
    // will attempt to retain the state of the canvas on its first run
    function run(uint256[64] calldata canvas, uint8 lastUpdateIndex)
        external
        returns (uint8 index, uint256 value)
    {
        uint256 gg = 0x0000000000001c70228820802080269822881c70000000000000000000000000;

        if (yielded) {
            return (56, gg); // bottom left
        }

        if (canvasLoggedCount < count) {
            targetCanvas[canvasLoggedCount] = canvas[canvasLoggedCount];
            canvasLoggedCount++;
            return (56, gg);
        }

        uint8 iter = 0;
        while (iter < canvasLoggedCount) {
            if (targetCanvas[iter] != canvas[iter]) {
                return (iter, targetCanvas[iter]);
            }
            iter++;
        }

        return (56, gg); // bottom left
    }

    /// yieldable by me or w1nt3r, as this may just be a gas burning contract
    function yield() external {
        require(msg.sender == me || msg.sender == w1nt3r, "unyieldable");
        yielded = true;
    }

    function resetTargetCanvas() external {
        require(msg.sender == me, "not me");
        canvasLoggedCount = 0;
    }
}

interface SnowV1 {
    function canvas(uint256 index) external view returns (uint256);
    function allCanvas() external view returns (uint256[64] memory data);
}

// try to find a group of 3x3

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

interface ISnowV1Program {
    function name() external view returns (string memory);

    function run(uint256[64] calldata canvas, uint8 lastUpdatedIndex)
        external
        returns (uint8 index, uint256 value);
}