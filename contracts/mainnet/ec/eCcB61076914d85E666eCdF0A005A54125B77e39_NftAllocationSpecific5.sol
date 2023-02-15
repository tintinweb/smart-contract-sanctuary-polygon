/**
 *Submitted for verification at polygonscan.com on 2023-02-15
*/

//SPDX-License-Identifier: NONE
pragma solidity 0.8.0;

contract NftAllocationSpecific2 {
  address public immutable trumpCards = 0x24A11e702CD90f034Ea44FaF1e180C0C654AC5d9;
  address public immutable sandLand = 0x9d305a42A3975Ee4c1C57555BeD5919889DCE63F;

  uint256 public baseAllocation = 20 * 1e6 * 1e18; //20M 

  function nftAllocation(address _tokenAddress, uint256 _tokenID) external view returns (uint256) {
    require(_tokenAddress == trumpCards || _tokenAddress == sandLand, "wrong NFT contract");
    return baseAllocation;
  }
}


contract NftAllocationSpecific3 {
  address public immutable lensProtocolProfiles = 0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d;

  uint256 public baseAllocation = 2 * 1e6 * 1e18; //2M 

  function nftAllocation(address _tokenAddress, uint256 _tokenID) external view returns (uint256) {
    require(_tokenAddress == lensProtocolProfiles, "wrong NFT contract");
    return baseAllocation;
  }
}

contract NftAllocationSpecific4 {
  address public immutable polygonApeYC = 0x419e82D502f598Ca63d821D3bBD8dFEFAf9Bbc8D;

  uint256 public baseAllocation = 1500000 * 1e18; //1.5M 

  function nftAllocation(address _tokenAddress, uint256 _tokenID) external view returns (uint256) {
    require(_tokenAddress == polygonApeYC, "wrong NFT contract");
    return baseAllocation;
  }
}

contract NftAllocationSpecific5 {
  address public immutable eggryptoMonsters = 0x42b4A7dB1ED930198bC37971b33e86f19cE88600;

  uint256 public baseAllocation = 2 * 1e6 *1e18; //2M 

  function nftAllocation(address _tokenAddress, uint256 _tokenID) external view returns (uint256) {
    require(_tokenAddress == eggryptoMonsters, "wrong NFT contract");
    return baseAllocation;
  }
}