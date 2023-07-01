pragma solidity ^0.8.6;

import '../interfaces/ISnapshotStore.sol';

contract SnapshotStore is ISnapshotStore {
  uint256 private nextPartIndex = 1;
  mapping(uint256 => Snapshot) private partsList;
  mapping(uint256 => uint256) private tokenIdToSnapshot;
  mapping(uint256 => uint256) private tokenIdToVp;

  function register(Snapshot memory _snapshot) external returns (uint256) {
    partsList[nextPartIndex] = _snapshot;
    nextPartIndex++;
    return nextPartIndex - 1;
  }

  function currentBlockNumber() external view returns (uint256) {
    return partsList[nextPartIndex - 1].end;
  }

  function setSnapshot(uint256 tokenId, uint256 snapshotId, uint256 vp) external {
    tokenIdToSnapshot[tokenId] = snapshotId;
    tokenIdToVp[tokenId] = vp;
  }

  function getSnapshot(uint256 index) external view returns (Snapshot memory output){
    output = partsList[tokenIdToSnapshot[index]];
  }

  function getTitle(uint256 index) external view returns (string memory output) {
    output = partsList[tokenIdToSnapshot[index]].title;
  }

  function getVp(uint256 index) external view returns (uint256 vp) {
    vp = tokenIdToVp[index];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface ISnapshotStore {
  struct Snapshot {
    string id;
    string title;
    string choices;
    string scores;
    uint256 start;
    uint256 end;
  }

  function register(Snapshot memory snapshot) external returns (uint256);

  function currentBlockNumber() external returns (uint256);

  function setSnapshot(uint256 tokenId, uint256 snapshotId, uint256 vp) external;

  function getSnapshot(uint256 index) external view returns (Snapshot memory output);

  function getTitle(uint256 index) external view returns (string memory output);

  function getVp(uint256 index) external view returns (uint256 vp);
}