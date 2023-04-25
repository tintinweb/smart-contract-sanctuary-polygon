// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/// @dev Timestamp of the first Saturday evening in seconds since the Unix Epoch. It's used to align
/// the allowed drawing windows with Saturday evenings.
uint constant FIRST_SATURDAY_EVENING = 244800;

/// @dev Width of the drawing window.
uint constant DRAWING_WINDOW_WIDTH = 4 hours;


library Drawing {
  /// @dev Floors the current timestamp to the last time a drawing window started. Note that the
  ///   drawing window may not have elapsed yet. The returned value is independent of whether or not
  ///   a draw has been triggered.
  function getCurrentDrawingWindow() public view returns (uint) {
    return FIRST_SATURDAY_EVENING + (block.timestamp - FIRST_SATURDAY_EVENING) / 7 days * 7 days;
  }

  /// @return True iff a drawing window is ongoing.
  function insideDrawingWindow() public view returns (bool) {
    return block.timestamp < getCurrentDrawingWindow() + DRAWING_WINDOW_WIDTH;
  }

  function _ceil(uint time, uint window) private pure returns (uint) {
    return (time + window - 1) / window * window;
  }

  /// @dev Ceils the current timestamp to the next time a drawing window starts. The returned value
  ///   is independent of whether or not a drawing window is ongoing or a draw has been triggered.
  function getNextDrawingWindow() public view returns (uint) {
    return FIRST_SATURDAY_EVENING + _ceil(block.timestamp - FIRST_SATURDAY_EVENING, 7 days);
  }

  /// @dev Takes a 256-bit random word provided by the ChainLink VRF and extracts 6 different random
  ///   numbers in the range [1, 90] from it. The implementation uses a modified version of the
  ///   Fisher-Yates shuffle algorithm.
  function getRandomNumbersWithoutRepetitions(uint256 randomness)
      public pure returns (uint8[6] memory numbers)
  {
    uint8[90] memory source;
    for (uint8 i = 1; i <= 90; i++) {
      source[i - 1] = i;
    }
    for (uint i = 0; i < 6; i++) {
      uint j = i + randomness % (90 - i);
      randomness /= 90;
      numbers[i] = source[j];
      source[j] = source[i];
    }
  }
}