// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// The Pluck MultiSender
// @author Fredric Bohlin

contract MultiSender {
  event AccountPaid(string _id, address _address, uint256 _amount);
  event BatchPaid(string _id, uint256 _amount);

  function multiSend(
    string memory _id,
    address[] calldata _accounts,
    uint256[] calldata _balances
  ) external payable {
    require(_accounts.length < 200, "Maximum of 200 batch payments exceeded");

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
      emit AccountPaid(_id, _accounts[i], _balances[i]);
    }

    emit BatchPaid(_id, total);
  }

  function sum(uint256[] calldata _data) internal pure returns (uint256) {
    uint256 _sum;
    for (uint256 i; i < _data.length; i++) {
      _sum += _data[i];
    }
    return _sum;
  }
}