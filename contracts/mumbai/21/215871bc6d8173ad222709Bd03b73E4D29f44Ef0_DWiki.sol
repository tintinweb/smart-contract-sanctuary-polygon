// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract DWiki {
  uint256 public videoCount = 0;

  string public name = "DWiki";
  mapping(uint256 => Video) public videos;

  struct Video {
    uint256 id;
    string hash;
    string title;
    address author;
  }

  event VideoUploaded(
    uint indexed id,
    string hash,
    string title,
    address author
  );

  constructor() {}

  function uploadVideo(string memory _videoHash, string memory _title) public {
    // Make sure video hash exists
    require(bytes(_videoHash).length > 0);
    // Make sure video title exists
    require(bytes(_title).length > 0);
    // Make sure uploader address exists
    require(msg.sender != address(0));

    videoCount += 1;

    // Add video to the contract
    videos[videoCount] = Video(videoCount, _videoHash, _title, msg.sender);
    emit VideoUploaded(videoCount, _videoHash, _title, msg.sender);
  }
}