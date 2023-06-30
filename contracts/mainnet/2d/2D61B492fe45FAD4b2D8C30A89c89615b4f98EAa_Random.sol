// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Random {
    function random() public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        block.difficulty,
                        blockhash(block.number - 1)
                    )
                )
            ) % 100;
    }

    function randomRange(
        uint256 range,
        uint256 count
    ) public view returns (uint256[] memory) {
        uint256[] memory randomNumbers = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            randomNumbers[i] =
                uint256(
                    keccak256(
                        abi.encodePacked(
                            msg.sender,
                            block.difficulty,
                            blockhash(block.number - 1),
                            i
                        )
                    )
                ) %
                range;
        }

        return randomNumbers;
    }
}