// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./AccessControllerInterface.sol";
import "./AggregatorV2V3Interface.sol";
import "./Owned.sol";
import "./SimpleWriteAccessController.sol";

/**
  * @notice Onchain verification of reports from the offchain reporting protocol

  * @dev For details on its operation, see the offchain reporting protocol design
  * @dev doc, which refers to this contract as simply the "contract".
*/
contract OffchainAggregator is Owned, AggregatorV2V3Interface, SimpleWriteAccessController {

  struct Transmission {
    int192 answer; // 192 bits ought to be enough for anyone
    uint64 timestamp;
  }

  Transmission transmission;

  constructor(
    uint8 _decimals,
    string memory _description
  )
  {
    decimals = _decimals;
    s_description = _description;
  }

  event NewTransmission(
    address transmitter,
    int192 answer,
    uint64 timestamp
  );

  function transmit(int192 _answer)
    external
    checkAccess
  {
    transmission = Transmission(_answer, uint64(block.timestamp));

    emit NewTransmission(
      msg.sender,
      _answer,
      uint64(block.timestamp)
    );
  }

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
    return transmission.answer;
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
    return transmission.timestamp;
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
    revert("The function is not available");
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
    revert("The function is not available");
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
    revert("The function is not available");
  }

  /*
   * v3 Aggregator interface
   */

  string constant private V3_NO_DATA_ERROR = "No data present";

  uint8 immutable public override decimals;


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
    revert("The function is not available");
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
    revert("The function is not available");
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

/**
 * @title The Owned contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract Owned {

  address payable public owner;
  address private pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address _to)
  external
  onlyOwner()
  {
    pendingOwner = _to;

    emit OwnershipTransferRequested(owner, _to);
  }

  /**
   * @dev Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
  external
  {
    require(msg.sender == pendingOwner, "Must be proposed owner");

    address oldOwner = owner;
    owner = msg.sender;
    pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @dev Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Only callable by owner");
    _;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Owned.sol";
import "./AccessControllerInterface.sol";

/**
 * @title SimpleWriteAccessController
 * @notice Gives access to accounts explicitly added to an access list by the
 * controller's owner.
 * @dev does not make any special permissions for externally, see
 * SimpleReadAccessController for that.
 */
contract SimpleWriteAccessController is AccessControllerInterface, Owned {

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