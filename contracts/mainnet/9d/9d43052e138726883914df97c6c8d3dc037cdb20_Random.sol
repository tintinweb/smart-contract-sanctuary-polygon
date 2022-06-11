/**
 *Submitted for verification at polygonscan.com on 2022-06-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

contract Random {
    uint256 counter;

    function canSteal(uint256, uint256) external returns (bool) {
        counter++;
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    counter +
                        block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );

        return ((seed % 100) + 1) <= 10 ? true : false;
    }

    function getMonsterId(
        uint256[] memory _tokenIds,
        uint256,
        uint256
    ) external view returns (uint256) {
        if (_tokenIds.length == 0) {
            return type(uint256).max;
        } else {
            uint256 seed = uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp +
                            block.difficulty +
                            ((
                                uint256(
                                    keccak256(abi.encodePacked(block.coinbase))
                                )
                            ) / (block.timestamp)) +
                            block.gaslimit +
                            ((
                                uint256(keccak256(abi.encodePacked(msg.sender)))
                            ) / (block.timestamp)) +
                            block.number
                    )
                )
            );

            uint256 index = seed % _tokenIds.length;
            return _tokenIds[index];
        }
    }
}