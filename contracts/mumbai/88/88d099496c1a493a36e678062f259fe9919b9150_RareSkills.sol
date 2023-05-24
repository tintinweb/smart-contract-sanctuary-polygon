/**
 *Submitted for verification at polygonscan.com on 2023-05-23
*/

pragma solidity 0.8.7;

contract RareSkills {
  mapping(address => uint256) public balances;
  uint256 public totalSupply;

  event Mint(address indexed to, uint256 amount);

  function mint(uint256 amount) external {
    balances[msg.sender] += amount;
    totalSupply += amount;
    emit Mint(msg.sender, amount);
  }
}