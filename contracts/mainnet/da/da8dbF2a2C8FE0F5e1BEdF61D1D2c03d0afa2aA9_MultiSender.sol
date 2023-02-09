// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// The Pluck MultiSender
// @author Fredric Bohlin
// @version 1.0.1

contract MultiSender {
  event AccountPaid(string batchId, string transactionId, address account, uint256 amount);
  event BatchPaid(string batchId, uint256 amount);

  struct Transaction {
    string id;
    address account;
    uint256 amount;
  }

  mapping(string => bool) public paidBatches;

  function multiSend(string memory _id, Transaction[] calldata _transactions) external payable {
    require(!paidBatches[_id], "Batch has already been successfully paid");
    require(_transactions.length < 200, "Maximum of 200 batch payments exceeded");

    uint256 value = msg.value;
    uint256 total = sumOfAmounts(_transactions);
    uint256 totalPaid = 0;

    require(value >= total, "Total amount too low");

    for (uint256 i; i < _transactions.length; i++) {
      require(value >= _transactions[i].amount, "Too low");
      assert(value - _transactions[i].amount >= 0);
      value = value - _transactions[i].amount;
      totalPaid += _transactions[i].amount;
      (bool success, ) = _transactions[i].account.call{value: _transactions[i].amount}("");
      require(success, "Transfer failed.");
      emit AccountPaid(_id, _transactions[i].id, _transactions[i].account, _transactions[i].amount);
    }

    paidBatches[_id] = true;
    emit BatchPaid(_id, totalPaid);
  }

  function sumOfAmounts(Transaction[] calldata _data) internal pure returns (uint256) {
    uint256 _sum;
    for (uint256 i; i < _data.length; i++) {
      _sum += _data[i].amount;
    }
    return _sum;
  }
}