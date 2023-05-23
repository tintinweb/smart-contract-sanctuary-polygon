// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2; // solhint-disable compiler-version

import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV2V3Interface.sol";
import "./access/AccessControlled.sol";
import "./interfaces/FeedRegistryInterface.sol";
import "./interfaces/TypeAndVersionInterface.sol";

/**
  * @notice An on-chain registry of assets to aggregators.
  * @notice This contract provides a consistent address for consumers but delegates where it reads from to the owner, who is
  * trusted to update it. This registry contract works for multiple feeds, not just a single aggregator.
  * @notice Only access enabled addresses are allowed to access getters for answers and round data
  */
contract FeedRegistry is FeedRegistryInterface, TypeAndVersionInterface, AccessControlled {
  uint256 constant private PHASE_OFFSET = 64;
  uint256 constant private PHASE_SIZE = 16;
  uint256 constant private MAX_ID = 2**(PHASE_OFFSET+PHASE_SIZE) - 1;

  mapping(address => bool) private s_isAggregatorEnabled;
  mapping(address => mapping(address => AggregatorV2V3Interface)) private s_proposedAggregators;
  mapping(address => mapping(address => uint16)) private s_currentPhaseId;
  mapping(address => mapping(address => mapping(uint16 => AggregatorV2V3Interface))) private s_phaseAggregators;
  mapping(address => mapping(address => mapping(uint16 => Phase))) private s_phases;

  /*
   * @notice Versioning
   */
  function typeAndVersion()
    external
    override
    pure
    virtual
    returns (
      string memory
    )
  {
    return "FeedRegistry 1.0.0";
  }

  /**
   * @notice represents the number of decimals the aggregator responses represent.
   */
  function decimals(
    address base,
    address quote
  )
    external
    view
    override
    returns (
      uint8
    )
  {
    AggregatorV2V3Interface aggregator = _getFeed(base, quote);
    require(address(aggregator) != address(0), "Feed not found");
    return aggregator.decimals();
  }

  /**
   * @notice returns the description of the aggregator the proxy points to.
   */
  function description(
    address base,
    address quote
  )
    external
    view
    override
    returns (
      string memory
    )
  {
    AggregatorV2V3Interface aggregator = _getFeed(base, quote);
    require(address(aggregator) != address(0), "Feed not found");
    return aggregator.description();
  }

  /**
   * @notice the version number representing the type of aggregator the proxy
   * points to.
   */
  function version(
    address base,
    address quote
  )
    external
    view
    override
    returns (
      uint256
    )
  {
    AggregatorV2V3Interface aggregator = _getFeed(base, quote);
    require(address(aggregator) != address(0), "Feed not found");
    return aggregator.version();
  }

  /**
   * @notice get data about the latest round. Consumers are encouraged to check
   * that they're receiving fresh data by inspecting the updatedAt and
   * answeredInRound return values.
   * Note that different underlying implementations of AggregatorV3Interface
   * have slightly different semantics for some of the return values. Consumers
   * should determine what implementations they expect to receive
   * data from and validate that they can properly handle return data from all
   * of them.
   * @param base base asset address
   * @param quote quote asset address
   * @return roundId is the round ID from the aggregator for which the data was
   * retrieved combined with a phase to ensure that round IDs get larger as
   * time moves forward.
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @dev Note that answer and updatedAt may change between queries.
   */
  function latestRoundData(
    address base,
    address quote
  )
    external
    view
    override
    checkPairAccess()
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    uint16 currentPhaseId = s_currentPhaseId[base][quote];
    AggregatorV2V3Interface aggregator = _getFeed(base, quote);
    require(address(aggregator) != address(0), "Feed not found");
    (
      roundId,
      answer,
      startedAt,
      updatedAt,
      answeredInRound
    ) = aggregator.latestRoundData();
    return _addPhaseIds(roundId, answer, startedAt, updatedAt, answeredInRound, currentPhaseId);
  }

  /**
   * @notice get data about a round. Consumers are encouraged to check
   * that they're receiving fresh data by inspecting the updatedAt and
   * answeredInRound return values.
   * Note that different underlying implementations of AggregatorV3Interface
   * have slightly different semantics for some of the return values. Consumers
   * should determine what implementations they expect to receive
   * data from and validate that they can properly handle return data from all
   * of them.
   * @param base base asset address
   * @param quote quote asset address
   * @param _roundId the proxy round id number to retrieve the round data for
   * @return roundId is the round ID from the aggregator for which the data was
   * retrieved combined with a phase to ensure that round IDs get larger as
   * time moves forward.
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @dev Note that answer and updatedAt may change between queries.
   */
  function getRoundData(
    address base,
    address quote,
    uint80 _roundId
  )
    external
    view
    override
    checkPairAccess()
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    (uint16 phaseId, uint64 aggregatorRoundId) = _parseIds(_roundId);
    AggregatorV2V3Interface aggregator = _getPhaseFeed(base, quote, phaseId);
    require(address(aggregator) != address(0), "Feed not found");
    (
      roundId,
      answer,
      startedAt,
      updatedAt,
      answeredInRound
    ) = aggregator.getRoundData(aggregatorRoundId);
    return _addPhaseIds(roundId, answer, startedAt, updatedAt, answeredInRound, phaseId);
  }


  /**
   * @notice Reads the current answer for an base / quote pair's aggregator.
   * @param base base asset address
   * @param quote quote asset address
   * @notice We advise to use latestRoundData() instead because it returns more in-depth information.
   * @dev This does not error if no answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended latestRoundData
   * instead which includes better verification information.
   */
  function latestAnswer(
    address base,
    address quote
  )
    external
    view
    override
    checkPairAccess()
    returns (
      int256 answer
    )
  {
    AggregatorV2V3Interface aggregator = _getFeed(base, quote);
    require(address(aggregator) != address(0), "Feed not found");
    return aggregator.latestAnswer();
  }

  /**
   * @notice get the latest completed timestamp where the answer was updated.
   * @param base base asset address
   * @param quote quote asset address
   *
   * @notice We advise to use latestRoundData() instead because it returns more in-depth information.
   * @dev This does not error if no answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended latestRoundData
   * instead which includes better verification information.
   */
  function latestTimestamp(
    address base,
    address quote
  )
    external
    view
    override
    checkPairAccess()
    returns (
      uint256 timestamp
    )
  {
    AggregatorV2V3Interface aggregator = _getFeed(base, quote);
    require(address(aggregator) != address(0), "Feed not found");
    return aggregator.latestTimestamp();
  }

  /**
   * @notice get the latest completed round where the answer was updated
   * @param base base asset address
   * @param quote quote asset address
   * @dev overridden function to add the checkPairAccess() modifier
   *
   * @notice We advise to use latestRoundData() instead because it returns more in-depth information.
   * @dev Use latestRoundData instead. This does not error if no
   * answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended latestRoundData
   * instead which includes better verification information.
   */
  function latestRound(
    address base,
    address quote
  )
    external
    view
    override
    checkPairAccess()
    returns (
      uint256 roundId
    )
  {
    uint16 currentPhaseId = s_currentPhaseId[base][quote];
    AggregatorV2V3Interface aggregator = _getFeed(base, quote);
    require(address(aggregator) != address(0), "Feed not found");
    return _addPhase(currentPhaseId, uint64(aggregator.latestRound()));
  }

  /**
   * @notice get past rounds answers
   * @param base base asset address
   * @param quote quote asset address
   * @param roundId the proxy round id number to retrieve the answer for
   * @dev overridden function to add the checkPairAccess() modifier
   *
   * @notice We advise to use getRoundData() instead because it returns more in-depth information.
   * @dev This does not error if no answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended getRoundData
   * instead which includes better verification information.
   */
  function getAnswer(
    address base,
    address quote,
    uint256 roundId
  )
    external
    view
    override
    checkPairAccess()
    returns (
      int256 answer
    )
  {
    if (roundId > MAX_ID) return 0;
    (uint16 phaseId, uint64 aggregatorRoundId) = _parseIds(roundId);
    AggregatorV2V3Interface aggregator = _getPhaseFeed(base, quote, phaseId);
    if (address(aggregator) == address(0)) return 0;
    return aggregator.getAnswer(aggregatorRoundId);
  }

  /**
   * @notice get block timestamp when an answer was last updated
   * @param base base asset address
   * @param quote quote asset address
   * @param roundId the proxy round id number to retrieve the updated timestamp for
   * @dev overridden function to add the checkPairAccess() modifier
   *
   * @notice We advise to use getRoundData() instead because it returns more in-depth information.
   * @dev This does not error if no answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended getRoundData
   * instead which includes better verification information.
   */
  function getTimestamp(
    address base,
    address quote,
    uint256 roundId
  )
    external
    view
    override
    checkPairAccess()
    returns (
      uint256 timestamp
    )
  {
    if (roundId > MAX_ID) return 0;
    (uint16 phaseId, uint64 aggregatorRoundId) = _parseIds(roundId);
    AggregatorV2V3Interface aggregator = _getPhaseFeed(base, quote, phaseId);
    if (address(aggregator) == address(0)) return 0;
    return aggregator.getTimestamp(aggregatorRoundId);
  }


  /**
   * @notice Retrieve the aggregator of an base / quote pair in the current phase
   * @param base base asset address
   * @param quote quote asset address
   * @return aggregator
   */
  function getFeed(
    address base,
    address quote
  )
    external
    view
    override
    returns (
      AggregatorV2V3Interface aggregator
    )
  {
    aggregator = _getFeed(base, quote);
    require(address(aggregator) != address(0), "Feed not found");
  }

  /**
   * @notice retrieve the aggregator of an base / quote pair at a specific phase
   * @param base base asset address
   * @param quote quote asset address
   * @param phaseId phase ID
   * @return aggregator
   */
  function getPhaseFeed(
    address base,
    address quote,
    uint16 phaseId
  )
    external
    view
    override
    returns (
      AggregatorV2V3Interface aggregator
    )
  {
    aggregator = _getPhaseFeed(base, quote, phaseId);
    require(address(aggregator) != address(0), "Feed not found for phase");
  }

  /**
   * @notice returns true if a aggregator is enabled for any pair
   * @param aggregator aggregator address
   */
  function isFeedEnabled(
    address aggregator
  )
    external
    view
    override
    returns (
      bool
    )
  {
    return s_isAggregatorEnabled[aggregator];
  }

  /**
   * @notice returns a phase by id. A Phase contains the starting and ending aggregator round ids.
   * endingAggregatorRoundId will be 0 if the phase is the current phase
   * @dev reverts if the phase does not exist
   * @param base base asset address
   * @param quote quote asset address
   * @param phaseId phase id
   * @return phase
   */
  function getPhase(
    address base,
    address quote,
    uint16 phaseId
  )
    external
    view
    override
    returns (
      Phase memory phase
    )
  {
    phase = _getPhase(base, quote, phaseId);
    require(_phaseExists(phase), "Phase does not exist");
  }

  /**
   * @notice retrieve the aggregator of an base / quote pair at a specific round id
   * @param base base asset address
   * @param quote quote asset address
   * @param roundId the proxy round id
   */
  function getRoundFeed(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    override
    returns (
      AggregatorV2V3Interface aggregator
    )
  {
    uint16 phaseId = _getPhaseIdByRoundId(base, quote, roundId);
    aggregator = _getPhaseFeed(base, quote, phaseId);
    require(address(aggregator) != address(0), "Feed not found for round");
  }

  /**
   * @notice returns the range of proxy round ids of a phase
   * @param base base asset address
   * @param quote quote asset address
   * @param phaseId phase id
   * @return startingRoundId
   * @return endingRoundId
   */
  function getPhaseRange(
    address base,
    address quote,
    uint16 phaseId
  )
    external
    view
    override
    returns (
      uint80 startingRoundId,
      uint80 endingRoundId
    )
  {
    Phase memory phase = _getPhase(base, quote, phaseId);
    require(_phaseExists(phase), "Phase does not exist");

    uint16 currentPhaseId = s_currentPhaseId[base][quote];
    if (phaseId == currentPhaseId) return _getLatestRoundRange(base, quote, currentPhaseId);
    return _getPhaseRange(base, quote, phaseId);
  }

  /**
   * @notice return the previous round id of a given round
   * @param base base asset address
   * @param quote quote asset address
   * @param roundId the round id number to retrieve the updated timestamp for
   * @dev Note that this is not the aggregator round id, but the proxy round id
   * To get full ranges of round ids of different phases, use getPhaseRange()
   * @return previousRoundId
   */
  function getPreviousRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external
    view
    override
    returns (
      uint80 previousRoundId
    )
  {
    uint16 phaseId = _getPhaseIdByRoundId(base, quote, roundId);
    return _getPreviousRoundId(base, quote, phaseId, roundId);
  }

  /**
   * @notice return the next round id of a given round
   * @param base base asset address
   * @param quote quote asset address
   * @param roundId the round id number to retrieve the updated timestamp for
   * @dev Note that this is not the aggregator round id, but the proxy round id
   * To get full ranges of round ids of different phases, use getPhaseRange()
   * @return nextRoundId
   */
  function getNextRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external
    view
    override
    returns (
      uint80 nextRoundId
    )
  {
    uint16 phaseId = _getPhaseIdByRoundId(base, quote, roundId);
    return _getNextRoundId(base, quote, phaseId, roundId);
  }

  /**
   * @notice Allows the owner to propose a new address for the aggregator
   * @param base base asset address
   * @param quote quote asset address
   * @param aggregator The new aggregator contract address
   */
  function proposeFeed(
    address base,
    address quote,
    address aggregator
  )
    external
    override
    onlyOwner()
  {
    AggregatorV2V3Interface currentPhaseAggregator = _getFeed(base, quote);
    require(aggregator != address(currentPhaseAggregator), "Cannot propose current aggregator");
    address proposedAggregator = address(_getProposedFeed(base, quote));
    if (proposedAggregator != aggregator) {
      s_proposedAggregators[base][quote] = AggregatorV2V3Interface(aggregator);
      emit FeedProposed(base, quote, aggregator, address(currentPhaseAggregator), msg.sender);
    }
  }

  /**
   * @notice Allows the owner to confirm and change the address
   * to the proposed aggregator
   * @dev Reverts if the given address doesn't match what was previously
   * proposed
   * @param base base asset address
   * @param quote quote asset address
   * @param aggregator The new aggregator contract address
   */
  function confirmFeed(
    address base,
    address quote,
    address aggregator
  )
    external
    override
    onlyOwner()
  {
    (uint16 nextPhaseId, address previousAggregator) = _setFeed(base, quote, aggregator);
    delete s_proposedAggregators[base][quote];
    s_isAggregatorEnabled[aggregator] = true;
    s_isAggregatorEnabled[previousAggregator] = false;
    emit FeedConfirmed(base, quote, aggregator, previousAggregator, nextPhaseId, msg.sender);
  }

  /**
   * @notice Returns the proposed aggregator for an base / quote pair
   * returns a zero address if there is no proposed aggregator for the pair
   * @param base base asset address
   * @param quote quote asset address
   * @return proposedAggregator
  */
  function getProposedFeed(
    address base,
    address quote
  )
    external
    view
    override
    returns (
      AggregatorV2V3Interface proposedAggregator
    )
  {
    return _getProposedFeed(base, quote);
  }

  /**
   * @notice Used if an aggregator contract has been proposed.
   * @param base base asset address
   * @param quote quote asset address
   * @param roundId the round ID to retrieve the round data for
   * @return id is the round ID for which data was retrieved
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
  */
  function proposedGetRoundData(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    virtual
    override
    hasProposal(base, quote)
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return s_proposedAggregators[base][quote].getRoundData(roundId);
  }

  /**
   * @notice Used if an aggregator contract has been proposed.
   * @param base base asset address
   * @param quote quote asset address
   * @return id is the round ID for which data was retrieved
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
  */
  function proposedLatestRoundData(
    address base,
    address quote
  )
    external
    view
    virtual
    override
    hasProposal(base, quote)
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return s_proposedAggregators[base][quote].latestRoundData();
  }

  function getCurrentPhaseId(
    address base,
    address quote
  )
    external
    view
    override
    returns (
      uint16 currentPhaseId
    )
  {
    return s_currentPhaseId[base][quote];
  }

  function _addPhase(
    uint16 phase,
    uint64 roundId
  )
    internal
    pure
    returns (
      uint80
    )
  {
    return uint80(uint256(phase) << PHASE_OFFSET | roundId);
  }

  function _parseIds(
    uint256 roundId
  )
    internal
    pure
    returns (
      uint16,
      uint64
    )
  {
    uint16 phaseId = uint16(roundId >> PHASE_OFFSET);
    uint64 aggregatorRoundId = uint64(roundId);

    return (phaseId, aggregatorRoundId);
  }

  function _addPhaseIds(
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound,
      uint16 phaseId
  )
    internal
    pure
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    )
  {
    return (
      _addPhase(phaseId, uint64(roundId)),
      answer,
      startedAt,
      updatedAt,
      _addPhase(phaseId, uint64(answeredInRound))
    );
  }

  function _getPhase(
    address base,
    address quote,
    uint16 phaseId
  )
    internal
    view
    returns (
      Phase memory phase
    )
  {
    return s_phases[base][quote][phaseId];
  }

  function _phaseExists(
    Phase memory phase
  )
    internal
    pure
    returns (
      bool
    )
  {
    return phase.phaseId > 0;
  }

  function _getProposedFeed(
    address base,
    address quote
  )
    internal
    view
    returns (
      AggregatorV2V3Interface proposedAggregator
    )
  {
    return s_proposedAggregators[base][quote];
  }

  function _getPhaseFeed(
    address base,
    address quote,
    uint16 phaseId
  )
    internal
    view
    returns (
      AggregatorV2V3Interface aggregator
    )
  {
    return s_phaseAggregators[base][quote][phaseId];
  }

  function _getFeed(
    address base,
    address quote
  )
    internal
    view
    returns (
      AggregatorV2V3Interface aggregator
    )
  {
    uint16 currentPhaseId = s_currentPhaseId[base][quote];
    return _getPhaseFeed(base, quote, currentPhaseId);
  }

  function _setFeed(
    address base,
    address quote,
    address newAggregator
  )
    internal
    returns (
      uint16 nextPhaseId,
      address previousAggregator
    )
  {
    require(newAggregator == address(s_proposedAggregators[base][quote]), "Invalid proposed aggregator");
    AggregatorV2V3Interface currentAggregator = _getFeed(base, quote);
    uint80 previousAggregatorEndingRoundId = _getLatestAggregatorRoundId(currentAggregator);
    uint16 currentPhaseId = s_currentPhaseId[base][quote];
    s_phases[base][quote][currentPhaseId].endingAggregatorRoundId = previousAggregatorEndingRoundId;

    nextPhaseId = currentPhaseId + 1;
    s_currentPhaseId[base][quote] = nextPhaseId;
    s_phaseAggregators[base][quote][nextPhaseId] = AggregatorV2V3Interface(newAggregator);
    uint80 startingRoundId = _getLatestAggregatorRoundId(AggregatorV2V3Interface(newAggregator));
    s_phases[base][quote][nextPhaseId] = Phase(nextPhaseId, startingRoundId, 0);

    return (nextPhaseId, address(currentAggregator));
  }

  function _getPreviousRoundId(
    address base,
    address quote,
    uint16 phaseId,
    uint80 roundId
  )
    internal
    view
    returns (
      uint80
    )
  {
    for (uint16 pid = phaseId; pid > 0; pid--) {
      AggregatorV2V3Interface phaseAggregator = _getPhaseFeed(base, quote, pid);
      (uint80 startingRoundId, uint80 endingRoundId) = _getPhaseRange(base, quote, pid);
      if (address(phaseAggregator) == address(0)) continue;
      if (roundId <= startingRoundId) continue;
      if (roundId > startingRoundId && roundId <= endingRoundId) return roundId - 1;
      if (roundId > endingRoundId) return endingRoundId;
    }
    return 0; // Round not found
  }

  function _getNextRoundId(
    address base,
    address quote,
    uint16 phaseId,
    uint80 roundId
  )
    internal
    view
    returns (
      uint80
    )
  {
    uint16 currentPhaseId = s_currentPhaseId[base][quote];
    for (uint16 pid = phaseId; pid <= currentPhaseId; pid++) {
      AggregatorV2V3Interface phaseAggregator = _getPhaseFeed(base, quote, pid);
      (uint80 startingRoundId, uint80 endingRoundId) =
        (pid == currentPhaseId) ? _getLatestRoundRange(base, quote, pid) : _getPhaseRange(base, quote, pid);
      if (address(phaseAggregator) == address(0)) continue;
      if (roundId >= endingRoundId) continue;
      if (roundId >= startingRoundId && roundId < endingRoundId) return roundId + 1;
      if (roundId < startingRoundId) return startingRoundId;
    }
    return 0; // Round not found
  }

  function _getPhaseRange(
    address base,
    address quote,
    uint16 phaseId
  )
    internal
    view
    returns (
      uint80 startingRoundId,
      uint80 endingRoundId
    )
  {
    Phase memory phase = _getPhase(base, quote, phaseId);
    return (
      _getStartingRoundId(phaseId, phase),
      _getEndingRoundId(phaseId, phase)
    );
  }

  function _getLatestRoundRange(
    address base,
    address quote,
    uint16 currentPhaseId
  )
    internal
    view
    returns (
      uint80 startingRoundId,
      uint80 endingRoundId
    )
  {
    Phase memory phase = s_phases[base][quote][currentPhaseId];
    return (
      _getStartingRoundId(currentPhaseId, phase),
      _getLatestRoundId(base, quote, currentPhaseId)
    );
  }

  function _getStartingRoundId(
    uint16 phaseId,
    Phase memory phase
  )
    internal
    pure
    returns (
      uint80 startingRoundId
    )
  {
    return _addPhase(phaseId, uint64(phase.startingAggregatorRoundId));
  }

  function _getEndingRoundId(
    uint16 phaseId,
    Phase memory phase
  )
    internal
    pure
    returns (
      uint80 startingRoundId
    )
  {
    return _addPhase(phaseId, uint64(phase.endingAggregatorRoundId));
  }

  function _getLatestRoundId(
    address base,
    address quote,
    uint16 phaseId
  )
    internal
    view
    returns (
      uint80 startingRoundId
    )
  {
    AggregatorV2V3Interface currentPhaseAggregator = _getFeed(base, quote);
    uint80 latestAggregatorRoundId = _getLatestAggregatorRoundId(currentPhaseAggregator);
    return _addPhase(phaseId, uint64(latestAggregatorRoundId));
  }

  function _getLatestAggregatorRoundId(
    AggregatorV2V3Interface aggregator
  )
    internal
    view
    returns (
      uint80 roundId
    )
  {
    if (address(aggregator) == address(0)) return uint80(0);
    return uint80(aggregator.latestRound());
  }

  function _getPhaseIdByRoundId(
    address base,
    address quote,
    uint80 roundId
  )
    internal
    view
    returns (
      uint16 phaseId
    )
  {
    // Handle case where the round is in current phase
    uint16 currentPhaseId = s_currentPhaseId[base][quote];
    (uint80 startingCurrentRoundId, uint80 endingCurrentRoundId) = _getLatestRoundRange(base, quote, currentPhaseId);
    if (roundId >= startingCurrentRoundId && roundId <= endingCurrentRoundId) return currentPhaseId;

    // Handle case where the round is in past phases
    require(currentPhaseId > 0, "Invalid phase");
    for (uint16 pid = currentPhaseId - 1; pid > 0; pid--) {
      AggregatorV2V3Interface phaseAggregator = s_phaseAggregators[base][quote][pid];
      if (address(phaseAggregator) == address(0)) continue;
      (uint80 startingRoundId, uint80 endingRoundId) = _getPhaseRange(base, quote, pid);
      if (roundId >= startingRoundId && roundId <= endingRoundId) return pid;
      if (roundId > endingRoundId) break;
    }
    return 0;
  }

  /**
   * @dev reverts if the caller does not have access granted by the accessController contract
   * to the base / quote pair or is the contract itself.
   */
  modifier checkPairAccess() {
    require(address(s_accessController) == address(0) || s_accessController.hasAccess(msg.sender, msg.data), "No access");
    _;
  }

  /**
   * @dev reverts if no proposed aggregator was set
   */
  modifier hasProposal(
    address base,
    address quote
  ) {
    require(address(s_proposedAggregators[base][quote]) != address(0), "No proposed aggregator present");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@chainlink/contracts/src/v0.7/dev/ConfirmedOwner.sol";
import "../interfaces/AccessControlledInterface.sol";
import "../interfaces/AccessControllerInterface.sol";

contract AccessControlled is AccessControlledInterface, ConfirmedOwner(msg.sender) {
  AccessControllerInterface internal s_accessController;

  function setAccessController(
    AccessControllerInterface _accessController
  )
    public
    override
    onlyOwner()
  {
    require(address(_accessController) != address(s_accessController), "Access controller is already set");
    s_accessController = _accessController;
    emit AccessControllerSet(address(_accessController), msg.sender);
  }

  function getAccessController()
    public
    view
    override
    returns (
      AccessControllerInterface
    )
  {
    return s_accessController;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2; // solhint-disable compiler-version

import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV2V3Interface.sol";

interface FeedRegistryInterface {
  struct Phase {
    uint16 phaseId;
    uint80 startingAggregatorRoundId;
    uint80 endingAggregatorRoundId;
  }

  event FeedProposed(
    address indexed asset,
    address indexed denomination,
    address indexed proposedAggregator,
    address currentAggregator,
    address sender
  );
  event FeedConfirmed(
    address indexed asset,
    address indexed denomination,
    address indexed latestAggregator,
    address previousAggregator,
    uint16 nextPhaseId,
    address sender
  );

  // V3 AggregatorV3Interface

  function decimals(
    address base,
    address quote
  )
    external
    view
    returns (
      uint8
    );

  function description(
    address base,
    address quote
  )
    external
    view
    returns (
      string memory
    );

  function version(
    address base,
    address quote
  )
    external
    view
    returns (
      uint256
    );

  function latestRoundData(
    address base,
    address quote
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function getRoundData(
    address base,
    address quote,
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // V2 AggregatorInterface

  function latestAnswer(
    address base,
    address quote
  )
    external
    view
    returns (
      int256 answer
    );

  function latestTimestamp(
    address base,
    address quote
  )
    external
    view
    returns (
      uint256 timestamp
    );

  function latestRound(
    address base,
    address quote
  )
    external
    view
    returns (
      uint256 roundId
    );

  function getAnswer(
    address base,
    address quote,
    uint256 roundId
  )
    external
    view
    returns (
      int256 answer
    );

  function getTimestamp(
    address base,
    address quote,
    uint256 roundId
  )
    external
    view
    returns (
      uint256 timestamp
    );

  // Registry getters

  function getFeed(
    address base,
    address quote
  )
    external
    view
    returns (
      AggregatorV2V3Interface aggregator
    );

  function getPhaseFeed(
    address base,
    address quote,
    uint16 phaseId
  )
    external
    view
    returns (
      AggregatorV2V3Interface aggregator
    );

  function isFeedEnabled(
    address aggregator
  )
    external
    view
    returns (
      bool
    );

  function getPhase(
    address base,
    address quote,
    uint16 phaseId
  )
    external
    view
    returns (
      Phase memory phase
    );

  // Round helpers

  function getRoundFeed(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    returns (
      AggregatorV2V3Interface aggregator
    );

  function getPhaseRange(
    address base,
    address quote,
    uint16 phaseId
  )
    external
    view
    returns (
      uint80 startingRoundId,
      uint80 endingRoundId
    );

  function getPreviousRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external
    view
    returns (
      uint80 previousRoundId
    );

  function getNextRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external
    view
    returns (
      uint80 nextRoundId
    );

  // Feed management

  function proposeFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  function confirmFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  // Proposed aggregator

  function getProposedFeed(
    address base,
    address quote
  )
    external
    view
    returns (
      AggregatorV2V3Interface proposedAggregator
    );

  function proposedGetRoundData(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function proposedLatestRoundData(
    address base,
    address quote
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // Phases
  function getCurrentPhaseId(
    address base,
    address quote
  )
    external
    view
    returns (
      uint16 currentPhaseId
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface TypeAndVersionInterface{
  function typeAndVersion()
    external
    pure
    returns (
      string memory
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {

  constructor(
    address newOwner
  )
    ConfirmedOwnerWithProposal(
      newOwner,
      address(0)
    )
  {
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./AccessControllerInterface.sol";

interface AccessControlledInterface {
  event AccessControllerSet(
    address indexed accessController,
    address indexed sender
  );

  function setAccessController(
    AccessControllerInterface _accessController
  )
    external;

  function getAccessController()
    external
    view
    returns (
      AccessControllerInterface
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AccessControllerInterface {
  function hasAccess(address user, bytes calldata data) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {

  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor(
    address owner,
    address pendingOwner
  ) {
    require(owner != address(0), "Cannot set owner to zero");

    s_owner = owner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(
    address to
  )
    public
    override
    onlyOwner()
  {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
    override
  {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner()
    public
    view
    override
    returns (
      address
    )
  {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(
    address to
  )
    private
  {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership()
    internal
    view
  {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface OwnableInterface {
  function owner()
    external
    returns (
      address
    );

  function transferOwnership(
    address recipient
  )
    external;

  function acceptOwnership()
    external;
}