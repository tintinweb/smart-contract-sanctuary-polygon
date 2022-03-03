/**
 *Submitted for verification at polygonscan.com on 2022-03-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AccessControllerInterface {
  function hasAccess(address user, bytes calldata data) external view returns (bool);
}

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
}

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}


// File contracts/ConfirmedOwnerWithProposal.sol




/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
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


// File contracts/ConfirmedOwner.sol




/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}


// File contracts/OwnerIsCreator.sol




/**
 * @title The OwnerIsCreator contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract OwnerIsCreator is ConfirmedOwner {

  constructor(
  )
    ConfirmedOwner(
      msg.sender
    )
  {
  }
}


// File contracts/OffchainAggregator.sol







/**
  * @notice Onchain verification of reports from the offchain reporting protocol

  * @dev For details on its operation, see the offchain reporting protocol design
  * @dev doc, which refers to this contract as simply the "contract".
*/
contract OffchainAggregator is OwnerIsCreator, AggregatorV2V3Interface, TypeAndVersionInterface {

  // Storing these fields used on the hot path in a HotVars variable reduces the
  // retrieval of all of them to a single SLOAD. If any further fields are
  // added, make sure that storage of the struct still takes at most 32 bytes.
  struct HotVars {
    // Oracle Aggregators expose a roundId to consumers. The offchain reporting
    // protocol does not use this id anywhere. We increment it whenever a new
    // transmission is made to provide callers with contiguous ids for successive
    // reports.
    uint32 latestAggregatorRoundId;
  }
  HotVars internal s_hotVars;

  // Transmission records the median answer from the transmit transaction at 发送中位数结果
  // time timestamp
  struct Transmission {
    int192 answer; // 192 bits ought to be enough for anyone
    uint32 observationsTimestamp; // when were observations made offchain
    uint32 transmissionTimestamp; // when was report received onchain
  }
  mapping(uint32 /* aggregator round ID */ => Transmission) internal s_transmissions;

  // incremented each time a new config is posted. This count is incorporated
  // into the config digest to prevent replay attacks.
  uint32 internal s_configCount;

  // makes it easier for offchain systems to extract config from logs
  uint32 internal s_latestConfigBlockNumber;

  // makes it easier for offchain systems to extract config from logs
  address internal s_latestTransmitter;

  // Lowest answer the system is allowed to report in response to transmissions
  int192 immutable public minAnswer;
  // Highest answer the system is allowed to report in response to transmissions
  int192 immutable public maxAnswer;

  struct Transmitter {
    bool active;

    // Index of oracle in s_signersList/s_transmittersList
    uint8 index;
  }
  mapping (address /* transmitter address */ => Transmitter) internal s_transmitters;

  struct Signer {
    bool active;

    // Index of oracle in s_signersList/s_transmittersList
    uint8 index;
  }
  mapping (address /* signer address */ => Signer) internal s_signers;

  // s_signersList contains the signing address of each oracle
  address[] internal s_signersList;

  // s_transmittersList contains the transmission address of each oracle,
  // i.e. the address the oracle actually sends transactions to the contract from
  address[] internal s_transmittersList;

  /*
   * @param _minAnswer lowest answer the median of a report is allowed to be
   * @param _maxAnswer highest answer the median of a report is allowed to be
   * @param _decimals answers are stored in fixed-point format, with this many digits of precision
   * @param _description short human-readable description of observable this contract's answers pertain to
   */
  constructor(
    int192 _minAnswer,
    int192 _maxAnswer,
    uint8 _decimals,
    string memory _description
  )
  {
    decimals = _decimals;
    s_description = _description;
    minAnswer = _minAnswer;
    maxAnswer = _maxAnswer;
  }

  /*
   * Versioning
   */
  function typeAndVersion()
    external
    override
    pure
    virtual
    returns (string memory)
  {
    return "OffchainAggregator 1.0.0";
  }

  /*
   * Config logic
   */

  /**
   * @notice triggers a new run of the offchain reporting protocol
   * @param previousConfigBlockNumber block in which the previous config was set, to simplify historic analysis
   * @param configCount ordinal number of this config setting among all config settings over the life of this contract
   * @param signers ith element is address ith oracle uses to sign a report
   * @param transmitters ith element is address ith oracle uses to transmit a report via the transmit method
   */
  event ConfigSet(
    uint32 previousConfigBlockNumber,
    uint64 configCount,
    address[] signers,
    address[] transmitters
  );

  /**
   * @notice sets offchain reporting protocol configuration incl. participating oracles
   * @param _transmitters addresses oracles use to transmit the reports
   */
  function setConfig(
    address[] calldata _signers,
    address[] calldata _transmitters
  )
    external
    onlyOwner()
  {
    require(_signers.length == _transmitters.length, "oracle length mismatch");

    // remove any old signer/transmitter addresses
    uint256 oldLength = s_signersList.length;
    for (uint256 i = 0; i < oldLength; i++) {
      address signer = s_signersList[i];
      address transmitter = s_transmittersList[i];
      delete s_signers[signer];
      delete s_transmitters[transmitter];
    }
    delete s_signersList;
    delete s_transmittersList;

    // add new signer/transmitter addresses
    for (uint i = 0; i < _signers.length; i++) {
      require(
        !s_signers[_signers[i]].active,
        "repeated signer address"
      );
      s_signers[_signers[i]] = Signer({
        active: true,
        index: uint8(i)
      });
      require(
        !s_transmitters[_transmitters[i]].active,
        "repeated transmitter address"
      );
      s_transmitters[_transmitters[i]] = Transmitter({
        active: true,
        index: uint8(i)
      });
    }
    s_signersList = _signers;
    s_transmittersList = _transmitters;

    uint32 previousConfigBlockNumber = s_latestConfigBlockNumber;
    s_latestConfigBlockNumber = uint32(block.number);
    s_configCount += 1;

    emit ConfigSet(
      previousConfigBlockNumber,
      s_configCount,
      _signers,
      _transmitters
    );
  }

  /**
   * @notice information about current offchain reporting protocol configuration
   * @return configCount ordinal number of current config, out of all configs applied to this contract so far
   * @return blockNumber block at which this config was set
   */
  function latestConfigDetails()
    external
    view
    returns (
      uint32 configCount,
      uint32 blockNumber
    )
  {
    return (s_configCount, s_latestConfigBlockNumber);
  }

  /**
   * @return list of addresses permitted to transmit reports to this contract
   * @dev The list will match the order used to specify the transmitter during setConfig
   */
  function getTransmitters()
  external
  view
  returns(address[] memory)
  {
    return s_transmittersList;
  }

  /*
   * Transmission logic
   */

  /**
   * @notice indicates that a new report was transmitted
   * @param aggregatorRoundId the round to which this report was assigned
   * @param answer median of the observations attached this report
   * @param transmitter address from which the report was transmitted
   * @param observationsTimestamp when were observations made offchain
   */
  event NewTransmission(
    uint32 indexed aggregatorRoundId,
    int192 answer,
    address transmitter,
    uint32 observationsTimestamp
  );

  /*
   * @notice details about the most transmission details
   * @return nextTransmitter who will be next to transmit the report
   * @return afterNextTransmitter who will transmit the report next afterwards
   * @return nextIndex the index of the next transmitter
   * @return length the length of the s_transmittersList
   * @return roundId aggregator round of latest report
   * @return answer median value from latest report
   * @return startedAt when the latest report was transmitted
   * @return updatedAt when the latest report was transmitted
   */
  function latestTransmissionDetails()
    external
    view
    returns (
      address nextTransmitter,
      address afterNextTransmitter,
      uint8 nextIndex,
      uint256 transmittersLength,
      uint80 roundId,
      int192 answer,
      uint256 startedAt,
      uint256 updatedAt
    )
  {
    require(msg.sender == tx.origin, "Only callable by EOA");

    nextIndex=0;
    uint8 afterNextIndex=0;

    // Calculating the index of the next transmitter
    uint256 s_length = s_transmittersList.length;
    if (s_length > 0) {

      // the index of the current transmitter
      Transmitter memory s_transmitter;
      s_transmitter = s_transmitters[s_latestTransmitter];
      if (s_transmitter.active){

        nextIndex = s_transmitter.index;
        nextIndex++;
        if (s_length == nextIndex) {
          nextIndex = 0;
        }

      }

      afterNextIndex = nextIndex;
      afterNextIndex++;
      if (s_length == afterNextIndex) {
        afterNextIndex = 0;
      }

      nextTransmitter = s_transmittersList[nextIndex];
      afterNextTransmitter = s_transmittersList[afterNextIndex];
    }

    roundId = s_hotVars.latestAggregatorRoundId;
    Transmission memory transmission = s_transmissions[uint32(roundId)];
    return (
      nextTransmitter,
      afterNextTransmitter,
      nextIndex,
      s_length,
      roundId,
      transmission.answer,
      transmission.observationsTimestamp,
      transmission.transmissionTimestamp
    );
  }

  // The constant-length components of the msg.data sent to transmit.
  // See the "If we wanted to call sam" example on for example reasoning
  // https://solidity.readthedocs.io/en/v0.7.2/abi-spec.html
  uint16 private constant TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT =
    4 + // function selector
    32 + // word containing start location of abiencoded _report value
    32 + // _rs value
    32 + // _ss value
    32 + // _vs value
    32 + // word containing length of _report
    0; // placeholder

  function expectedMsgDataLength()
    private pure returns (uint256 length)
  {
    // calldata will never be big enough to make this overflow
    return uint256(TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT) +
      64 + // one byte pure entry in _report
      0; // placeholder
  }

  /**
   * @notice transmit is called to post a new report to the contract
   * @param _report serialized report, which the signatures are signing. See parsing code below for format.
   * @param _rs the R components of the signature on report.
   * @param _ss the S components of the signature on report.
   * @param _vs the V component of the signature on report.
   */
  function transmit(
    // NOTE: If these parameters are changed, expectedMsgDataLength and/or
    // TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT need to be changed accordingly
    bytes calldata _report,
    // ECDSA signature
    bytes32 _rs,
    bytes32 _ss,
    uint8 _vs
  )
    external
  {

    require(s_transmitters[msg.sender].active, "unauthorized transmitter");
    
    require(msg.data.length == expectedMsgDataLength(), "transmit message length mismatch");
    
    int192 median;
    uint32 observationsTimestamp;
    (median, observationsTimestamp) = abi.decode(_report, (int192, uint32));

    uint32 s_latestTimestamp=s_transmissions[s_hotVars.latestAggregatorRoundId].transmissionTimestamp;
    require(observationsTimestamp > s_latestTimestamp, "invalid observations timestamp");

    // Verify signatures attached to report
    {
      bytes32 h = keccak256(_report);
  
      Signer memory signer;
      address signerAddress = ecrecover(h, _vs+27, _rs, _ss);
      signer = s_signers[signerAddress];
      require(signer.active, "signature error");
    }

    _transmit(median,observationsTimestamp);
  }

  function _transmit(
    int192 median,
    uint32 observationsTimestamp
  ) internal {

    require(minAnswer <= median && median <= maxAnswer, "median is out of min-max range");
    HotVars memory hotVars = s_hotVars; // cache read from storage
    hotVars.latestAggregatorRoundId++;
    s_transmissions[hotVars.latestAggregatorRoundId] =
      Transmission({
        answer: median,
        observationsTimestamp: observationsTimestamp,
        transmissionTimestamp: uint32(block.timestamp)
      });

    s_latestTransmitter = msg.sender;
    emit NewTransmission(
      hotVars.latestAggregatorRoundId,
      median,
      msg.sender,
      observationsTimestamp
    );
    // Emit these for backwards compatability with offchain consumers
    // that only support legacy events
    emit NewRound(
      hotVars.latestAggregatorRoundId,
      address(0x0), // use zero address since we don't have anybody "starting" the round here
      observationsTimestamp
    );
    emit AnswerUpdated(
      median,
      hotVars.latestAggregatorRoundId,
      block.timestamp
    );

    // persist updates to hotVars
    s_hotVars = hotVars;
  }

  /*
   * v2 Aggregator interface
   */

  /**
   * @notice median from the most recent report
   */
  function latestAnswer()
    public
    override
    view
    virtual
    returns (int256)
  {
    return s_transmissions[s_hotVars.latestAggregatorRoundId].answer;
  }

  /**
   * @notice timestamp of block in which last report was transmitted
   */
  function latestTimestamp()
    public
    override
    view
    virtual
    returns (uint256)
  {
    return s_transmissions[s_hotVars.latestAggregatorRoundId].transmissionTimestamp;
  }

  /**
   * @notice Aggregator round (NOT OCR round) in which last report was transmitted
   */
  function latestRound()
    public
    override
    view
    virtual
    returns (uint256)
  {
    return s_hotVars.latestAggregatorRoundId;
  }

  /**
   * @notice median of report from given aggregator round (NOT OCR round)
   * @param _roundId the aggregator round of the target report
   */
  function getAnswer(uint256 _roundId)
    public
    override
    view
    virtual
    returns (int256)
  {
    if (_roundId > 0xFFFFFFFF) { return 0; }
    return s_transmissions[uint32(_roundId)].answer;
  }

  /**
   * @notice timestamp of block in which report from given aggregator round was transmitted
   * @param _roundId aggregator round (NOT OCR round) of target report
   */
  function getTimestamp(uint256 _roundId)
    public
    override
    view
    virtual
    returns (uint256)
  {
    if (_roundId > 0xFFFFFFFF) { return 0; }
    return s_transmissions[uint32(_roundId)].transmissionTimestamp;
  }

  /*
   * v3 Aggregator interface
   */

  string constant private V3_NO_DATA_ERROR = "No data present";

  /**
   * @return answers are stored in fixed-point format, with this many digits of precision
   */
  uint8 immutable public override decimals;

  /**
   * @notice aggregator contract version
   */
  uint256 constant public override version = 1;

  string internal s_description;

  /**
   * @notice human-readable description of observable this contract is reporting on
   */
  function description()
    public
    override
    view
    virtual
    returns (string memory)
  {
    return s_description;
  }

  /**
   * @notice details for the given aggregator round
   * @param _roundId target aggregator round (NOT OCR round). Must fit in uint32
   * @return roundId _roundId
   * @return answer median of report from given _roundId
   * @return startedAt timestamp of block in which report from given _roundId was transmitted
   * @return updatedAt timestamp of block in which report from given _roundId was transmitted
   * @return answeredInRound _roundId
   */
  function getRoundData(uint80 _roundId)
    public
    override
    view
    virtual
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    require(_roundId <= 0xFFFFFFFF, V3_NO_DATA_ERROR);
    Transmission memory transmission = s_transmissions[uint32(_roundId)];
    return (
      _roundId,
      transmission.answer,
      transmission.observationsTimestamp,
      transmission.transmissionTimestamp,
      _roundId
    );
  }

  /**
   * @notice aggregator details for the most recently transmitted report
   * @return roundId aggregator round of latest report (NOT OCR round)
   * @return answer median of latest report
   * @return startedAt timestamp of block containing latest report
   * @return updatedAt timestamp of block containing latest report
   * @return answeredInRound aggregator round of latest report
   */
  function latestRoundData()
    public
    override
    view
    virtual
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    roundId = s_hotVars.latestAggregatorRoundId;

    // Skipped for compatability with existing FluxAggregator in which latestRoundData never reverts.
    // require(roundId != 0, V3_NO_DATA_ERROR);

    Transmission memory transmission = s_transmissions[uint32(roundId)];
    return (
      roundId,
      transmission.answer,
      transmission.observationsTimestamp,
      transmission.transmissionTimestamp,
      roundId
    );
  }
}


