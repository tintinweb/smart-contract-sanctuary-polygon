// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TaniKUD{

  address payable owner;

  constructor(){
    owner = payable(msg.sender);
  }

  event Buy(
    address from,
    uint256 amount
  );

  function newPayment() public payable{
    (bool success,) = owner.call{value: msg.value}("");
    require(success, "Failed to pay");
    emit Buy(
      msg.sender,
      msg.value / 1000000000000000000
    );
  }

}