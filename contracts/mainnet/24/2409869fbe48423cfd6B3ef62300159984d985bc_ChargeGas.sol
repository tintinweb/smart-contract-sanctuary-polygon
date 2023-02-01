// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Pellar & LightLink 2022

contract ChargeGas {
  function getAccountsNeedCharge(address[] memory _accounts, uint256 _amount) public view returns (bool[] memory) {
    uint256 size = _accounts.length;
    bool[] memory accountsNeedCharge = new bool[](size);
    for (uint256 i = 0; i < _accounts.length; i++) {
      accountsNeedCharge[i] = _accounts[i].balance < _amount;
    }
    return accountsNeedCharge;
  }

  function chargeAccounts(address[] memory _accounts, uint256 _amount) public payable {
    require(msg.value == _amount * _accounts.length, "ChargeGas: insufficient funds");
    for (uint256 i = 0; i < _accounts.length; i++) {
      payable(_accounts[i]).transfer(_amount);
    }
  }
}