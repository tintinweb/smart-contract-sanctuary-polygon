// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract WeTube {
    uint256 public currentVideoId;

    struct Video {
        uint256 id;
        string title;
        string description;
        string category;
        string location;
        string thumbnailHash;
        string videoHash;
        address owner;
        uint256 createdAt;
    }

    mapping(uint256 => Video) public videos;

    event VideoAdded(
        uint256 id,
        string title,
        string description,
        string category,
        string location,
        string thumbnailHash,
        string videoHash,
        address owner,
        uint256 createdAt
    );

    function addVideo(
        string memory _title,
        string memory _description,
        string memory _category,
        string memory _location,
        string memory _thumbnailHash,
        string memory _videoHash
    ) public {
        require(bytes(_videoHash).length > 0, "Video hash cannot be empty");
        require(
            bytes(_thumbnailHash).length > 0,
            "Thumbnail hash cannot be empty"
        );
        require(bytes(_title).length > 0, "Title cannot be empty");
        videos[currentVideoId] = Video(
            currentVideoId,
            _title,
            _description,
            _category,
            _location,
            _thumbnailHash,
            _videoHash,
            msg.sender,
            block.timestamp
        );
        emit VideoAdded(
            currentVideoId,
            _title,
            _description,
            _category,
            _location,
            _thumbnailHash,
            _videoHash,
            msg.sender,
            block.timestamp
        );
        currentVideoId++;
    }
}