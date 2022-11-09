/**
 *Submitted for verification at polygonscan.com on 2022-11-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @author @sudosuberenu
/// @title Course 1 - Faucet - Final Challange
contract Challenge {
  address public winner;

  constructor() {}

  modifier checkWinner {
    require(winner == address(0), "We already have a winner");
    _;
  }

  modifier setWinner {
    _;
    revert();
  }

  modifier onlyOwner {
    winner = msg.sender;
    _;
  }

  function mint3(uint256 number) external checkWinner setWinner {
    if (number > 2) {
      winner = msg.sender;
    }    
  }

  function mint1(address _winner) external checkWinner setWinner {
    if (_winner == address(0)) {
      winner = msg.sender;
    } 
  }

  function mint2(uint256 number) external checkWinner onlyOwner returns (bool) {
    if (number >= 2) {
      return true;
    }
    return false;
  }
}