/**
 *Submitted for verification at polygonscan.com on 2023-06-15
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @chainlink/contracts/src/v0.8/interfaces/[email protected]
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]
pragma solidity ^0.8.0;


interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}


// File @api3/airnode-protocol-v1/contracts/api3-server-v1/proxies/interfaces/[email protected]
pragma solidity ^0.8.0;

/// @dev See DapiProxy.sol for comments about usage
interface IProxy {
    function read() external view returns (int224 value, uint32 timestamp);

    function api3ServerV1() external view returns (address);
}


// File @api3/contracts/v0.8/interfaces/[email protected]
pragma solidity ^0.8.0;


// File solidity/contracts/adapters/api3-chainlink-adapter/API3ChainlinkAdapter.sol
pragma solidity >=0.8.7 <0.9.0;


contract API3ChainlinkAdapter is AggregatorV2V3Interface {
  /// @notice Thrown when trying to query a round that is not the latest one
  error OnlyLatestRoundIsAvailable();

  /// @notice The address of the underlying API3 Proxy
  IProxy public immutable API3_PROXY;
  uint8 public immutable decimals;
  string public description;

  /// @notice The round number we'll use to represent the latest round
  uint80 internal constant LATEST_ROUND = 0;
  /// @notice Magnitude to convert API3 values to Chainlink values
  uint256 internal immutable _magnitudeConversion;

  constructor(
    IProxy _api3Proxy,
    uint8 _decimals,
    string memory _description
  ) {
    API3_PROXY = _api3Proxy;
    decimals = _decimals;
    description = _description;
    _magnitudeConversion = 10**(18 - _decimals);
  }

  function version() external pure returns (uint256) {
    // Not sure what this represents, but current Chainlink feeds use this value
    return 4;
  }

  function getRoundData(uint80 __roundId)
    external
    view
    returns (
      uint80 _roundId,
      int256 _answer,
      uint256 _startedAt,
      uint256 _updatedAt,
      uint80 _answeredInRound
    )
  {
    if (__roundId != LATEST_ROUND) revert OnlyLatestRoundIsAvailable();
    return latestRoundData();
  }

  function latestRoundData()
    public
    view
    returns (
      uint80 _roundId,
      int256 _answer,
      uint256 _startedAt,
      uint256 _updatedAt,
      uint80 _answeredInRound
    )
  {
    (_answer, _updatedAt) = _read();
    _roundId = _answeredInRound = LATEST_ROUND;
    _startedAt = _updatedAt;
  }

  function latestAnswer() public view returns (int256 _value) {
    (_value, ) = _read();
  }

  function latestTimestamp() public view returns (uint256 _timestamp) {
    (, _timestamp) = _read();
  }

  function latestRound() external pure returns (uint256) {
    return LATEST_ROUND;
  }

  function getAnswer(uint256 _roundId) external view returns (int256) {
    if (_roundId != LATEST_ROUND) revert OnlyLatestRoundIsAvailable();
    return latestAnswer();
  }

  function getTimestamp(uint256 _roundId) external view returns (uint256) {
    if (_roundId != LATEST_ROUND) revert OnlyLatestRoundIsAvailable();
    return latestTimestamp();
  }

  function _read() internal view returns (int224 _value, uint32 _timestamp) {
    (_value, _timestamp) = API3_PROXY.read();
    unchecked {
      // API3 uses 18 decimals, while Chainlink feeds might use a different amount
      _value /= int224(int256(_magnitudeConversion));
    }
  }
}