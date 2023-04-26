/**
 *Submitted for verification at polygonscan.com on 2023-04-25
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract story {
    //
    uint256 public storyCounter;
    uint256 public startTime;
    uint256 private lastWrittenYear;

    //
    //STRUCT
    //
    struct Story {
        uint256 backStoryId; //storyId happened 1 year ago & 0 start
        uint256 timestamp; 
        string incident; 
        bool isFinal; //If you choice true, the world line finish by the incident
        address teller;
        //bool isEmpty; 
    }

    //
    //MAPPING
    //
    mapping(uint256 => Story) storyList;

    //
    //EVENT
    //
    event WriteStory(
        uint256 indexed storyId, 
        uint256 indexed backStoryId,
        uint256 year, 
        string incident,
        address indexed teller,
        bool isFinal
        );

    //
    //CONSTRUCTOR
    //
    constructor() {
        startTime = block.timestamp;
        storyCounter = 0;
    }

    //
    //MAIN
    //

    function currentYear() public view returns(uint256) {
        return (block.timestamp - startTime) / 60;
        } 
        //the function is to return current year
        //8640 = 2.4h * 3600sec(1h)


    function writeStory (
        uint256 _backStoryId, 
        string memory _incident,
        bool _isFinal
    ) public {
         require(
            _backStoryId == 0 || (
                storyList[_backStoryId].timestamp >= startTime &&
                !storyList[_backStoryId].isFinal
            ),
            "Invalid_back_story_ID"
        );
        //check whether there is a incident before year


        Story memory newStory = Story({
            backStoryId: _backStoryId,
            timestamp: block.timestamp,
            incident: _incident,
            isFinal: _isFinal,
            teller: msg.sender
        });

        storyList[storyCounter] = newStory;
        storyCounter++;

        emit WriteStory(storyCounter -1, _backStoryId, currentYear(), _incident, msg.sender, _isFinal);
    }




    //
    //GET
    //
    function getStory(uint256 _storyId) external view returns(Story memory) {
        return storyList[_storyId];
    }

    function getCurrentYear() public view returns(uint256) {
    return (block.timestamp - startTime) / 60;
    } //actual time setting of Story Teller

    ///
    function getLastWrittenYear() public view returns(uint256) {
    return lastWrittenYear;
    }

    function setLastWrittenYear(uint256 _lastWrittenYear) private {
    lastWrittenYear = _lastWrittenYear;
    }
}