// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PeerPlay{
    uint256 public videoCount = 0;
    string public name = "Peerplay";
    mapping(uint256=>Video) public videos;

    struct Video{
        uint256 id;
        string hash;
        string title;
        string description;
        string location;
        string category;
        string thumbnailHash;
        string date;
        address author;
    }

    event VideoUploaded(
        uint256 id,
        string hash,
        string title,
        string description,
        string location,
        string category,
        string thumbnail,
        string date,
        address author
    );


    function uploadVideo(
        string memory _videoHash,
        string memory _title,
        string memory _description,
        string memory _location,
        string memory _category,
        string memory _thumbnailHash,
        string memory _date
    ) public {
        require(bytes(_videoHash).length>0);
        require(bytes(_title).length>0);
        require(msg.sender!=address(0));

        videoCount++;

        videos[videoCount]=Video(
            videoCount,
            _videoHash,
            _title,
            _description,
            _location,
            _category,
            _thumbnailHash,
            _date,
            msg.sender
        );

        emit VideoUploaded(
            videoCount,
            _videoHash,
            _title,
            _description,
            _location,
            _category,
            _thumbnailHash,
            _date,
            msg.sender
        );
    }
}