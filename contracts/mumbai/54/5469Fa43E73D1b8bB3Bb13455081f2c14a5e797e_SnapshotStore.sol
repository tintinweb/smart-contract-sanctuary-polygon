pragma solidity ^0.8.6;

import '../interfaces/ISnapshotStore.sol';

contract SnapshotStore is ISnapshotStore {
  uint256 private nextPartIndex = 1;
  mapping(uint256 => Snapshot) private partsList;
  mapping(uint256 => uint256) private tokenIdToSnapshot;

  function register(Snapshot memory _snapshot) external returns (uint256) {
    partsList[nextPartIndex] = _snapshot;
    nextPartIndex++;
    return nextPartIndex - 1;
  }

  function currentBlockNumber() external view returns (uint256) {
    return partsList[nextPartIndex - 1].end;
  }

  function setSnapshot(uint256 tokenId, uint256 snapshotId) external {
    tokenIdToSnapshot[tokenId] = snapshotId;
  }

  function getTitle(uint256 index) external view returns (string memory output) {
    output = partsList[tokenIdToSnapshot[index]].title;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface ISnapshotStore {
  struct Snapshot {
    string id;
    string title;
    uint256 start;
    uint256 end;
  }
  struct Box {
    uint256 w;
    uint256 h;
  }

  function register(Snapshot memory snapshot) external returns (uint256);

  function currentBlockNumber() external returns (uint256);

  function setSnapshot(uint256 tokenId, uint256 snapshotId) external;

  function getTitle(uint256 index) external view returns (string memory output);
}