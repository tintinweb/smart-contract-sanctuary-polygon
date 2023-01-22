/**
 *Submitted for verification at polygonscan.com on 2023-01-22
*/

// SPDX-License-Identifier: Apache2.0
pragma solidity 0.8.4;

/// This is the DAO Treasury smart contract
/// The funds in this contract can only be moved through governance vote
contract Foundation {
  address public admin;  
  event received(address indexed from, uint256 amount);
  event fundSuccess(address indexed payee, uint256 amount);
  event fundFailed(address indexed payee, uint256 amount, uint256 balance);

  receive() external payable {
    if (msg.value != 0) {
      emit received(msg.sender, msg.value);
    }
  }

  constructor() {
      admin = msg.sender;
  }

  /// Send funds to a specific address with specific amount
  /// @param payee The address to send funds to
  /// @param amount The amount of funds to send
  function fund(address payable payee, uint256 amount) external {
    require(msg.sender == admin, "invalid caller");  
    require(payee != address(0), "payee address should not be zero");
    bool ret = payee.send(amount);
    if (ret) {
      emit fundSuccess(payee, amount);
    } else {
      emit fundFailed(payee, amount, address(this).balance);
    }
  }
}