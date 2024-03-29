// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library EngineFlags {
  /// @dev magic value to be used as flag to keep unchanged any current configuration
  /// Strongly assumes that the value `type(uint256).max - 42` will never be used, which seems reasonable
  uint256 public constant KEEP_CURRENT = type(uint256).max - 42;

  /// @dev value to be used as flag for bool value true
  uint256 public constant ENABLED = 1;

  /// @dev value to be used as flag for bool value false
  uint256 public constant DISABLED = 0;

  /// @dev converts flag ENABLED DISABLED to bool
  function toBool(uint256 flag) public pure returns (bool) {
    require(flag == 0 || flag == 1, 'INVALID_CONVERSION_TO_BOOL');
    if (flag == 1) {
      return true;
    } else {
      return false;
    }
  }

  /// @dev converts bool to ENABLED DISABLED flags
  function fromBool(bool isTrue) public pure returns (uint256) {
    if (isTrue) {
      return ENABLED;
    } else {
      return DISABLED;
    }
  }
}