// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error NotOwner();

interface USDC {
  function balanceOf(address account) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract DemoContract {
  USDC public usdcContractObject;

  address payable public owner;

  constructor() {
    usdcContractObject = USDC(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    owner = payable(msg.sender);
  }

  function deposit(uint256 _amount) external {
    usdcContractObject.transferFrom(msg.sender, address(this), _amount);
  }

  function withdraw(uint256 _amount) external onlyOwner {
    usdcContractObject.transfer(owner, _amount);
  }

  function getBalance() external view returns (uint256) {
    return usdcContractObject.balanceOf(address(this));
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert NotOwner();
    }
    _;
  }
}