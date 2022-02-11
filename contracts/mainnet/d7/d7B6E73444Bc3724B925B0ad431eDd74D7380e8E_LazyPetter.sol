// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface AavegotchiFacet {
  function tokenIdsOfOwner(address _owner) external view returns (uint32[] memory tokenIds_);
}

interface AavegotchiGameFacet {
  function interact(uint256[] calldata _tokenIds) external;
}

contract LazyPetter {
  uint256 public lastExecuted;
  address private gotchiOwner;
  AavegotchiFacet private af;
  AavegotchiGameFacet private agf;

  constructor(address gotchiDiamond, address _gotchiOwner) {
    af = AavegotchiFacet(gotchiDiamond);
    agf = AavegotchiGameFacet(gotchiDiamond);
    gotchiOwner = _gotchiOwner;
  }

  function petGotchis() external{
    require(
      ((block.timestamp - lastExecuted) > 43200),
      "LazyPetter: pet: 12 hours not elapsed"
    );

    uint32[] memory gotchis = af.tokenIdsOfOwner(gotchiOwner);
    uint256[] memory gotchiIds = new uint256[](gotchis.length);
    for (uint i = 0; i < gotchis.length; i++) {
      gotchiIds[i] = uint256(gotchis[i]);
    }
    agf.interact(gotchiIds);

    lastExecuted = block.timestamp;
  }
}