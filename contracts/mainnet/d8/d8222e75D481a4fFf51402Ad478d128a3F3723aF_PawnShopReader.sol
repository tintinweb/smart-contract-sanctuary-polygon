// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "../base/governance/ControllableV2.sol";
import "../infrastructure/price/IPriceCalculator.sol";
import "../loan/ITetuPawnShop.sol";
import "../openzeppelin/Math.sol";

/// @title View data reader for using on website UI and other integrations
/// @author belbix
contract PawnShopReader is Initializable, ControllableV2 {

  string public constant VERSION = "1.0.1";
  uint256 constant public PRECISION = 1e18;
  string private constant _CALCULATOR = "calculator";
  string private constant _SHOP = "shop";

  // DO NOT CHANGE NAMES OR ORDERING!
  mapping(bytes32 => address) internal tools;

  function initialize(address _controller, address _calculator, address _pawnshop) external initializer {
    ControllableV2.initializeControllable(_controller);
    tools[keccak256(abi.encodePacked(_CALCULATOR))] = _calculator;
    tools[keccak256(abi.encodePacked(_SHOP))] = _pawnshop;
  }

  /// @dev Allow operation only for Controller or Governance
  modifier onlyControllerOrGovernance() {
    require(_isController(msg.sender) || _isGovernance(msg.sender), "Not controller or gov");
    _;
  }

  event ToolAddressUpdated(string name, address newValue);

  // ************** READ FUNCTIONS **************

  function positions(uint256 from, uint256 to) external view returns (ITetuPawnShop.Position[] memory){
    uint256 size = pawnshop().positionCounter();
    if (size == 1) {
      return new ITetuPawnShop.Position[](0);
    }
    if (from == 0) {
      from = 1;
    }
    to = Math.min(size - 1, to);
    ITetuPawnShop.Position[] memory result = new ITetuPawnShop.Position[](to - from + 1);

    uint256 j = 0;
    for (uint256 i = from; i <= to; i++) {
      result[j] = pawnshop().getPosition(i);
      j++;
    }

    return result;
  }

  function openPositions(uint256 from, uint256 to) external view returns (ITetuPawnShop.Position[] memory){
    uint256 size = pawnshop().openPositionsSize();
    if (size == 0) {
      return new ITetuPawnShop.Position[](0);
    }
    to = Math.min(size - 1, to);
    ITetuPawnShop.Position[] memory result = new ITetuPawnShop.Position[](to - from + 1);

    uint256 j = 0;
    for (uint256 i = from; i <= to; i++) {
      result[j] = pawnshop().getPosition(pawnshop().openPositions(i));
      j++;
    }

    return result;
  }

  function positionsByCollateral(
    address collateral,
    uint256 from,
    uint256 to
  ) external view returns (ITetuPawnShop.Position[] memory){
    uint256 size = pawnshop().positionsByCollateralSize(collateral);
    if (size == 0) {
      return new ITetuPawnShop.Position[](0);
    }
    to = Math.min(size - 1, to);
    ITetuPawnShop.Position[] memory result = new ITetuPawnShop.Position[](to - from + 1);

    uint256 j = 0;
    for (uint256 i = from; i <= to; i++) {
      result[j] = pawnshop().getPosition(pawnshop().positionsByCollateral(collateral, i));
      j++;
    }

    return result;
  }

  function positionsByAcquired(
    address acquired,
    uint256 from,
    uint256 to
  ) external view returns (ITetuPawnShop.Position[] memory){
    uint256 size = pawnshop().positionsByAcquiredSize(acquired);
    if (size == 0) {
      return new ITetuPawnShop.Position[](0);
    }
    to = Math.min(size - 1, to);
    ITetuPawnShop.Position[] memory result = new ITetuPawnShop.Position[](to - from + 1);

    uint256 j = 0;
    for (uint256 i = from; i <= to; i++) {
      result[j] = pawnshop().getPosition(pawnshop().positionsByAcquired(acquired, i));
      j++;
    }

    return result;
  }

  function borrowerPositions(
    address borrower,
    uint256 from,
    uint256 to
  ) external view returns (ITetuPawnShop.Position[] memory){
    uint256 size = pawnshop().borrowerPositionsSize(borrower);
    if (size == 0) {
      return new ITetuPawnShop.Position[](0);
    }
    to = Math.min(size - 1, to);
    ITetuPawnShop.Position[] memory result = new ITetuPawnShop.Position[](to - from + 1);

    uint256 j = 0;
    for (uint256 i = from; i <= to; i++) {
      result[j] = pawnshop().getPosition(pawnshop().borrowerPositions(borrower, i));
      j++;
    }

    return result;
  }

  function lenderPositions(
    address lender,
    uint256 from,
    uint256 to
  ) external view returns (ITetuPawnShop.Position[] memory){
    uint256 size = pawnshop().lenderPositionsSize(lender);
    if (size == 0) {
      return new ITetuPawnShop.Position[](0);
    }
    to = Math.min(size - 1, to);
    ITetuPawnShop.Position[] memory result = new ITetuPawnShop.Position[](to - from + 1);

    uint256 j = 0;
    for (uint256 i = from; i <= to; i++) {
      result[j] = pawnshop().getPosition(pawnshop().lenderPositions(lender, i));
      j++;
    }

    return result;
  }

  function auctionBids(uint256 from, uint256 to) external view returns (ITetuPawnShop.AuctionBid[] memory){
    uint256 size = pawnshop().auctionBidCounter();
    if (size == 1) {
      return new ITetuPawnShop.AuctionBid[](0);
    }
    if (from == 0) {
      from = 1;
    }
    to = Math.min(size - 1, to);
    ITetuPawnShop.AuctionBid[] memory result = new ITetuPawnShop.AuctionBid[](to - from + 1);

    uint256 j = 0;
    for (uint256 i = from; i <= to; i++) {
      result[j] = pawnshop().getAuctionBid(i);
      j++;
    }

    return result;
  }

  function lenderAuctionBid(address lender, uint256 posId) external view returns (ITetuPawnShop.AuctionBid memory){
    uint256 index = pawnshop().lenderOpenBids(lender, posId) - 1;
    uint256 bidId = pawnshop().positionToBidIds(posId, index);
    return pawnshop().getAuctionBid(bidId);
  }

  function positionAuctionBids(uint256 posId, uint256 from, uint256 to) external view returns (ITetuPawnShop.AuctionBid[] memory){
    uint256 size = pawnshop().auctionBidSize(posId);
    if (size == 0) {
      return new ITetuPawnShop.AuctionBid[](0);
    }
    to = Math.min(size - 1, to);
    ITetuPawnShop.AuctionBid[] memory result = new ITetuPawnShop.AuctionBid[](to - from + 1);

    uint256 j = 0;
    for (uint256 i = from; i <= to; i++) {
      result[j] = pawnshop().getAuctionBid(pawnshop().positionToBidIds(posId, i));
      j++;
    }

    return result;
  }

  // ******************** COMMON VIEWS ********************

  // normalized precision
  //noinspection NoReturn
  function getPrice(address _token) public view returns (uint256) {
    //slither-disable-next-line unused-return,variable-scope,uninitialized-local
    try priceCalculator().getPriceWithDefaultOutput(_token) returns (uint256 price){
      return price;
    } catch {
      return 0;
    }
  }

  function normalizePrecision(uint256 amount, uint256 decimals) internal pure returns (uint256){
    return amount * PRECISION / (10 ** decimals);
  }

  function priceCalculator() public view returns (IPriceCalculator) {
    return IPriceCalculator(tools[keccak256(abi.encodePacked(_CALCULATOR))]);
  }

  function pawnshop() public view returns (ITetuPawnShop) {
    return ITetuPawnShop(tools[keccak256(abi.encodePacked(_SHOP))]);
  }

  // *********** GOVERNANCE ACTIONS *****************

  function setPriceCalculator(address newValue) external onlyControllerOrGovernance {
    tools[keccak256(abi.encodePacked(_CALCULATOR))] = newValue;
    emit ToolAddressUpdated(_CALCULATOR, newValue);
  }

  function setPawnShop(address newValue) external onlyControllerOrGovernance {
    tools[keccak256(abi.encodePacked(_SHOP))] = newValue;
    emit ToolAddressUpdated(_SHOP, newValue);
  }

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "../../openzeppelin/Initializable.sol";
import "../interface/IControllable.sol";
import "../interface/IControllableExtended.sol";
import "../interface/IController.sol";

/// @title Implement basic functionality for any contract that require strict control
///        V2 is optimised version for less gas consumption
/// @dev Can be used with upgradeable pattern.
///      Require call initializeControllable() in any case.
/// @author belbix
abstract contract ControllableV2 is Initializable, IControllable, IControllableExtended {

  bytes32 internal constant _CONTROLLER_SLOT = bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1);
  bytes32 internal constant _CREATED_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created")) - 1);
  bytes32 internal constant _CREATED_BLOCK_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created_block")) - 1);

  event ContractInitialized(address controller, uint ts, uint block);

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param __controller Controller address
  function initializeControllable(address __controller) public initializer {
    _setController(__controller);
    _setCreated(block.timestamp);
    _setCreatedBlock(block.number);
    emit ContractInitialized(__controller, block.timestamp, block.number);
  }

  /// @dev Return true if given address is controller
  function isController(address _value) external override view returns (bool) {
    return _isController(_value);
  }

  function _isController(address _value) internal view returns (bool) {
    return _value == _controller();
  }

  /// @notice Return true if given address is setup as governance in Controller
  function isGovernance(address _value) external override view returns (bool) {
    return _isGovernance(_value);
  }

  function _isGovernance(address _value) internal view returns (bool) {
    return IController(_controller()).governance() == _value;
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  function controller() external view override returns (address) {
    return _controller();
  }

  function _controller() internal view returns (address result) {
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Set a controller address to contract slot
  function _setController(address _newController) private {
    require(_newController != address(0));
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      sstore(slot, _newController)
    }
  }

  /// @notice Return creation timestamp
  /// @return ts Creation timestamp
  function created() external view override returns (uint256 ts) {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      ts := sload(slot)
    }
  }

  /// @dev Filled only once when contract initialized
  /// @param _value block.timestamp
  function _setCreated(uint256 _value) private {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      sstore(slot, _value)
    }
  }

  /// @notice Return creation block number
  /// @return ts Creation block number
  function createdBlock() external view returns (uint256 ts) {
    bytes32 slot = _CREATED_BLOCK_SLOT;
    assembly {
      ts := sload(slot)
    }
  }

  /// @dev Filled only once when contract initialized
  /// @param _value block.number
  function _setCreatedBlock(uint256 _value) private {
    bytes32 slot = _CREATED_BLOCK_SLOT;
    assembly {
      sstore(slot, _value)
    }
  }

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IPriceCalculator {

  function getPrice(address token, address outputToken) external view returns (uint256);

  function getPriceWithDefaultOutput(address token) external view returns (uint256);

  function getLargestPool(address token, address[] memory usedLps) external view returns (address, uint256, address);

  function getPriceFromLp(address lpAddress, address token) external view returns (uint256);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

/// @title Interface for Tetu PawnShop contract
/// @author belbix
interface ITetuPawnShop {

  event PositionOpened(
    uint256 posId,
    address collateralToken,
    uint256 collateralAmount,
    uint256 collateralTokenId,
    address acquiredToken,
    uint256 acquiredAmount,
    uint256 posDurationBlocks,
    uint256 posFee
  );
  event PositionClosed(uint256 posId);
  event BidExecuted(
    uint256 posId,
    uint256 bidId,
    uint256 amount,
    address acquiredMoneyHolder,
    address lender
  );
  event AuctionBidOpened(uint256 posId, uint256 bidId, uint256 amount, address lender);
  event PositionClaimed(uint256 posId);
  event PositionRedeemed(uint256 posId);
  event AuctionBidAccepted(uint256 posId, uint256 bidId);
  event AuctionBidClosed(uint256 posId, uint256 bidId);
  event GovernanceActionAnnounced(uint256 id, address addressValue, uint256 uintValue);
  event OwnerChanged(address oldOwner, address newOwner);
  event FeeRecipientChanged(address oldRecipient, address newRecipient);
  event PlatformFeeChanged(uint256 oldFee, uint256 newFee);
  event DepositAmountChanged(uint256 oldAmount, uint256 newAmount);
  event DepositTokenChanged(address oldToken, address newToken);

  enum GovernanceAction {
    ChangeOwner, // 0
    ChangeFeeRecipient, // 1
    ChangePlatformFee, // 2
    ChangePositionDepositAmount, // 3
    ChangePositionDepositToken // 4
  }

  enum AssetType {
    ERC20, // 0
    ERC721 // 1
  }

  enum IndexType {
    LIST, // 0
    BY_COLLATERAL, // 1
    BY_ACQUIRED, // 2
    BORROWER_POSITION, // 3
    LENDER_POSITION // 4
  }

  struct TimeLock {
    uint256 time;
    address addressValue;
    uint256 uintValue;
  }

  struct Position {
    uint256 id;
    address borrower;
    address depositToken;
    uint256 depositAmount;
    bool open;
    PositionInfo info;
    PositionCollateral collateral;
    PositionAcquired acquired;
    PositionExecution execution;
  }

  struct PositionInfo {
    uint256 posDurationBlocks;
    uint256 posFee;
    uint256 createdBlock;
    uint256 createdTs;
  }

  struct PositionCollateral {
    address collateralToken;
    AssetType collateralType;
    uint256 collateralAmount;
    uint256 collateralTokenId;
  }

  struct PositionAcquired {
    address acquiredToken;
    uint256 acquiredAmount;
  }

  struct PositionExecution {
    address lender;
    uint256 posStartBlock;
    uint256 posStartTs;
    uint256 posEndTs;
  }

  struct AuctionBid {
    uint256 id;
    uint256 posId;
    address lender;
    uint256 amount;
    bool open;
  }

  // ****************** VIEWS ****************************

  /// @dev PosId counter. Should start from 1 for keep 0 as empty value
  function positionCounter() external view returns (uint256);

  /// @notice Return Position for given id
  /// @dev AbiEncoder not able to auto generate functions for mapping with structs
  function getPosition(uint256 posId) external view returns (Position memory);

  /// @dev Hold open positions ids. Removed when position closed
  function openPositions(uint256 index) external view returns (uint256 posId);

  /// @dev Collateral token => PosIds
  function positionsByCollateral(address collateralToken, uint256 index) external view returns (uint256 posId);

  /// @dev Acquired token => PosIds
  function positionsByAcquired(address acquiredToken, uint256 index) external view returns (uint256 posId);

  /// @dev Borrower token => PosIds
  function borrowerPositions(address borrower, uint256 index) external view returns (uint256 posId);

  /// @dev Lender token => PosIds
  function lenderPositions(address lender, uint256 index) external view returns (uint256 posId);

  /// @dev index type => PosId => index
  ///      Hold array positions for given type of array
  function posIndexes(IndexType typeId, uint256 posId) external view returns (uint256 index);

  /// @dev BidId counter. Should start from 1 for keep 0 as empty value
  function auctionBidCounter() external view returns (uint256);

  /// @notice Return auction bid for given id
  /// @dev AbiEncoder not able to auto generate functions for mapping with structs
  function getAuctionBid(uint256 bidId) external view returns (AuctionBid memory);

  /// @dev lender => PosId => positionToBidIds + 1
  ///      Lender auction position for given PosId. 0 keep for empty position
  function lenderOpenBids(address lender, uint256 posId) external view returns (uint256 index);

  /// @dev PosId => bidIds. All open and close bids for the given position
  function positionToBidIds(uint256 posId, uint256 index) external view returns (uint256 bidId);

  /// @dev PosId => timestamp. Timestamp of the last bid for the auction
  function lastAuctionBidTs(uint256 posId) external view returns (uint256 ts);

  /// @dev Return amount required for redeem position
  function toRedeem(uint256 posId) external view returns (uint256 amount);

  /// @dev Return asset type ERC20 or ERC721
  function getAssetType(address _token) external view returns (AssetType);

  function isERC721(address _token) external view returns (bool);

  function isERC20(address _token) external view returns (bool);

  /// @dev Return size of active positions
  function openPositionsSize() external view returns (uint256);

  /// @dev Return size of all auction bids for given position
  function auctionBidSize(uint256 posId) external view returns (uint256);

  function positionsByCollateralSize(address collateral) external view returns (uint256);

  function positionsByAcquiredSize(address acquiredToken) external view returns (uint256);

  function borrowerPositionsSize(address borrower) external view returns (uint256);

  function lenderPositionsSize(address lender) external view returns (uint256);

  // ************* USER ACTIONS *************

  /// @dev Borrower action. Assume approve
  ///      Open a position with multiple options - loan / instant deal / auction
  function openPosition(
    address _collateralToken,
    uint256 _collateralAmount,
    uint256 _collateralTokenId,
    address _acquiredToken,
    uint256 _acquiredAmount,
    uint256 _posDurationBlocks,
    uint256 _posFee
  ) external returns (uint256);

  /// @dev Borrower action
  ///      Close not executed position. Return collateral and deposit to borrower
  function closePosition(uint256 id) external;

  /// @dev Lender action. Assume approve for acquired token
  ///      Place a bid for given position ID
  ///      It can be an auction bid if acquired amount is zero
  function bid(uint256 id, uint256 amount) external;

  /// @dev Lender action
  ///      Transfer collateral to lender if borrower didn't return the loan
  ///      Deposit will be returned to borrower
  function claim(uint256 id) external;

  /// @dev Borrower action. Assume approve on acquired token
  ///      Return the loan to lender, transfer collateral and deposit to borrower
  function redeem(uint256 id) external;

  /// @dev Borrower action. Assume that auction ended.
  ///      Transfer acquired token to borrower
  function acceptAuctionBid(uint256 posId) external;

  /// @dev Lender action. Requires ended auction, or not the last bid
  ///      Close auction bid and transfer acquired tokens to lender
  function closeAuctionBid(uint256 bidId) external;

  /// @dev Announce governance action
  function announceGovernanceAction(GovernanceAction id, address addressValue, uint256 uintValue) external;

  /// @dev Set new contract owner
  function setOwner(address _newOwner) external;

  /// @dev Set new fee recipient
  function setFeeRecipient(address _newFeeRecipient) external;

  /// @dev Platform fee in range 0 - 500, with denominator 10000
  function setPlatformFee(uint256 _value) external;

  /// @dev Tokens amount that need to deposit for a new position
  ///      Will be returned when position closed
  function setPositionDepositAmount(uint256 _value) external;

  /// @dev Tokens that need to deposit for a new position
  function setPositionDepositToken(address _value) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
  /**
   * @dev Returns the largest of two numbers.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  /**
   * @dev Returns the smallest of two numbers.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * @dev Returns the average of two numbers. The result is rounded towards
   * zero.
   */
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow.
    return (a & b) + (a ^ b) / 2;
  }

  /**
   * @dev Returns the ceiling of the division of two numbers.
   *
   * This differs from standard division with `/` in that it rounds up instead
   * of rounding down.
   */
  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b - 1) / b can overflow on addition, so we distribute.
    return a / b + (a % b == 0 ? 0 : 1);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private _initializing;

  /**
   * @dev Modifier to protect an initializer function from being invoked twice.
   */
  modifier initializer() {
    require(_initializing || !_initialized, "Initializable: contract is already initialized");

    bool isTopLevelCall = !_initializing;
    if (isTopLevelCall) {
      _initializing = true;
      _initialized = true;
    }

    _;

    if (isTopLevelCall) {
      _initializing = false;
    }
  }
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

