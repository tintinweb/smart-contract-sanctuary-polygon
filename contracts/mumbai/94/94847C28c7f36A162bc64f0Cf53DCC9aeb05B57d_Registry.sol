// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./interfaces/IRegistry.sol";

contract Registry is IRegistry {
  address public protocolFeeUnderlying;
  uint256 public storyRegisterFee;
  uint256 public storyAppendFee;
  uint256 public votingDuration;
  bytes32[] public allStories;
  mapping(bytes32 => uint256[]) internal profileIdRegistry;
  mapping(bytes32 => uint256[]) internal pubIdRegistry;
  mapping(bytes32 => mapping(uint256 => uint256[])) internal candidatesProfileIds;
  mapping(bytes32 => mapping(uint256 => uint256[])) internal candidatesPubIds;
  mapping(bytes32 => mapping(uint256 => mapping(bytes32 => uint256))) votes;

  event storyRegistered(uint256 indexed profileId, uint256 pubId, bytes32 indexed _hash);
  event candidateRegistered(uint256 indexed headProfileId, uint256 headPubId, uint256 index, bytes32 indexed headHash, uint256 profileId, uint256 pubId);

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

  function getStory(StoryItem memory head) public view override returns (StoryItem[] memory) {
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

  function getStoryByHash(bytes32 _hash) external view override returns (StoryItem[] memory) {
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
    uint256 index,
    StoryItem memory candidate
  ) external override {
    bytes32 _hash = keccak256(abi.encodePacked(head.profileId, head.pubId));
    candidatesProfileIds[_hash][index].push(candidate.profileId);
    candidatesPubIds[_hash][index].push(candidate.pubId);
    emit candidateRegistered(head.profileId, head.pubId, index, _hash, candidate.profileId, candidate.pubId);
  }

  function listStoryItemCandidates(StoryItem memory head, uint256 index) public view override returns (StoryItem[] memory) {
    bytes32 _hash = keccak256(abi.encodePacked(head.profileId, head.pubId));
    uint256[] memory profileIds = candidatesProfileIds[_hash][index];
    uint256[] memory pubIds = candidatesPubIds[_hash][index];

    StoryItem[] memory candidates = new StoryItem[](profileIds.length);
    for (uint256 i = 0; i < profileIds.length; i++) {
      candidates[i].profileId = profileIds[i];
      candidates[i].pubId = pubIds[i];
    }

    return candidates;
  }

  function voteStoryItemCandidate(StoryItem memory head, uint256 index, StoryItem memory candidate) external override {
    bytes32 _headHash = keccak256(abi.encodePacked(head.profileId, head.pubId));
    bytes32 _candidateHash = keccak256(abi.encodePacked(candidate.profileId, candidate.pubId));
    votes[_headHash][index][_candidateHash] += 1;

  }

  function getStoryItemCandidateVotes(StoryItem memory head, uint256 index, StoryItem memory candidate) public view override returns (uint256) {
    bytes32 _headHash = keccak256(abi.encodePacked(head.profileId, head.pubId));
    bytes32 _candidateHash = keccak256(abi.encodePacked(candidate.profileId, candidate.pubId));
    return votes[_headHash][index][_candidateHash];
  }


  function commitStory(StoryItem memory head) external override {
    StoryItem[] memory story = getStory(head);
    StoryItem[] memory candidates = listStoryItemCandidates(head, story.length - 1);
    if (candidates.length > 0) {
      uint256 firstVoteCount = getStoryItemCandidateVotes(head, story.length, candidates[0]);
      uint256 maxIndex = 0;
      uint256 maxVotes = firstVoteCount;
      for (uint256 i = 1; i < candidates.length; i++) {
        uint256 voteCount = getStoryItemCandidateVotes(head, story.length, candidates[i]);
        if (voteCount > maxVotes) {
          maxIndex = i;
        }
      }
      bytes32 _hash = keccak256(abi.encodePacked(head.profileId, head.pubId));
      profileIdRegistry[_hash].push(candidates[maxIndex].profileId);
      pubIdRegistry[_hash].push(candidates[maxIndex].pubId);
    }
  }

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

  function getStoryByHash(bytes32 _hash) external view returns (StoryItem[] memory);

  function appendStoryItemCandidate(
    StoryItem memory head,
    uint256 index,
    StoryItem memory candidate
  ) external;

  function voteStoryItemCandidate(StoryItem memory head, uint256 index, StoryItem memory candidate) external;

  function getStoryItemCandidateVotes(StoryItem memory head, uint256 index, StoryItem memory candidate) external view returns (uint256);

  function listStoryItemCandidates(StoryItem memory head, uint256 index) external view returns (StoryItem[] memory);

  function commitStory(StoryItem memory head) external;

  function getStoryVotingDeadline(StoryItem memory head) external view returns (uint256);
}