/**
 *Submitted for verification at polygonscan.com on 2022-08-16
*/

// SPDX-License-Identifier: MIT

// File: contracts/bulkminter.sol

pragma solidity >=0.7.0 <0.9.0;

interface IERC1155 {
  function safeTransferFrom( address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

contract BulkAirdrop {
  function bulkAirdropERC1155(IERC1155 _token, address[] calldata _to, uint256 _id, uint256 _amount) public {
    for (uint256 i = 0; i < _to.length; i++) {
      _token.safeTransferFrom(msg.sender, _to[i], _id, _amount, "");
    }
  }
}