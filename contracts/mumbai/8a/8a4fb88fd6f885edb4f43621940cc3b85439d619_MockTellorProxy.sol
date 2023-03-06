/**
 *Submitted for verification at polygonscan.com on 2023-03-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

error SubmitValueFailed();

contract MockTellorProxy {
  address public scribe;

  constructor(address _scribe) {
    scribe = _scribe;
  }

  modifier onlyScribe() {
    if (msg.sender != scribe)
      revert("MockDestination: Only scribe can call this function");
    _;
  }

  function handleTellorData(bytes calldata _data) external onlyScribe {
    (
      bytes32 _queryId,
      bytes memory _value,
      uint256 _nonce,
      bytes memory _queryData
    ) = abi.decode(_data, (bytes32, bytes, uint256, bytes));

    // Tellor Playground on Mumbai
    (bool success, ) = address(0x3251838bd813fdf6a97D32781e011cce8D225d59).call(
      abi.encodeWithSignature(
        "submitValue(bytes32,bytes,uint256,bytes)",
        _queryId,
        _value,
        _nonce,
        _queryData
      )
    );
    if (!success) revert SubmitValueFailed();
  }
}