// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./SafeERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

contract TransferHelper {
  using SafeERC20 for IERC20;

  error TransferFailed();

  function nativeMultipleTransfer(
    address[] calldata tos,
    uint256[] calldata amounts
  ) external payable {
    for (uint256 i; i < amounts.length; i++) {
      (bool os, ) = payable(tos[i]).call{ value: amounts[i] }("");
      if (!os) revert TransferFailed();
    }
  }

  function erc20MultipleTransfer(
    address collection,
    address[] calldata tos,
    uint256[] calldata amounts
  ) external {
    for (uint256 i; i < amounts.length; i++) {
      IERC20(collection).safeTransferFrom(msg.sender, tos[i], amounts[i]);
    }
  }

  function erc721BatchTransfer(
    address collection,
    address to,
    uint256[] calldata tokenIds
  ) external {
    for (uint256 i; i < tokenIds.length; i++) {
      IERC721(collection).safeTransferFrom(msg.sender, to, tokenIds[i], "");
    }
  }

  function erc721MultipleTransfer(
    address collection,
    address[] calldata tos,
    uint256[] calldata tokenIds
  ) external {
    for (uint256 i; i < tokenIds.length; i++) {
      IERC721(collection).safeTransferFrom(msg.sender, tos[i], tokenIds[i], "");
    }
  }

  function erc1155BatchTransfer(
    address collection,
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts
  ) external {
    IERC1155(collection).safeBatchTransferFrom(
      msg.sender,
      to,
      tokenIds,
      amounts,
      ""
    );
  }

  function erc1155MultipleTransfer(
    address collection,
    address[] calldata tos,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts
  ) external {
    for (uint256 i; i < tokenIds.length; i++) {
      IERC1155(collection).safeTransferFrom(
        msg.sender,
        tos[i],
        tokenIds[i],
        amounts[i],
        ""
      );
    }
  }
}