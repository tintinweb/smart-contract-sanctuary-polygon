// SPDX-License-Identifier: MIT
// Derby Finance - 2022
pragma solidity ^0.8.11;

contract XChainControllerTestMock {
  uint32[] public chainIds;
  address private dao;

  struct vaultInfo {
    int256 totalCurrentAllocation;
    mapping(uint32 => int256) currentAllocationPerChain;
  }

  // (vaultNumber => vaultInfo struct)
  mapping(uint256 => vaultInfo) internal vaults;

  modifier onlyDao() {
    require(msg.sender == dao, "xController: only DAO");
    _;
  }

  constructor() {
    dao = msg.sender;
  }

  function receiveAllocationsFromGame(uint256 _vaultNumber, int256[] memory _deltas) external {
    for (uint256 i = 0; i < chainIds.length; i++) {
      uint32 chain = chainIds[i];
      vaults[_vaultNumber].totalCurrentAllocation += _deltas[i];
      vaults[_vaultNumber].currentAllocationPerChain[chain] += _deltas[i];
    }
  }

  function getCurrentTotalAllocation(uint256 _vaultNumber) public view returns (int256) {
    return vaults[_vaultNumber].totalCurrentAllocation;
  }

  function getCurrentAllocation(
    uint256 _vaultNumber,
    uint32 _chainId
  ) public view returns (int256) {
    return vaults[_vaultNumber].currentAllocationPerChain[_chainId];
  }

  function setChainIds(uint32[] memory _chainIds) external onlyDao {
    chainIds = _chainIds;
  }
}