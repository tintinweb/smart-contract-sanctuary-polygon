// SPDX-License-Identifier: MIT
// Content trademark cyberskies.io

pragma solidity ^0.8.7;

import "erc1155.sol";
import "ownable.sol";

/**
 * @title Cyberskies Medals
 * @notice ERC1155 Contract for cyberskies.io
 */
contract CSMDL is ERC1155, Ownable {
    
  string public name;
  string public symbol;
  mapping(uint => string) public tokenURI;
  uint256 internal supply = 0;
  
  constructor() ERC1155("") {
    name = "Cyberskies Medals";
    symbol = "CSMDL";
  }

  function Mint(uint _id,address _to,uint _quantity) public onlyOwner {
    _mint(_to, _id, _quantity, "");
  }

  function BatchMint(uint _id,address[] memory _to,uint _quantity) public onlyOwner {
      for(uint i = 0 ; i < _to.length;i++){
        _mint(_to[i], _id, _quantity, "");
      }
  }

  function setURI(uint _id, string memory _uri) public onlyOwner {
    tokenURI[_id] = _uri;
    emit URI(_uri, _id);
  }

  function uri(uint _id) public override view returns (string memory) {
    return tokenURI[_id];
  }
}