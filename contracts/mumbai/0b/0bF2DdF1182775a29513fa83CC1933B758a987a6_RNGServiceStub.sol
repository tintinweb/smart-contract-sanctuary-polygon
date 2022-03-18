pragma solidity ^0.8.6;

import "../RNGInterface.sol";

contract RNGServiceStub is RNGInterface {

  uint256 internal random;
  address internal feeToken;
  uint256 internal requestFee;

  function getLastRequestId() external override pure returns (uint32 requestId) {
    return 1;
  }

  function setRequestFee(address _feeToken, uint256 _requestFee) external {
    feeToken = _feeToken;
    requestFee = _requestFee;
  }

  /// @return _feeToken
  /// @return _requestFee
  function getRequestFee() external override view returns (address _feeToken, uint256 _requestFee) {
    return (feeToken, requestFee);
  }

  function setRandomNumber(uint256 _random) external {
    random = _random;
  }

  function requestRandomNumber() external override pure returns (uint32, uint32) {
    return (1, 1);
  }

  function isRequestComplete(uint32) external override pure returns (bool) {
    return true;
  }

  function randomNumber(uint32) external override view returns (uint256) {
    return random;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;

/// @title Random Number Generator Interface
/// @notice Provides an interface for requesting random numbers from 3rd-party RNG services (Chainlink VRF, Starkware VDF, etc..)
interface RNGInterface {

  /// @notice Emitted when a new request for a random number has been submitted
  /// @param requestId The indexed ID of the request used to get the results of the RNG service
  /// @param sender The indexed address of the sender of the request
  event RandomNumberRequested(uint32 indexed requestId, address indexed sender);

  /// @notice Emitted when an existing request for a random number has been completed
  /// @param requestId The indexed ID of the request used to get the results of the RNG service
  /// @param randomNumber The random number produced by the 3rd-party service
  event RandomNumberCompleted(uint32 indexed requestId, uint256 randomNumber);

  /// @notice Gets the last request id used by the RNG service
  /// @return requestId The last request id used in the last request
  function getLastRequestId() external view returns (uint32 requestId);

  /// @notice Gets the Fee for making a Request against an RNG service
  /// @return feeToken The address of the token that is used to pay fees
  /// @return requestFee The fee required to be paid to make a request
  function getRequestFee() external view returns (address feeToken, uint256 requestFee);

  /// @notice Sends a request for a random number to the 3rd-party service
  /// @dev Some services will complete the request immediately, others may have a time-delay
  /// @dev Some services require payment in the form of a token, such as $LINK for Chainlink VRF
  /// @return requestId The ID of the request used to get the results of the RNG service
  /// @return lockBlock The block number at which the RNG service will start generating time-delayed randomness.  The calling contract
  /// should "lock" all activity until the result is available via the `requestId`
  function requestRandomNumber() external returns (uint32 requestId, uint32 lockBlock);

  /// @notice Checks if the request for randomness from the 3rd-party service has completed
  /// @dev For time-delayed requests, this function is used to check/confirm completion
  /// @param requestId The ID of the request used to get the results of the RNG service
  /// @return isCompleted True if the request has completed and a random number is available, false otherwise
  function isRequestComplete(uint32 requestId) external view returns (bool isCompleted);

  /// @notice Gets the random number produced by the 3rd-party service
  /// @param requestId The ID of the request used to get the results of the RNG service
  /// @return randomNum The random number
  function randomNumber(uint32 requestId) external returns (uint256 randomNum);
}