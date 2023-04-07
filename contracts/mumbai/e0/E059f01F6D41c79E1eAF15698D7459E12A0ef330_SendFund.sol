// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error Send__TransferFailed();

contract SendFund {
  address payable public receiver;

  event Transfer(address indexed sender, address indexed receiver, uint amount);

  bool locked;

  modifier noReentrancy() {
    require(!locked, "Reentrant call.");
    locked = true;
    _;
    locked = false;
  }

  constructor(address payable _receiver) {
    receiver = _receiver;
  }

  function transfer() public payable noReentrancy {
    require(msg.value > 0, "Value must be greater than 0");
    (bool success, ) = payable(receiver).call{value: msg.value}("");
    if (!success) {
      revert Send__TransferFailed();
    }
    emit Transfer(msg.sender, receiver, msg.value);
  }
}

// 0x5340794F0AE62485F753AbceC1ca5F1a307b3c65