// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Coba{

  mapping (address => uint) public balances;

  address payable owner;

  constructor(){
    owner = payable(msg.sender);
  }

  event Buy(
    address from,
    address to,
    uint256 amount
  );

  function newPayment(address _to) public payable{
    (bool success,) = _to.call{value: msg.value}("");
    require(success, "Failed to pay");
    emit Buy(
      msg.sender,
      _to,
      msg.value / 1000000000000000000
    );
  }

}