/// @dev This interface contains additional functions for Controllable class
///      Don't extend the exist Controllable for the reason of huge coherence
interface IControllableExtended {

  function created() external view returns (uint256 ts);

  function controller() external view returns (address adr);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IController {

  function addVaultsAndStrategies(address[] memory _vaults, address[] memory _strategies) external;

  function addStrategy(address _strategy) external;

  function governance() external view returns (address);

  function dao() external view returns (address);

  function bookkeeper() external view returns (address);

  function feeRewardForwarder() external view returns (address);

  function mintHelper() external view returns (address);

  function rewardToken() external view returns (address);

  function fundToken() external view returns (address);

  function psVault() external view returns (address);

  function fund() external view returns (address);

  function distributor() external view returns (address);

  function announcer() external view returns (address);

  function vaultController() external view returns (address);

  function whiteList(address _target) external view returns (bool);

  function vaults(address _target) external view returns (bool);

  function strategies(address _target) external view returns (bool);

  function psNumerator() external view returns (uint256);

  function psDenominator() external view returns (uint256);

  function fundNumerator() external view returns (uint256);

  function fundDenominator() external view returns (uint256);

  function isAllowedUser(address _adr) external view returns (bool);

  function isDao(address _adr) external view returns (bool);

  function isHardWorker(address _adr) external view returns (bool);

  function isRewardDistributor(address _adr) external view returns (bool);

  function isPoorRewardConsumer(address _adr) external view returns (bool);

  function isValidVault(address _vault) external view returns (bool);

  function isValidStrategy(address _strategy) external view returns (bool);

  function rebalance(address _strategy) external;

  // ************ DAO ACTIONS *************
  function setPSNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function setFundNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function changeWhiteListStatus(address[] calldata _targets, bool status) external;
}