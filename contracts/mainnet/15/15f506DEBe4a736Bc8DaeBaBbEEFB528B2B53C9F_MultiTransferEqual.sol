/**
 *Submitted for verification at polygonscan.com on 2022-10-22
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;



// File: MultiTransferEqual.sol

/// @notice Transfer equal Ether amount to multiple addresses

contract MultiTransferEqual {
  /// @notice Send equal Ether amount to multiple addresses.
  ///  Payable
  /// @param _addresses Array of addresses to send to
  /// @param _amount Amount to send
  function multiTransferEqual_L1R(address payable[] calldata _addresses, uint256 _amount)
  payable external returns(bool)
  {
    // assert(_addresses.length <= 255);
    require(_amount <= msg.value / _addresses.length);
    for (uint8 i; i < _addresses.length; i++) {
      // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
      /*(success, ) = */_addresses[i].call{ value: _amount }("");
      // we do not care. caller should check sending results manually and re-send if needed.
    }
    return true;
  }
}