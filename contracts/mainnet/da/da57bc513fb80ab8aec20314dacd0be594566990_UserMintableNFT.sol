/**
 * This is enhancement over custom NFT allowing users to mint tokens approved by admin
 * This contract will be used as enhanced version of NFT (v2)
*/

pragma solidity 0.5.17;

import "./CustomERC721.sol";

contract UserMintableNFT is CustomERC721 {

  mapping(address => mapping(uint => bool)) isNonceUsed;

  constructor(string memory name, string memory symbol, string memory baseURI) public CustomERC721(name, symbol, baseURI)
  {

  }

  /**
   * @dev Allows anyone to mint token signed by admin
   * Reverts if admin has not signed for `tokenId` or `to`
   * @param r signature
   * @param s signature
   * @param v recovery id of signature
   * @param tokenId tokenId to be minted
   * @param to address to which tokens needs to be minted
   * @param _signerNonce non-sequential nonce of signer to avoid replay protection
   * @return bool true when operation is successful

   */
  function userMint(
    bytes32 r, bytes32 s, uint8 v,
    uint256 tokenId,
    address to,
    uint256 _signerNonce
  )
    public
    noEmergencyFreeze
    returns (bool)
  {
    
    bytes32 message = keccak256(abi.encodePacked(
      bytes4(0x8cd49589), // Keccak-256 hash of "userMint"
      address(this),
      _signerNonce,
      to,
      tokenId
    ));
    address signer = getSigner(message, r, s, v);
    require(signer == owner || isDeputyOwner[signer], "Admin should sign message");
    require(isNonceUsed[signer][_signerNonce], "nonce already used");
    super._mint(to, tokenId);
    isNonceUsed[signer][_signerNonce] = true;
    return true;
  }

  /**
   * @dev Allows anyone to mint tokens signed by admin
   * Reverts if admin has not signed for `tokenIds` or `to`
   * @param r signature
   * @param s signature
   * @param v recovery id of signature
   * @param tokenIds tokenIds to be minted
   * @param to address to which tokens needs to be minted
   * @param _signerNonce non-sequential nonce of signer to avoid replay protection
   * @return bool true when operation is successful
   */
  function userBulkMint(
    bytes32 r, bytes32 s, uint8 v,
    uint256[] memory tokenIds,
    address to,
    uint256 _signerNonce
  )
    public
    noEmergencyFreeze
    returns (bool)
  {
    bytes32 message = keccak256(abi.encodePacked(
      bytes4(0x5827c1ff), // Keccak-256 hash of "userBulkMint"
      address(this),
      _signerNonce,
      to,
      tokenIds
    ));
    address signer = getSigner(message, r, s, v);
    require(signer == owner || isDeputyOwner[signer], "Admin should sign message");
    require(isNonceUsed[signer][_signerNonce], "nonce already used");
    for(uint256 i=0; i<tokenIds.length; i++) {
      super._mint(to, tokenIds[i]);
    }
    isNonceUsed[signer][_signerNonce] = true;
    return true;
  }
  
}