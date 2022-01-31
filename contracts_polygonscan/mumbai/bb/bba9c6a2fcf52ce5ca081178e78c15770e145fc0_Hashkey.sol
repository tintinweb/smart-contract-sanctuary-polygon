// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC1155.sol";
import "./Freezable.sol";
import "./Describable.sol";
import "./Strings.sol";

contract Hashkey is
  ERC1155,
  Freezable,
  Describable
{

  constructor(string memory description, string memory uri_) ERC1155(uri_) public {
    _setupDescription(description);
  }

  function mint(address to, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
    super._mint(to, id, amount, data);
  }

  function mintBatch(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _quantities,
    bytes memory _data
  ) public onlyOwner {
    super._mintBatch(_to, _ids, _quantities, _data);
  }

  function _beforeTokenTransfer(
      address operator,
      address from,
      address to,
      uint256[] memory ids,
      uint256[] memory amounts,
      bytes memory data
  ) internal override whenTransfer(from, to) {}

  function uri(uint256 _tokenId) public view override returns (string memory) {
    return Strings.strConcat(
        super.uri(_tokenId),
        Strings.uint2str(_tokenId),
	".json"
    );
  }

}