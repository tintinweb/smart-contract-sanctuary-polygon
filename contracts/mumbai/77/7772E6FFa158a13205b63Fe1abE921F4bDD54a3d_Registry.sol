// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./interfaces/IRegistry.sol";

contract Registry is IRegistry {
  address public protocolFeeUnderlying;
  uint256 public storyRegisterFee;
  uint256 public storyAppendFee;
  uint256 public votingDuration;
  mapping(bytes32 => uint256[]) internal profileIdRegistry;
  mapping(bytes32 => uint256[]) internal pubIdRegistry;
  mapping(bytes32 => mapping(uint256 => uint256[])) internal candidatesProfileIds;
  mapping(bytes32 => mapping(uint256 => uint256[])) internal candidatesPubIds;
  bytes32[] allStories;

  event storyRegistered(uint256 indexed profileId, uint256 pubId, bytes32 indexed _hash);
  

  constructor(
    address _protocolFeeUnderlying,
    uint256 _storyRegisterFee,
    uint256 _storyAppendFee,
    uint256 _votingDuration
  ) {
    protocolFeeUnderlying = _protocolFeeUnderlying;
    storyRegisterFee = _storyRegisterFee;
    storyAppendFee = _storyAppendFee;
    votingDuration = _votingDuration;
  }

  function registerStory(StoryItem memory head) external override {
    bytes32 _hash = keccak256(abi.encodePacked(head.profileId, head.pubId));
    uint256[] memory newProfileIdHead = new uint256[](1);
    uint256[] memory newPubIdHead = new uint256[](1);
    newProfileIdHead[0] = head.profileId;
    newPubIdHead[0] = head.pubId;
    profileIdRegistry[_hash] = newProfileIdHead;
    pubIdRegistry[_hash] = newPubIdHead;
    allStories.push(_hash);
    emit storyRegistered(head.profileId, head.pubId, _hash);
  }

  function getStory(StoryItem memory head) external view override returns (StoryItem[] memory) {
    bytes32 _hash = keccak256(abi.encodePacked(head.profileId, head.pubId));
    uint256[] memory profileIds = profileIdRegistry[_hash];
    uint256[] memory pubIds = pubIdRegistry[_hash];
    StoryItem[] memory stories = new StoryItem[](profileIds.length);
    for (uint256 i = 0; i < profileIds.length; i++) {
      stories[i].profileId = profileIds[i];
      stories[i].pubId = pubIds[i];
    }
    return stories;
  }

  function appendStoryItemCandidate(
    StoryItem memory head,
    StoryItem memory tail,
    StoryItem memory candidate
  ) external override {
    bytes32 _hash = keccak256(abi.encodePacked(head.profileId, head.pubId));
    uint256[] memory newProfileIdHead = new uint256[](1);
    uint256[] memory newPubIdHead = new uint256[](1);
    newProfileIdHead[0] = head.profileId;
    newPubIdHead[0] = head.pubId;
    profileIdRegistry[_hash] = newProfileIdHead;
    pubIdRegistry[_hash] = newPubIdHead;
    emit storyRegistered(head.profileId, head.pubId, _hash);
  }

  function voteStoryItemCandidate(StoryItem memory head, StoryItem memory candidate) external override {}

  function getStoryItemCandidateVotes(StoryItem memory candidate) external view override returns (uint256 votes) {
    return 42;
  }

  function listStoryItemCandidates(StoryItem memory head) external override returns (StoryItem[] memory) {
    StoryItem[] memory candidates = new StoryItem[](0);
    return candidates;
  }

  function commitStory(StoryItem memory head) external override {}

  function getStoryVotingDeadline(StoryItem memory head) external view override returns (uint256) {
    return 42;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IRegistry {
  struct StoryItem {
    uint256 profileId;
    uint256 pubId;
  }

  function registerStory(StoryItem memory head) external;

  function getStory(StoryItem memory head) external view returns (StoryItem[] memory);

  function appendStoryItemCandidate(
    StoryItem memory head,
    StoryItem memory tail,
    StoryItem memory candidate
  ) external;

  function voteStoryItemCandidate(StoryItem memory head, StoryItem memory candidate) external;

  function getStoryItemCandidateVotes(StoryItem memory candidate) external view returns (uint256 votes);

  function listStoryItemCandidates(StoryItem memory head) external returns (StoryItem[] memory);

  function commitStory(StoryItem memory head) external;

  function getStoryVotingDeadline(StoryItem memory head) external view returns (uint256);
}