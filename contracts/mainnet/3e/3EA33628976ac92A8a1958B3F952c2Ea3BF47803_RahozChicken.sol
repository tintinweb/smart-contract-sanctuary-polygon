/**
 *Submitted for verification at polygonscan.com on 2022-10-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IPoolStorage {
  function token0() external view returns (IERC20);
  function token1() external view returns (IERC20);
}

contract RahozChicken {
  address public P0;  // 0xaABB8B94a93dc1171CB329DC618391F229eC83Eb
  address public P1; //0xf9cc934753a127100585812181ac04d07158a4c2;
  IERC20 public coreToken;
  uint256 public startTime;
  address public deployer;
  address public winner;

  // user address => ballot number
  mapping(address => uint256) public ballot;
  mapping(address => bool) public canWithdraw;


  constructor(IERC20 _core, address _p0, address _p1) {
    coreToken = _core;
    P0 = _p0;
    P1 = _p1;
    startTime = block.timestamp;
    deployer = msg.sender;
  }

  function bet(uint256 amount) external {
    require(amount < 100e18, 'i am poor');
    require(ballot[msg.sender] == 0, 'already bet');

    coreToken.transferFrom(msg.sender, address(this), amount);
    ballot[msg.sender] = _genRandom() + uint256(msg.sender);
  }

  function release() external {
    if(block.timestamp > startTime + 1 days) {
      uint256 reward = coreToken.balanceOf(address(this));
      coreToken.transfer(winner == address(0) ? deployer : winner, reward);
      return;
    }
    if(ballot[msg.sender] > ballot[winner]) winner = msg.sender;
  }

  function _genRandom() private view returns (uint256) {
    uint256 b0_0 = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270).balanceOf(P0);
    uint256 b0_1 = IERC20(0x3A58a54C066FdC0f2D55FC9C89F0415C92eBf3C4).balanceOf(P0);
    uint256 b1_0 = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174).balanceOf(P1);
    uint256 b1_1 = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F).balanceOf(P1);
    return b0_0 + b0_1 + b1_0 + b1_1 + block.timestamp + address(0).balance;
  }
  
}