// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";

contract SeretanERC721 is ERC721Enumerable {
  string private baseURI;

  struct Phase {
    uint256 startTime;
    bytes32 allowlistRoot;
    uint256 maxTotalSupply;
    uint256 maxTotalSupplyOfOne;
  }
  Phase[] private phaseList;

  mapping(address => uint256) private totalSupplyOf;

  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseURI_,
    Phase[] memory phaseList_
  )
    ERC721(name_, symbol_)
  {
    baseURI = baseURI_;

    for (uint256 i = 0; i < phaseList_.length; i++) {
      phaseList.push(phaseList_[i]);
    }
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function _safeMint(
    address to,
    uint256 tokenId
  )
    internal
    override
  {
    totalSupplyOf[to]++;
    super._safeMint(to, tokenId);
  }

  function safeMintOne(
    address to,
    uint256 currentPhaseNumber,
    bytes32[] calldata allowlistProof
  )
    public
  {
    require(0 <= currentPhaseNumber && currentPhaseNumber < phaseList.length, "Invalid currentPhaseNumber");
    require(phaseList[currentPhaseNumber].startTime <= block.timestamp, "Invalid currentPhaseNumber");
    require(currentPhaseNumber+1 == phaseList.length || phaseList[currentPhaseNumber+1].startTime > block.timestamp, "Invalid currentPhaseNumber");

    if (phaseList[currentPhaseNumber].allowlistRoot != 0) {
      bytes32 allowlistLeaf = keccak256(bytes.concat(keccak256(abi.encode(to))));
      require(MerkleProof.verify(allowlistProof, phaseList[currentPhaseNumber].allowlistRoot, allowlistLeaf), "Not listed on allowlist");
    }

    require(phaseList[currentPhaseNumber].maxTotalSupply > totalSupply(), "Unable to mint anymore");

    require(phaseList[currentPhaseNumber].maxTotalSupplyOfOne > totalSupplyOf[to], "Unable to mint anymore");

    uint256 tokenId = totalSupply();
    _safeMint(to, tokenId);
  }
}