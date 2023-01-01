// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


// BlockTube Contract
contract BlockTube {
    
    // Counting the number of videos uploaded
    uint256 public numberVideos = 0;

    // Structure for Video
    struct Video {
        uint256 id;
        uint256 date;
        string location;
        string title;
        string description;
        string category;
        address owner;
    }
    
    // Mapping videos to unique id's
    mapping(uint256 => Video) public Videos;

    // Event for uploading video
    event videoUploaded(
        uint256 videoNumber,
        uint256 date,
        string location,
        string title,
        string description,
        string category,
        address owner
    );

    /*
     * @dev Uploads the video (Save its info to Videos mapping)
     * @param _location is the ipfs address where video is saved
     * @param _title of the video
     * @param _description of the video
     * @param _category in which the video lies
     */
    function uploadVideo(
        string memory _location,
        string memory _title,
        string memory _description,
        string memory _category
    ) public {
        // Checks if the info about the video provided
        require(
            bytes(_location).length > 0 &&
                bytes(_title).length > 0 &&
                bytes(_description).length > 0 &&
                bytes(_category).length > 0,
            "Check if all the details are provided."
        );
        // Checks for the senders address
        assert(msg.sender != address(0));
        Videos[numberVideos] = Video(
            numberVideos,
            block.timestamp,
            _location,
            _title,
            _description,
            _category,
            msg.sender
        );
        emit videoUploaded(
            numberVideos,
            block.timestamp,
            _location,
            _title,
            _description,
            _category,
            msg.sender
        );
        numberVideos++;
    }
}