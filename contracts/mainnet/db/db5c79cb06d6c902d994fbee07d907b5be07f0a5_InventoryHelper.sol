// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC721.sol";
import "./OperatorRole.sol";

contract InventoryHelper is OperatorRole {
  error allowlistOnly();

  mapping(address => bool) private allowlistCollection;
  mapping(address => bool) private allowlist;

  function batchTransferERC721(
    address collection,
    address to,
    uint256[] calldata tokenIds
  ) external {
    if (allowlistCollection[collection] && !allowlist[msg.sender])
      revert allowlistOnly();

    for (uint256 i; i < tokenIds.length; i++) {
      IERC721(collection).safeTransferFrom(msg.sender, to, tokenIds[i]);
    }
  }

  function flipAllowlist(
    address collection,
    address[] calldata users,
    bool isCollectionAllowed,
    bool isUserAllowed
  ) external onlyOperator {
    allowlistCollection[collection] = isCollectionAllowed;
    for (uint8 i; i < users.length; i++) {
      allowlist[users[i]] = isUserAllowed;
    }
  }
}