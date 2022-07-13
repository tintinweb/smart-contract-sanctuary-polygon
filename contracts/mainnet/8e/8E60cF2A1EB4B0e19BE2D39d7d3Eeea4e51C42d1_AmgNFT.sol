// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "./nf-token-metadata.sol";

 
contract AmgNFT is NFTokenMetadata {
 
  constructor() {
    nftName = "TEST NFT STORE";
    nftSymbol = "TESTSTORE";
  }
 
  function mint(address _to, uint256 _tokenId, string calldata _uri, bool autoApproval, bool copyrightProtection) external onlyOwner {
    if (autoApproval) {
      super._setAutoApprove(_tokenId, true);
    }
    if (copyrightProtection) {
      super._setCopyrightProtection(_tokenId, true);
    }
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }
 
}