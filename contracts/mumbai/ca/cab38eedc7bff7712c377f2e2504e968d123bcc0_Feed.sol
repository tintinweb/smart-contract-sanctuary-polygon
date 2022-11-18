/**
 *Submitted for verification at polygonscan.com on 2022-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
abstract contract ReentrancyGuard {
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;
  uint256 private _status;
  constructor() {
    _status = _NOT_ENTERED;
  }
  modifier nonReentrant() {
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
    _status = _ENTERED;
    _;
    _status = _NOT_ENTERED;
  }
}
interface IERC1155 {
  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
interface IERC1155Receiver {
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);
}
contract Feed is IERC1155Receiver, ReentrancyGuard {

  address public foodContract;
  address public owner;
  string public name = "Feed";
  string public symbol = "FM";

  event _1155Received();

  constructor() {
    owner = msg.sender;
  }

  event _feedMaru(address _address, uint256[] _id);
  
  modifier onlyOwner() {
    require(msg.sender == owner, "x");
    _;
  }

  function setFoodContract (address _address) external onlyOwner{
    foodContract = _address;
  }

  function feedMaru(uint256[] memory _id) public nonReentrant{
    require(_id.length <= 5, "max limit reached");
    for (uint256 i = 0; i < _id.length; i++) {
      IERC1155(foodContract).safeTransferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, _id[i], 1, "");
    }
    emit _feedMaru(msg.sender, _id);
  }

  function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external virtual override returns (bytes4) {
    operator;
    from;
    id;
    value;
    data;
    emit _1155Received();
    return this.onERC1155Received.selector;
  }

}