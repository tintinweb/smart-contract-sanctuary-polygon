/**
 *Submitted for verification at polygonscan.com on 2023-05-12
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

contract OwnestPolygonAirdrop {
  function drop(address[] memory _recipients, uint256[] memory _values) payable public {
    require(
      _recipients.length == _values.length,
      "Arrays must have the same length"
    );
    uint256 total = 0;
    for (uint256 i = 0; i < _values.length; i++) {
      total += _values[i];
    }
    require(msg.value == total, "Incorrect matic value.");
    for (uint256 i = 0; i < _recipients.length; i++) {
      payable(_recipients[i]).transfer(_values[i]);
    }
  }
}