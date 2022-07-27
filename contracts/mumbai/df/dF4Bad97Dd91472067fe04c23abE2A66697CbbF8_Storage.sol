pragma solidity ^0.8.4;

contract Storage {
  string public data;

  function setData(string calldata _data) external {
    data = _data;
  }
}