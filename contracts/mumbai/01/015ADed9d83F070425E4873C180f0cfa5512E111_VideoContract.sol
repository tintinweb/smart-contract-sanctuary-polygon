// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface IVideoContract {
    /**
     * @notice Event is emitted after a video is uploaded
     */
    event VideoUploaded(
        uint256 id,
        string hashNum,
        string title,
        string description,
        string thumbnailHash,
        string date,
        address author
    );

    /**
     * @notice Emitted when owner updates the super token factory
     * @param _videoHash unique hash of the video
     * @param _title title of the video
     * @param _description description of the video
     * @param _thumbnailHash hash of the thumbnail uploaded to ipfs
     * @param _date date of the upload
     */
    function uploadVideo(
        string memory _videoHash,
        string memory _title,
        string memory _description,
        string memory _thumbnailHash,
        string memory _date
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.11;

import "./interfaces/IVideoContract.sol";

contract VideoContract is IVideoContract {
    uint256 public videoCount = 0;

    /// @notice name of the contract
    string public name = "Splash";

    /// @notice  mapping of videoCount to Video
    mapping(uint256 => Video) public videos;

    struct Video {
        uint256 id;
        string hashNum;
        string title;
        string description;
        string thumbnailHash;
        string date;
        address author;
    }

    constructor() {}

    /**
     * @notice Emitted when owner updates the super token factory
     * @param _videoHash unique hash of the video
     * @param _title title of the video
     * @param _description description of the video
     * @param _thumbnailHash hash of the thumbnail uploaded to ipfs
     * @param _date date of the upload
     */
    function uploadVideo(
        string memory _videoHash,
        string memory _title,
        string memory _description,
        string memory _thumbnailHash,
        string memory _date
    ) public {
        require(bytes(_videoHash).length > 0);
        require(bytes(_title).length > 0);
        require(msg.sender != address(0));

        videoCount++;

        videos[videoCount] = Video(
            videoCount,
            _videoHash,
            _title,
            _description,
            _thumbnailHash,
            _date,
            msg.sender
        );

        emit VideoUploaded(
            videoCount,
            _videoHash,
            _title,
            _description,
            _thumbnailHash,
            _date,
            msg.sender
        );
    }
}