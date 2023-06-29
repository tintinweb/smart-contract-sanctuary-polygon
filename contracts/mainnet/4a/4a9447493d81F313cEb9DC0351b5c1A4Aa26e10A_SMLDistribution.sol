/**
 *Submitted for verification at polygonscan.com on 2023-06-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20 {
  function transfer(address to, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract SMLDistribution {
  IERC20 public smlToken;
  address public owner;

  constructor() {
    owner = msg.sender;
  }

  function setSmlToken(address _smlToken) external returns (bool) {
    require(owner == msg.sender, "not owner");
    smlToken = IERC20(_smlToken);
    return true;
  }

  function distribute(address[] memory _addresses, uint256[] memory _amounts) external returns (bool) {
    require(owner == msg.sender, "not owner");
    for (uint256 i = 0; i < _addresses.length; i++) {
      smlToken.transferFrom(msg.sender, _addresses[i], _amounts[i]);
    }
    return true;
  }
}