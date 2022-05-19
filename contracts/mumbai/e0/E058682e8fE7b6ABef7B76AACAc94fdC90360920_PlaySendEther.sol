pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT


/**

三种发送ETH的方式

1- transfer 2300 gas, reverts
2- send  2300 gas, returns bool,
3- call all ags, return bool and data

 */
contract PlaySendEther {
  constructor() payable {}

  // 回退函数
  receive() external payable {}

  function sendViaTransfer(address payable _to) external payable {
    _to.transfer(1223);
  }

  function sendViaSend(address payable _to) external payable {
    bool sent = _to.send(1223);
    require(sent, "send failed");
  }

  function sendViaCall(address payable _to) external payable {
    (bool success, ) = _to.call{ value: 1223 }("");
    require(success, "call failed");
  }
}

contract EthReceiver {
  event Log(uint256 amount, uint256 gas);

  // gasleft() 返回剩余gas
  receive() external payable {
    emit Log(msg.value, gasleft());
  }
}