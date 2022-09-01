/**
 *Submitted for verification at polygonscan.com on 2022-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MoodContract {
    address owner;

    enum Moods {
        HAPPY,
        SAD,
        ANGRY
    }
    Moods moods;

    constructor() {
        owner = msg.sender;
    }

    function setAngry() public {
        moods = Moods.ANGRY;
    }

    function setHappy() public {
        moods = Moods.HAPPY;
    }

    function setSad() public {
        moods = Moods.SAD;
    }

    function getMoodByKey(Moods _mood) internal pure returns (string memory) {
        // Error handling for input
        require(uint8(_mood) <= 3);

        // Loop through possible options
        if (Moods.SAD == _mood) return "SAD";
        if (Moods.ANGRY == _mood) return "ANGRY";
        if (Moods.HAPPY == _mood) return "HAPPY";
    }

    // Retrieve Mood
    function getMood() public view returns (string memory) {
        return getMoodByKey(moods);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function payOwner() external {
        require(msg.sender == owner);
        (bool success, ) = payable(owner).call{value: address(this).balance}(
            ""
        );
        require(success);
    }

    fallback() external payable {}

    receive() external payable {}
}