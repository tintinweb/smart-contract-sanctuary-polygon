// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC1155.sol";

contract FracDeal is ERC1155 {

  address private _owner;

  constructor() public ERC1155("https://emote.one/assets/properties/{id}.json"){
    _owner = msg.sender;
  }

  function whoOwnsFracDeal() public view returns (address) {
    return _owner;
  }

  function mintCustom(uint256 id, uint256 amount, bytes memory data) public {
    require(_owner == msg.sender, "Only FracDeal owner has the authority to mint new assets");
    /**
     * All minted assets will be deposited into _owner
     * _owner will later distribute assets across recipients
     */
     _mint(msg.sender, id, amount, data);
  }
}