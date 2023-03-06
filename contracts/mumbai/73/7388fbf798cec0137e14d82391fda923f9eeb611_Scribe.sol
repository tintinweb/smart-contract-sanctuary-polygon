/**
 *Submitted for verification at polygonscan.com on 2023-03-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

error OnlyOwner();
error OnlyReporter();
error SubmitValueFailed();

contract Scribe {
  address public owner;
  mapping(address => bool) public reporters;

  /// @dev Only the owner can call this function.
  modifier onlyOwner() {
    if (msg.sender != owner) revert OnlyOwner();
    _;
  }

  /// @dev Only reporters can call this function.
  modifier onlyReporter() {
    if (reporters[msg.sender] == false) revert OnlyReporter();
    _;
  }

  constructor() {
    owner = address(msg.sender);
    reporters[msg.sender] = true;
  }

  /// @dev Add a reporter to the allowlist.
  function addReporter(address _reporter) external onlyOwner {
    reporters[_reporter] = true;
  }

  /// @dev Remove the reporter from the allowlist.
  function removeReporter(address _reporter) external onlyOwner {
    reporters[_reporter] = false;
  }

  /// @dev Submit a value to a consumer contract.
  function submitValue(
    address _target,
    string memory _selector,
    bytes calldata _data
  ) external onlyReporter {
    (bool success, ) = address(_target).call(
      abi.encodeWithSignature(_selector, _data)
    );
    if (!success) revert SubmitValueFailed();
  }
}