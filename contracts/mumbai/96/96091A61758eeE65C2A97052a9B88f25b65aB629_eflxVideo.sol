/**
 *Submitted for verification at polygonscan.com on 2022-02-02
*/

// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.6;

contract eflxVideo {
  uint256 uploadFee;
  address public owner;

  uint public videoCount = 0;
  string public name = "eflxVideo";
  mapping(uint => Video) public videos;

  struct Video {
    uint id;
    string hash;
    string posterhash;
    string title;
    string logline;
    address producer;
  }

  event VideoUploaded(
    uint id,
    string hash,
    string posterhash,
    string title,
    string logline,
    address producer
  );

  modifier onlyOwner() {
         require(msg.sender == owner, "Only you can call the owner.");
        _;
    }

  constructor(address ownerAddress, uint256 _uploadFee) {
     owner = ownerAddress;
     uploadFee = _uploadFee;
  }

  function setuploadFee(uint256 _newuploadFee) public onlyOwner{
    uploadFee = _newuploadFee;
  }

  function uploadVideo(string memory _videoHash, string memory _posterHash, string memory _title, string memory _logline) public payable {
    (bool success,) = owner.call{value: uploadFee}("");
    require(success, "Failed to send money");
    // Make sure the video hash exists
    require(bytes(_videoHash).length > 0);
    // Make sure video poster exists
    require(bytes(_posterHash).length > 0);
    // Make sure video title exists
    require(bytes(_title).length > 0);
    // Make sure video logline exists
    require(bytes(_logline).length > 0);
    // Make sure uploader address exists
    require(msg.sender!=address(0));

    // Increment video id
    videoCount ++;

    // Add video to the contract
    videos[videoCount] = Video(videoCount, _videoHash, _posterHash, _title, _logline, msg.sender);
    // Trigger an event
    emit VideoUploaded(videoCount, _videoHash, _posterHash, _title, _logline, msg.sender);
  }
}