// File contracts/SimpleWriteAccessController.sol





/**
 * @title SimpleWriteAccessController
 * @notice Gives access to accounts explicitly added to an access list by the
 * controller's owner.
 * @dev does not make any special permissions for externally, see
 * SimpleReadAccessController for that.
 */
contract SimpleWriteAccessController is AccessControllerInterface, OwnerIsCreator {

  bool public checkEnabled;
  mapping(address => bool) internal accessList;

  event AddedAccess(address user);
  event RemovedAccess(address user);
  event CheckAccessEnabled();
  event CheckAccessDisabled();

  constructor()
  {
    checkEnabled = true;
  }

  /**
   * @notice Returns the access of an address
   * @param _user The address to query
   */
  function hasAccess(
    address _user,
    bytes memory
  )
  public
  view
  virtual
  override
  returns (bool)
  {
    return accessList[_user] || !checkEnabled;
  }

  /**
   * @notice Adds an address to the access list
   * @param _user The address to add
   */
  function addAccess(address _user) external onlyOwner() {
    addAccessInternal(_user);
  }

  function addAccessInternal(address _user) internal {
    if (!accessList[_user]) {
      accessList[_user] = true;
      emit AddedAccess(_user);
    }
  }

  /**
   * @notice Removes an address from the access list
   * @param _user The address to remove
   */
  function removeAccess(address _user)
  external
  onlyOwner()
  {
    if (accessList[_user]) {
      accessList[_user] = false;

      emit RemovedAccess(_user);
    }
  }

  /**
   * @notice makes the access check enforced
   */
  function enableAccessCheck()
  external
  onlyOwner()
  {
    if (!checkEnabled) {
      checkEnabled = true;

      emit CheckAccessEnabled();
    }
  }

  /**
   * @notice makes the access check unenforced
   */
  function disableAccessCheck()
  external
  onlyOwner()
  {
    if (checkEnabled) {
      checkEnabled = false;

      emit CheckAccessDisabled();
    }
  }

  /**
   * @dev reverts if the caller does not have access
   */
  modifier checkAccess() {
    require(hasAccess(msg.sender, msg.data), "No access");
    _;
  }
}


