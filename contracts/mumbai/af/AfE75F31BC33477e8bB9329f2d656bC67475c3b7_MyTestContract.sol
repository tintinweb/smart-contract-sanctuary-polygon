// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MyTestContract {
  uint32 private _counter;

  event ORDER(uint256 orderId, uint256 nftId, uint256 price, address seller, uint256 timeStamp);
  event BUYMARKETITEM(uint256 orderId, uint256 nftId, uint256 price, address seller, address buyer, uint256 transactionFee, uint256 timeStamp);
  event CANCELORDER(uint256 orderId, uint256 nftId, uint256 price, address seller, uint256 timeStamp);

  function emitOrder() external {
    _counter++;
    emit ORDER(1, 1, 1, msg.sender, block.timestamp);
  }

  function emitBuy() external {
    _counter++;
    emit BUYMARKETITEM(1, 1, 1, msg.sender, msg.sender, 1, block.timestamp);
  }

  function emitCancel() external {
    _counter++;
    emit CANCELORDER(1, 1, 1, msg.sender, block.timestamp);
  }
}