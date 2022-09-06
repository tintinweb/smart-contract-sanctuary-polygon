// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract MultiSender {
  event Paid(address _address, uint256 _amount);

  function multiSend(address[] calldata _accounts, uint256[] calldata _balances) external payable {
    uint256 value = msg.value;
    uint256 total = sum(_balances);

    require(value >= total, "Total amount too low");

    uint256 i = 0;
    uint256 x = _accounts.length;

    for (i; i < x; i++) {
      require(value >= _balances[i], "Too low");
      assert(value - _balances[i] >= 0);
      value = value - _balances[i];
      (bool success, ) = _accounts[i].call{value: _balances[i]}("");
      require(success, "Transfer failed.");
      emit Paid(_accounts[i], _balances[i]);
    }
  }

  function sum(uint256[] calldata _data) internal pure returns (uint256) {
    uint256 _sum;
    for (uint256 i; i < _data.length; i++) {
      _sum += _data[i];
    }
    return _sum;
  }
}