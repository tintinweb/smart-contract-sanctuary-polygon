/**
 *Submitted for verification at polygonscan.com on 2022-10-29
*/

pragma solidity ^0.4.18;

contract MATIC {
  function transfer(address _recipient, uint256 _value) public returns (bool success);
}

contract Airdrop {
  function drop(MATIC token, address[] recipients, uint256[] values) public {
    for (uint256 i = 0; i < recipients.length; i++) {
      token.transfer(recipients[i], values[i]);
    }
  }
}