// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "./OffchainAggregator.sol";
import "./SimpleReadAccessController.sol";

/**
 * @notice Wrapper of OffchainAggregator which checks read access on Aggregator-interface methods
 */
contract AccessControlledOffchainAggregator is OffchainAggregator, SimpleReadAccessController {

  constructor(
    int8 _upperBoundAnchorRatio,
    int8 _lowerBoundAnchorRatio,
    uint8 _decimals,
    string memory _description
  )
    OffchainAggregator(
      _upperBoundAnchorRatio,
      _lowerBoundAnchorRatio,
      _decimals,
      _description
    )
  {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./interfaces/AccessControllerInterface.sol";
import "./interfaces/AggregatorV2V3Interface.sol";
import "./interfaces/TypeAndVersionInterface.sol";
import "./SignedSafeMath.sol";
import "./OwnerIsCreator.sol";

/**
  * @notice Onchain verification of reports from the offchain reporting protocol

  * @dev For details on its operation, see the offchain reporting protocol design
  * @dev doc, which refers to this contract as simply the "contract".
*/
contract OffchainAggregator is OwnerIsCreator, AggregatorV2V3Interface, TypeAndVersionInterface {

  using SignedSafeMath for int256;
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

  int8 public upperBoundAnchorRatio; //1.2e2
  int8 public lowerBoundAnchorRatio; //0.8e2

  int8 internal constant minLowerBoundAnchorRatio = 0.8e2;
  int8 internal constant maxUpperBoundAnchorRatio = 1.2e2;

  struct Signer {
    bool active;

    // Index of oracle in s_signersList/s_transmittersList
    uint8 index;
  }
  // s_signersList contains the signing address of each oracle
  address[] internal s_signersList;
  mapping (address /* signer address */ => Signer) internal s_signers;

  struct Transmitter {
    bool active;

    // Index of oracle in s_signersList/s_transmittersList
    uint8 index;
  }
  // s_transmittersList contains the transmission address of each oracle,
  // i.e. the address the oracle actually sends transactions to the contract from
  address[] internal s_transmittersList;
  mapping (address /* transmitter address */ => Transmitter) internal s_transmitters;

  constructor(
    int8 _upperBoundAnchorRatio,
    int8 _lowerBoundAnchorRatio,
    uint8 _decimals,
    string memory _description
  )
  {
    upperBoundAnchorRatio = _upperBoundAnchorRatio;
    lowerBoundAnchorRatio = _lowerBoundAnchorRatio;
    decimals = _decimals;
    s_description = _description;
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

  /**
   * @notice triggers a new run of the offchain reporting protocol
   * @param transmitters ith element is address ith oracle uses to transmit a report via the transmit method
   */
  event TransmittersAdded(
    address[] transmitters
  );

  event AnchorRatioUpdated(int256 upperBoundAnchorRatio, int256 lowerBoundAnchorRatio);

  modifier onlyTransmitter {
    require(s_transmitters[msg.sender].active, "Only callable by Transmitter");
    _;
  }

  function setAnchorRatio(
    int8 _upperBoundAnchorRatio,
    int8 _lowerBoundAnchorRatio
  )
  external
  onlyOwner()
  {

    require(minLowerBoundAnchorRatio <= _lowerBoundAnchorRatio, "lowerBoundAnchorRatio must greater or equal to minLowerBoundAnchorRatio");
    require(maxUpperBoundAnchorRatio >= _upperBoundAnchorRatio, "upperBoundAnchorRatio must Less than or equal to maxUpperBoundAnchorRatio");
    require(_upperBoundAnchorRatio > _lowerBoundAnchorRatio, "upperBoundAnchorRatio must Less than lowerBoundAnchorRatio");

    upperBoundAnchorRatio = _upperBoundAnchorRatio;
    lowerBoundAnchorRatio = _lowerBoundAnchorRatio;

    emit AnchorRatioUpdated(upperBoundAnchorRatio, lowerBoundAnchorRatio);
  }

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

  function transmitWithForce(
    int192 median,
    uint32 observationsTimestamp
  )
  onlyTransmitter()
  external
  {
    _transmit(median,observationsTimestamp);
  }

  function transmit(
    bytes calldata _report,
    // ECDSA signatures
    bytes32 _rs,
    bytes32 _ss,
    uint8 _vs
  )
  external
  onlyTransmitter()
  {
    // Verify signatures attached to report
    int192 median;
    uint32 observationsTimestamp;
    (median, observationsTimestamp) = abi.decode(_report, (int192, uint32));
    bytes32 h = keccak256(_report);

    Signer memory signer;
    address signerAddress = ecrecover(h, _vs+27, _rs, _ss);
    signer = s_signers[signerAddress];
    require(signer.active, "signature error");

    int256 previousAnswer=s_transmissions[s_hotVars.latestAggregatorRoundId].answer;
    if(previousAnswer>0){
      int256 maxAnswer = previousAnswer.mul(upperBoundAnchorRatio).div(1e2);
      int256 minAnswer = previousAnswer.mul(lowerBoundAnchorRatio).div(1e2);

      require(minAnswer <= median && median <= maxAnswer, "median is out of min-max range");
    }

    _transmit(median,observationsTimestamp);
  }

  function _transmit(
    int192 median,
    uint32 observationsTimestamp
  ) internal {
    HotVars memory r_hotVars = s_hotVars; // cache read from storage
    r_hotVars.latestAggregatorRoundId++;
    s_transmissions[r_hotVars.latestAggregatorRoundId] =
    Transmission({
      answer: median,
      observationsTimestamp: observationsTimestamp,
      transmissionTimestamp: uint32(block.timestamp)
    });

    emit NewTransmission(
      r_hotVars.latestAggregatorRoundId,
      median,
      msg.sender,
      observationsTimestamp
    );
    // Emit these for backwards compatability with offchain consumers
    // that only support legacy events
    emit NewRound(
      r_hotVars.latestAggregatorRoundId,
      address(0x0), // use zero address since we don't have anybody "starting" the round here
      observationsTimestamp
    );
    emit AnswerUpdated(
      median,
      r_hotVars.latestAggregatorRoundId,
      block.timestamp
    );
    s_hotVars = r_hotVars;
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
   * @notice Aggregator round (NOT OCR round) in which last report was transmitted 发送的最后轮次 不是ocr轮次
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "./SimpleWriteAccessController.sol";

/**
 * @title SimpleReadAccessController
 * @notice Gives access to:
 * - any externally owned account (note that off-chain actors can always read
 * any contract storage regardless of on-chain access control measures, so this
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
  function hasAccess(address _user, bytes memory _calldata) public view virtual override returns (bool) {
    return super.hasAccess(_user, _calldata) || _user == tx.origin;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AccessControllerInterface {
  function hasAccess(address user, bytes calldata data) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

abstract contract TypeAndVersionInterface{
  function typeAndVersion()
    external
    pure
    virtual
    returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ConfirmedOwner.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
    constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./interfaces/OwnableInterface.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface OwnableInterface {
    function owner() external returns (address);

    function transferOwnership(address recipient) external;

    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./OwnerIsCreator.sol";
import "./interfaces/AccessControllerInterface.sol";

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
  function hasAccess(address _user, bytes memory) public view virtual override returns (bool) {
    return accessList[_user] || !checkEnabled;
  }

  /**
   * @notice Adds an address to the access list
   * @param _user The address to add
   */
  function addAccess(address _user) external onlyOwner {
    if (!accessList[_user]) {
      accessList[_user] = true;

      emit AddedAccess(_user);
    }
  }

  /**
   * @notice Removes an address from the access list
   * @param _user The address to remove
   */
  function removeAccess(address _user) external onlyOwner {
    if (accessList[_user]) {
      accessList[_user] = false;

      emit RemovedAccess(_user);
    }
  }

  /**
   * @notice makes the access check enforced
   */
  function enableAccessCheck() external onlyOwner {
    if (!checkEnabled) {
      checkEnabled = true;

      emit CheckAccessEnabled();
    }
  }

  /**
   * @notice makes the access check unenforced
   */
  function disableAccessCheck() external onlyOwner {
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