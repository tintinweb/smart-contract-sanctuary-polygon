// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract StorageTest {
    
    struct StrategyParams {
      bool active;
      Type class;
      uint256 allocation;
      uint256 debt;
    }
    enum Type {
      IMMEDIATE,
      DELAYED,
      ABSTRACT
    }
    mapping(address => StrategyParams) public strategyParams;

    function setParams(bool activ, uint256 all, uint256 deb) external {
      strategyParams[msg.sender].active = activ;
      strategyParams[msg.sender].allocation = all;
      strategyParams[msg.sender].debt = deb;
    }
    function setClass(Type c) external {
      strategyParams[msg.sender].class = c;
    }
}