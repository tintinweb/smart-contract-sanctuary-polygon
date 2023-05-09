// SPDX-License-Identifier: MIT

pragma solidity^0.8.0;

// Author: @Kekaze
contract moodDiary {
    // This is the body of the contract..

    string mood;

    // This function is a write function to set a mood
    function setMood(string memory _mood) public {
        mood = _mood;
    }

    // this function is a read function to read the set mood

    function getMood () public view returns(string memory){
        return mood;
    }
}