// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;

import './ERC1155.sol';

contract FunoonNFT1155 is ERC1155 {
  uint256 newItemId = 1;
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
  ) ERC1155(name, symbol) {
    owner = msg.sender;
    _setTokenURIPrefix(tokenURIPrefix);
  }

  modifier onlyOwner() {
    require(owner == msg.sender, 'Ownable: caller is not the owner');
    _;
  }

  /** @dev change the Ownership from current owner to newOwner address
        @param newOwner : newOwner address */

  function ownerTransfership(address newOwner) public onlyOwner returns (bool) {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    owner = newOwner;
    return true;
  }

  /** @dev verify the tokenURI that should be verified by owner of the contract.
        *requirements: signer must be owner of the contract
        @param tokenURI string memory URI of token to be minted.
        @param sign struct combination of uint8, bytes32, bytes 32 are v, r, s.
        note : sign value must be in the order of v, r, s.

    */

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

  function mint(
    string memory uri,
    uint256 supply,
    uint256 fee,
    Sign memory sign
  ) public {
    verifySign(uri, sign);
    _mint(newItemId, supply, uri, fee);
    newItemId = newItemId + 1;
  }

  function setBaseURI(string memory _baseURI) public onlyOwner {
    _setTokenURIPrefix(_baseURI);
  }

  function burn(uint256 tokenId, uint256 supply) public {
    _burn(msg.sender, tokenId, supply);
  }

  function burnBatch(uint256[] memory tokenIds, uint256[] memory amounts)
    public
  {
    _burnBatch(msg.sender, tokenIds, amounts);
  }
}