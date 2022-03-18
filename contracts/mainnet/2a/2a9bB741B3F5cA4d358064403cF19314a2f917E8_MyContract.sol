pragma solidity ^0.8.0;

contract MyContract {
  mapping(uint256 => uint256) public orders;
  address public admin;

  constructor() {
    admin = msg.sender;
  }

  function setOrder(uint256 i, uint256 j) public {
    orders[i] = j;
  }
}