// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
}
contract CryptoBonusMilesBridge {
  address payable private owner;
  IERC20 public token;
  event Airdrop(address indexed to, uint amount);

  constructor(IERC20 _token) {
    owner = payable(msg.sender);
    token = _token;
  }

  receive() payable external {}

  function airdrop(address payable to, uint256 amount) public {
    require(owner == msg.sender);
    token.transfer(to, amount);
    to.transfer(0.01 ether);
    emit Airdrop(to, amount);
  }

  function withdrawToken(IERC20 _token) public {
    require(owner == msg.sender);
    uint amount = _token.balanceOf(address(this));
    require(amount > 0);
    _token.transfer(owner, amount);
  }
  
  function withdraw() public {
    require(owner == msg.sender);
    uint256 ethBalance = address(this).balance;
    owner.transfer(ethBalance);
  }

  function transferOwnership(address payable newOwner) public {
    require(owner == msg.sender);
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}