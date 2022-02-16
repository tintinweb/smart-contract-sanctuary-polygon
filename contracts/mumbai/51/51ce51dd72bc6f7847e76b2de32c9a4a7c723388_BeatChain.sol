/**
 *Submitted for verification at polygonscan.com on 2022-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract BeatChain {
  uint public videoCount;
  string public name;
  mapping(uint => Video) public videos;

  struct Video {
    uint id;
    string hash;
    string title;
    address payable author;
  }

  event VideoUploaded(
    uint id,
    string hash,
    string title,
    address payable author
  );

  event PaidForStream(
		string hash,
		address listener,
		uint payment
  );

  constructor() {
    videoCount = 0;
    name = "BeatChain";
  }

  function uploadVideo(string memory _videoHash, string memory _title) public {
    // Make sure the video hash exists
    require(bytes(_videoHash).length > 0);
    // Make sure video title exists
    require(bytes(_title).length > 0);
    // Make sure uploader address exists
    require(msg.sender!=address(0));

    // Increment video id
    videoCount ++;

    // Add video to the contract
    videos[videoCount] = Video(videoCount, _videoHash, _title, payable(msg.sender));
    // Trigger an event
    emit VideoUploaded(videoCount, _videoHash, _title, payable(msg.sender));
  }

  function stream(uint videoId) payable public {
		// require(msg.value >= video.costOfStream, "Insufficient payment.");
		// require(msg.value >= 0.0000000152 ether, "Insufficient payment.");

		(bool success, ) = videos[videoId].author.call{value: 0.0000000152 ether}(""); //todo // check call
    require(success, "Transaction Failed");

		emit PaidForStream(videos[videoId].hash, msg.sender, msg.value);
	}
}