// File contracts/SimpleReadAccessController.sol




/**
 * @title SimpleReadAccessController
 * @notice Gives access to:
 * - any externally owned account (note that offchain actors can always read
 * any contract storage regardless of onchain access control measures, so this
 * does not weaken the access control while improving usability)
 * - accounts explicitly added to an access list
 * @dev SimpleReadAccessController is not suitable for access controlling writes
 * since it grants any externally owned account access! See
 * SimpleWriteAccessController for that.
 */
contract SimpleReadAccessController is SimpleWriteAccessController {

  /**
   * @notice Returns the access of an address
   * @param _user The address to query
   */
  function hasAccess(
    address _user,
    bytes memory _calldata
  )
  public
  view
  virtual
  override
  returns (bool)
  {
    return super.hasAccess(_user, _calldata) || _user == tx.origin;
  }

}


// File contracts/AccessControlledOffchainAggregator.sol





/**
 * @notice Wrapper of OffchainAggregator which checks read access on Aggregator-interface methods
 */
contract AccessControlledOffchainAggregator is OffchainAggregator, SimpleReadAccessController {

  constructor(
    int192 _minAnswer,
    int192 _maxAnswer,
    uint8 _decimals,
    string memory _description
  )
    OffchainAggregator(
      _minAnswer,
      _maxAnswer,
      _decimals,
      _description
    ) {
  }

  /*
   * Versioning
   */

  function typeAndVersion()
    external
    override
    pure
    virtual
    returns (string memory)
  {
    return "AccessControlledOffchainAggregator 1.0.0";
  }


  /*
   * v2 Aggregator interface
   */

  /// @inheritdoc OffchainAggregator
  function latestAnswer()
    public
    override
    view
    checkAccess()
    returns (int256)
  {
    return super.latestAnswer();
  }

  /// @inheritdoc OffchainAggregator
  function latestTimestamp()
    public
    override
    view
    checkAccess()
    returns (uint256)
  {
    return super.latestTimestamp();
  }

  /// @inheritdoc OffchainAggregator
  function latestRound()
    public
    override
    view
    checkAccess()
    returns (uint256)
  {
    return super.latestRound();
  }

  /// @inheritdoc OffchainAggregator
  function getAnswer(uint256 _roundId)
    public
    override
    view
    checkAccess()
    returns (int256)
  {
    return super.getAnswer(_roundId);
  }

  /// @inheritdoc OffchainAggregator
  function getTimestamp(uint256 _roundId)
    public
    override
    view
    checkAccess()
    returns (uint256)
  {
    return super.getTimestamp(_roundId);
  }

  /*
   * v3 Aggregator interface
   */

  /// @inheritdoc OffchainAggregator
  function description()
    public
    override
    view
    checkAccess()
    returns (string memory)
  {
    return super.description();
  }

  /// @inheritdoc OffchainAggregator
  function getRoundData(uint80 _roundId)
    public
    override
    view
    checkAccess()
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return super.getRoundData(_roundId);
  }

  /// @inheritdoc OffchainAggregator
  function latestRoundData()
    public
    override
    view
    checkAccess()
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return super.latestRoundData();
  }

}