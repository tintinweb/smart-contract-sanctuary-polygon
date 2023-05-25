pragma solidity 0.8.10;

contract MockEACAggregatorProxy {
    address public aggregator;
    uint256 timestamp;
    uint80 roundId;
    int256 answer;
    string public name;
    mapping(uint80 => int256) public historyAnswer;
    mapping(uint80 => uint256) public historyTimtstamp;
    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
    event NewRound(uint256 indexed roundId, address indexed startedBy);

    constructor(string memory _name, address _aggregator, int256 _answer) public {
        name = _name;
        aggregator = _aggregator;
        timestamp = block.timestamp;
        roundId = 1;
        answer = _answer;
        historyAnswer[roundId] = answer;
        historyTimtstamp[roundId] = block.timestamp;
        emit AnswerUpdated(_answer, roundId, block.timestamp);
        emit NewRound(roundId, address(this));
    }
  function decimals() external view returns (uint8) {
    return uint8(8);
  }

  function latestAnswer() external view returns (int256) {
    return answer;
  }

  function latestTimestamp() external view returns (uint256) {
    return timestamp;
  }

  function latestRound() external view returns (uint256) {
    return roundId;
  }

  function getAnswer(uint80 roundId) external view returns (int256) {
    return historyAnswer[roundId];
  }

  function getTimestamp(uint80 roundId) external view returns (uint256) {
    return historyTimtstamp[roundId];
  }

  function latestRoundData(uint80 roundId) external view returns(uint80, int256, uint256, uint256, uint80) {
    return (roundId, answer, timestamp, timestamp, roundId);
  }

  function updateAnswer(int256 _answer) external {
    answer = _answer;
    roundId += 1;
    historyAnswer[roundId] = _answer;
    historyTimtstamp[roundId] = block.timestamp;
    emit NewRound(roundId, address(this));
    emit AnswerUpdated(_answer, roundId, block.timestamp);
  }


  function updateAggregator(address _newAggregator) external {
    aggregator = _newAggregator;
  }

}