// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Burner {
  address burnable;

  function setBurnable(address burnable_) external {
    burnable = burnable_;
  }

  function burn(uint256 tokenId) external returns (bytes memory) {
    (bool success, bytes memory r) = burnable.call(
      abi.encodeWithSignature('burn(uint256)', tokenId)
    );

    if (!success) {
      revert('failed burn');
    }

    return r;
  }
}