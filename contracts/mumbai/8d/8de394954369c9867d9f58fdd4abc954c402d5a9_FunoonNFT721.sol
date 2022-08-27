// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;

import "./ERC721.sol";

contract FunoonNFT721 is ERC721 {
  uint256 public tokenCounter;
  address public owner;

  struct Sign {
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  constructor(
    string memory name,
    string memory symbol,
    string memory tokenURIPrefix
  ) ERC721(name, symbol) {
    tokenCounter = 1;
    owner = msg.sender;
    _setBaseURI(tokenURIPrefix);
  }

  modifier onlyOwner() {
    require(owner == msg.sender, 'Ownable: caller is not the owner');
    _;
  }

  function ownerTransfership(address newOwner) public onlyOwner returns (bool) {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    owner = newOwner;
    return true;
  }

  function verifySign(string memory tokenURI, Sign memory sign) internal view {
    bytes32 hash = keccak256(abi.encodePacked(this, tokenURI));
    require(
      owner ==
        ecrecover(
          keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', hash)),
          sign.v,
          sign.r,
          sign.s
        ),
      'Owner sign verification failed'
    );
  }

  /**
   * @dev Internal function to mint a new token.
   * Reverts if the given token ID already exists.
   * @param sign struct combination of uint8, bytes32, bytes32 are v, r, s.
   * @param tokenURI string memory URI of the token to be minted.
   * @param fee uint256 royalty of the token to be minted.
   */

  function createCollectible(
    string memory tokenURI,
    uint256 fee,
    Sign memory sign
  ) public returns (uint256) {
    uint256 newItemId = tokenCounter;
    verifySign(tokenURI, sign);
    _safeMint(msg.sender, newItemId, fee);
    _setTokenURI(newItemId, tokenURI);
    tokenCounter = tokenCounter + 1;
    return newItemId;
  }

  function setBaseURI(string memory _baseURI) public onlyOwner {
    _setBaseURI(_baseURI);
  }

  function burn(uint256 tokenId) public {
    require(_exists(tokenId), 'ERC721: nonexistent token');
    _burn(tokenId);
  }
}