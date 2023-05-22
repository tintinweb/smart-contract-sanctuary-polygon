// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Random {
    //Random Number Generator
    function random(
        uint256 number,
        uint256 counter
    ) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender,
                        counter
                    )
                )
            ) % number;
    }

    //Random String Generator (Max length 14)

    function randomString(uint256 length) public view returns (string memory) {
        require(length <= 14, "Length cannot be greater than 14");
        require(length >= 1, "Length cannot be Zero");
        bytes memory randomWord = new bytes(length);
        // since we have 62 Characters
        bytes memory chars = new bytes(62);
        chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        for (uint256 i = 0; i < length; i++) {
            uint256 randomNumber = random(62, i);
            // Index access for string is not possible
            randomWord[i] = chars[randomNumber];
        }
        return string(randomWord);
    }
}