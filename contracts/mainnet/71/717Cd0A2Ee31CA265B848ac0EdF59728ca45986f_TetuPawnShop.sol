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

// use copies of openzeppelin contracts with changed names for avoid dependency issues
import "../openzeppelin/ERC721Holder.sol";
import "../openzeppelin/IERC721.sol";
import "../openzeppelin/SafeERC20.sol";
import "../openzeppelin/IERC20.sol";
import "../openzeppelin/ReentrancyGuard.sol";
import "../base/ArrayLib.sol";
import "./ITetuPawnShop.sol";

/// @title Contract for handling deals between two parties
/// @author belbix
contract TetuPawnShop is ERC721Holder, ReentrancyGuard, ITetuPawnShop {
  using SafeERC20 for IERC20;
  using ArrayLib for uint256[];

  // ---- CONSTANTS

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant VERSION = "1.0.2";
  /// @dev Time lock for any governance actions
  uint256 constant public TIME_LOCK = 2 days;
  /// @dev Denominator for any internal computation with low precision
  uint256 constant public DENOMINATOR = 10000;
  /// @dev Governance can't set fee more than this value
  uint256 constant public PLATFORM_FEE_MAX = 500; // 5%
  /// @dev Standard auction duration that refresh when a new bid placed
  uint256 constant public AUCTION_DURATION = 1 days;
  /// @dev Timestamp date when contract created
  uint256 immutable createdTs;
  /// @dev Block number when contract created
  uint256 immutable createdBlock;

  // ---- CHANGEABLE VARIABLES

  /// @dev Contract owner. Should be a multi-signature wallet
  ///      On Polygon TETU msig gov wallet 3/4 is 0xcc16d636dD05b52FF1D8B9CE09B09BC62b11412B
  address public owner;
  /// @dev Fee recipient. Assume it will be a place with ability to manage different tokens
  address public feeRecipient;
  /// @dev 1% by default, percent of acquired tokens that will be used for buybacks
  uint256 public platformFee = 100;
  /// @dev Amount of tokens for open position. Protection against spam
  uint256 public positionDepositAmount;
  /// @dev Token for antispam protection. TETU assumed
  ///      Zero address means no protection
  address public positionDepositToken;
  /// @dev Time-locks for governance actions
  mapping(GovernanceAction => TimeLock) public timeLocks;

  // ---- POSITIONS

  /// @inheritdoc ITetuPawnShop
  uint256 public override positionCounter = 1;
  /// @dev PosId => Position. Hold all positions. Any record should not be removed
  mapping(uint256 => Position) public positions;
  /// @inheritdoc ITetuPawnShop
  uint256[] public override openPositions;
  /// @inheritdoc ITetuPawnShop
  mapping(address => uint256[]) public override positionsByCollateral;
  /// @inheritdoc ITetuPawnShop
  mapping(address => uint256[]) public override positionsByAcquired;
  /// @inheritdoc ITetuPawnShop
  mapping(address => uint256[]) public override borrowerPositions;
  /// @inheritdoc ITetuPawnShop
  mapping(address => uint256[]) public override lenderPositions;
  /// @inheritdoc ITetuPawnShop
  mapping(IndexType => mapping(uint256 => uint256)) public override posIndexes;

  // ---- AUCTION

  /// @inheritdoc ITetuPawnShop
  uint256 public override auctionBidCounter = 1;
  /// @dev BidId => Bid. Hold all bids. Any record should not be removed
  mapping(uint256 => AuctionBid) public auctionBids;
  /// @inheritdoc ITetuPawnShop
  mapping(address => mapping(uint256 => uint256)) public override lenderOpenBids;
  /// @inheritdoc ITetuPawnShop
  mapping(uint256 => uint256[]) public override positionToBidIds;
  /// @inheritdoc ITetuPawnShop
  mapping(uint256 => uint256) public override lastAuctionBidTs;

  /// @dev Tetu Controller address requires for governance actions
  constructor(address _owner, address _depositToken, uint _positionDepositAmount, address _feeRecipient) {
    require(_owner != address(0), "TPS: Zero owner");
    require(_feeRecipient != address(0), "TPS: Zero feeRecipient");
    owner = _owner;
    feeRecipient = _feeRecipient;
    positionDepositToken = _depositToken;
    createdTs = block.timestamp;
    createdBlock = block.number;
    positionDepositAmount = _positionDepositAmount;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "TPS: Not owner");
    _;
  }

  /// @dev Check time lock for governance actions and revert if conditions wrong
  modifier checkTimeLock(GovernanceAction action, address _address, uint256 _uint){
    TimeLock memory timeLock = timeLocks[action];
    require(timeLock.time != 0 && timeLock.time < block.timestamp, "TPS: Time Lock");
    if (_address != address(0)) {
      require(timeLock.addressValue == _address, "TPS: Wrong address value");
    }
    if (_uint != 0) {
      require(timeLock.uintValue == _uint, "TPS: Wrong uint value");
    }
    _;
    delete timeLocks[action];
  }

  // ************* USER ACTIONS *************

  /// @inheritdoc ITetuPawnShop
  function openPosition(
    address _collateralToken,
    uint256 _collateralAmount,
    uint256 _collateralTokenId,
    address _acquiredToken,
    uint256 _acquiredAmount,
    uint256 _posDurationBlocks,
    uint256 _posFee
  ) external nonReentrant override returns (uint256){
    require(_posFee <= DENOMINATOR * 10, "TPS: Pos fee absurdly high");
    require(_posDurationBlocks != 0 || _posFee == 0, "TPS: Fee for instant deal forbidden");
    require(_collateralAmount != 0 || _collateralTokenId != 0, "TPS: Wrong amounts");
    require(_collateralToken != address(0), "TPS: Zero cToken");
    require(_acquiredToken != address(0), "TPS: Zero aToken");

    Position memory pos;
    {
      PositionInfo memory info = PositionInfo(
        _posDurationBlocks,
        _posFee,
        block.number,
        block.timestamp
      );

      PositionCollateral memory collateral = PositionCollateral(
        _collateralToken,
        _getAssetType(_collateralToken),
        _collateralAmount,
        _collateralTokenId
      );

      PositionAcquired memory acquired = PositionAcquired(
        _acquiredToken,
        _acquiredAmount
      );

      PositionExecution memory execution = PositionExecution(
        address(0),
        0,
        0,
        0
      );

      pos = Position(
        positionCounter, // id
        msg.sender, // borrower
        positionDepositToken,
        positionDepositAmount,
        true, // open
        info,
        collateral,
        acquired,
        execution
      );
    }

    openPositions.push(pos.id);
    posIndexes[IndexType.LIST][pos.id] = openPositions.length - 1;

    positionsByCollateral[_collateralToken].push(pos.id);
    posIndexes[IndexType.BY_COLLATERAL][pos.id] = positionsByCollateral[_collateralToken].length - 1;

    positionsByAcquired[_acquiredToken].push(pos.id);
    posIndexes[IndexType.BY_ACQUIRED][pos.id] = positionsByAcquired[_acquiredToken].length - 1;

    borrowerPositions[msg.sender].push(pos.id);
    posIndexes[IndexType.BORROWER_POSITION][pos.id] = borrowerPositions[msg.sender].length - 1;

    positions[pos.id] = pos;
    positionCounter++;

    _takeDeposit(pos.id);
    _transferCollateral(pos.collateral, msg.sender, address(this));
    emit PositionOpened(
      pos.id,
      _collateralToken,
      _collateralAmount,
      _collateralTokenId,
      _acquiredToken,
      _acquiredAmount,
      _posDurationBlocks,
      _posFee
    );
    return pos.id;
  }

  /// @inheritdoc ITetuPawnShop
  function closePosition(uint256 id) external nonReentrant override {
    Position storage pos = positions[id];
    require(pos.id == id, "TPS: Wrong ID");
    require(pos.borrower == msg.sender, "TPS: Only borrower can close a position");
    require(pos.execution.lender == address(0), "TPS: Can't close executed position");
    require(pos.open, "TPS: Position closed");

    _removePosFromIndexes(pos);
    borrowerPositions[pos.borrower].removeIndexed(posIndexes[IndexType.BORROWER_POSITION], pos.id);

    _transferCollateral(pos.collateral, address(this), pos.borrower);
    _returnDeposit(id);
    pos.open = false;
    emit PositionClosed(id);
  }

  /// @inheritdoc ITetuPawnShop
  function bid(uint256 id, uint256 amount) external nonReentrant override {
    Position storage pos = positions[id];
    require(pos.id == id, "TPS: Wrong ID");
    require(pos.open, "TPS: Position closed");
    require(pos.execution.lender == address(0), "TPS: Can't bid executed position");
    if (pos.acquired.acquiredAmount != 0) {
      require(amount == pos.acquired.acquiredAmount, "TPS: Wrong bid amount");
      _executeBid(pos, amount, msg.sender, msg.sender);
    } else {
      _auctionBid(pos, amount, msg.sender);
    }
  }

  /// @inheritdoc ITetuPawnShop
  function claim(uint256 id) external nonReentrant override {
    Position storage pos = positions[id];
    require(pos.id == id, "TPS: Wrong ID");
    require(pos.execution.lender == msg.sender, "TPS: Only lender can claim");
    uint256 posEnd = pos.execution.posStartBlock + pos.info.posDurationBlocks;
    require(posEnd < block.number, "TPS: Too early to claim");
    require(pos.open, "TPS: Position closed");

    _endPosition(pos);
    _transferCollateral(pos.collateral, address(this), msg.sender);
    _returnDeposit(id);
    emit PositionClaimed(id);
  }

  /// @inheritdoc ITetuPawnShop
  function redeem(uint256 id) external nonReentrant override {
    Position storage pos = positions[id];
    require(pos.id == id, "TPS: Wrong ID");
    require(pos.borrower == msg.sender, "TPS: Only borrower can redeem");
    require(pos.execution.lender != address(0), "TPS: Not executed position");
    require(pos.open, "TPS: Position closed");

    _endPosition(pos);
    uint256 toSend = _toRedeem(id);
    IERC20(pos.acquired.acquiredToken).safeTransferFrom(msg.sender, pos.execution.lender, toSend);
    _transferCollateral(pos.collateral, address(this), msg.sender);
    _returnDeposit(id);
    emit PositionRedeemed(id);
  }

  /// @inheritdoc ITetuPawnShop
  function acceptAuctionBid(uint256 posId) external nonReentrant override {
    require(lastAuctionBidTs[posId] + AUCTION_DURATION < block.timestamp, "TPS: Auction not ended");
    require(positionToBidIds[posId].length > 0, "TPS: No bids");
    uint256 bidId = positionToBidIds[posId][positionToBidIds[posId].length - 1];

    AuctionBid storage _bid = auctionBids[bidId];
    require(_bid.id != 0, "TPS: Auction bid not found");
    require(_bid.open, "TPS: Bid closed");
    require(_bid.posId == posId, "TPS: Wrong bid");

    Position storage pos = positions[posId];
    require(pos.borrower == msg.sender, "TPS: Not borrower");
    require(pos.open, "TPS: Position closed");

    pos.acquired.acquiredAmount = _bid.amount;
    _executeBid(pos, _bid.amount, address(this), _bid.lender);
    lenderOpenBids[_bid.lender][pos.id] = 0;
    _bid.open = false;
    emit AuctionBidAccepted(posId, _bid.id);
  }

  /// @inheritdoc ITetuPawnShop
  function closeAuctionBid(uint256 bidId) external nonReentrant override {
    AuctionBid storage _bid = auctionBids[bidId];
    require(_bid.id != 0, "TPS: Auction bid not found");
    Position storage pos = positions[_bid.posId];

    bool isAuctionEnded = lastAuctionBidTs[pos.id] + AUCTION_DURATION < block.timestamp;
    bool isLastBid = false;
    if (positionToBidIds[pos.id].length != 0) {
      uint256 lastBidId = positionToBidIds[pos.id][positionToBidIds[pos.id].length - 1];
      isLastBid = lastBidId == bidId;
    }
    require((isLastBid && isAuctionEnded) || !isLastBid || !pos.open, "TPS: Auction is not ended");

    lenderOpenBids[_bid.lender][pos.id] = 0;
    _bid.open = false;
    IERC20(pos.acquired.acquiredToken).safeTransfer(msg.sender, _bid.amount);
    emit AuctionBidClosed(pos.id, bidId);
  }

  // ************* INTERNAL FUNCTIONS *************

  /// @dev Transfer to this contract a deposit
  function _takeDeposit(uint256 posId) internal {
    Position storage pos = positions[posId];
    if (pos.depositToken != address(0)) {
      IERC20(pos.depositToken).safeTransferFrom(pos.borrower, address(this), pos.depositAmount);
    }
  }

  /// @dev Return to borrower a deposit
  function _returnDeposit(uint256 posId) internal {
    Position storage pos = positions[posId];
    if (pos.depositToken != address(0)) {
      IERC20(pos.depositToken).safeTransfer(pos.borrower, pos.depositAmount);
    }
  }

  /// @dev Execute bid for the open position
  ///      Transfer acquired tokens to borrower
  ///      In case of instant deal transfer collateral to lender
  function _executeBid(
    Position storage pos,
    uint256 amount,
    address acquiredMoneyHolder,
    address lender
  ) internal {
    uint256 feeAmount = amount * platformFee / DENOMINATOR;
    uint256 toSend = amount - feeAmount;
    if (acquiredMoneyHolder == address(this)) {
      IERC20(pos.acquired.acquiredToken).safeTransfer(pos.borrower, toSend);
    } else {
      IERC20(pos.acquired.acquiredToken).safeTransferFrom(acquiredMoneyHolder, pos.borrower, toSend);
      IERC20(pos.acquired.acquiredToken).safeTransferFrom(acquiredMoneyHolder, address(this), feeAmount);
    }
    _transferFee(pos.acquired.acquiredToken, feeAmount);

    pos.execution.lender = lender;
    pos.execution.posStartBlock = block.number;
    pos.execution.posStartTs = block.timestamp;
    _removePosFromIndexes(pos);

    lenderPositions[lender].push(pos.id);
    posIndexes[IndexType.LENDER_POSITION][pos.id] = lenderPositions[lender].length - 1;

    // instant buy
    if (pos.info.posDurationBlocks == 0) {
      _transferCollateral(pos.collateral, address(this), lender);
      _endPosition(pos);
    }
    emit BidExecuted(
      pos.id,
      amount,
      acquiredMoneyHolder,
      lender
    );
  }

  /// @dev Open an auction bid
  ///      Transfer acquired token to this contract
  function _auctionBid(Position storage pos, uint256 amount, address lender) internal {
    require(lenderOpenBids[lender][pos.id] == 0, "TPS: Auction bid already exist");

    if (positionToBidIds[pos.id].length != 0) {
      // if we have bids need to check auction duration
      require(lastAuctionBidTs[pos.id] + AUCTION_DURATION > block.timestamp, "TPS: Auction ended");

      uint256 lastBidId = positionToBidIds[pos.id][positionToBidIds[pos.id].length - 1];
      AuctionBid storage lastBid = auctionBids[lastBidId];
      require(lastBid.amount * 110 / 100 < amount, "TPS: New bid lower than previous");
    }

    AuctionBid memory _bid = AuctionBid(
      auctionBidCounter,
      pos.id,
      lender,
      amount,
      true
    );

    positionToBidIds[pos.id].push(_bid.id);
    // write index + 1 for keep zero as empty value
    lenderOpenBids[lender][pos.id] = positionToBidIds[pos.id].length;

    IERC20(pos.acquired.acquiredToken).safeTransferFrom(msg.sender, address(this), amount);

    lastAuctionBidTs[pos.id] = block.timestamp;
    auctionBids[_bid.id] = _bid;
    auctionBidCounter++;
    emit AuctionBidOpened(pos.id, _bid.id, amount, lender);
  }

  /// @dev Finalize position. Remove position from indexes
  function _endPosition(Position storage pos) internal {
    require(pos.execution.posEndTs == 0, "TPS: Position claimed");
    pos.open = false;
    pos.execution.posEndTs = block.timestamp;
    borrowerPositions[pos.borrower].removeIndexed(posIndexes[IndexType.BORROWER_POSITION], pos.id);
    if (pos.execution.lender != address(0)) {
      lenderPositions[pos.execution.lender].removeIndexed(posIndexes[IndexType.LENDER_POSITION], pos.id);
    }

  }

  /// @dev Transfer collateral from sender to recipient
  function _transferCollateral(PositionCollateral memory _collateral, address _sender, address _recipient) internal {
    if (_collateral.collateralType == AssetType.ERC20) {
      if (_sender == address(this)) {
        IERC20(_collateral.collateralToken).safeTransfer(_recipient, _collateral.collateralAmount);
      } else {
        IERC20(_collateral.collateralToken).safeTransferFrom(_sender, _recipient, _collateral.collateralAmount);
      }
    } else if (_collateral.collateralType == AssetType.ERC721) {
      IERC721(_collateral.collateralToken).safeTransferFrom(_sender, _recipient, _collateral.collateralTokenId);
    } else {
      revert("TPS: Wrong asset type");
    }
  }

  /// @dev Transfer fee to platform. Assume that token inside this contract
  ///      Do buyback if possible, otherwise just send to controller for manual handling
  function _transferFee(address token, uint256 amount) internal {
    // little deals can have zero fees
    if (amount == 0) {
      return;
    }
    IERC20(token).safeTransfer(feeRecipient, amount);
  }

  /// @dev Remove position from common indexes
  function _removePosFromIndexes(Position memory _pos) internal {
    openPositions.removeIndexed(posIndexes[IndexType.LIST], _pos.id);
    positionsByCollateral[_pos.collateral.collateralToken].removeIndexed(posIndexes[IndexType.BY_COLLATERAL], _pos.id);
    positionsByAcquired[_pos.acquired.acquiredToken].removeIndexed(posIndexes[IndexType.BY_ACQUIRED], _pos.id);
  }

  // ************* VIEWS **************************

  /// @inheritdoc ITetuPawnShop
  function toRedeem(uint256 id) external view override returns (uint256){
    return _toRedeem(id);
  }

  function _toRedeem(uint256 id) private view returns (uint256){
    Position memory pos = positions[id];
    return pos.acquired.acquiredAmount +
    (pos.acquired.acquiredAmount * pos.info.posFee / DENOMINATOR);
  }

  /// @inheritdoc ITetuPawnShop
  function getAssetType(address _token) external view override returns (AssetType){
    return _getAssetType(_token);
  }

  function _getAssetType(address _token) private view returns (AssetType){
    if (_isERC721(_token)) {
      return AssetType.ERC721;
    } else if (_isERC20(_token)) {
      return AssetType.ERC20;
    } else {
      revert("TPS: Unknown asset");
    }
  }

  /// @dev Return true if given token is ERC721 token
  function isERC721(address _token) external view override returns (bool) {
    return _isERC721(_token);
  }

  //noinspection NoReturn
  function _isERC721(address _token) private view returns (bool) {
    //slither-disable-next-line unused-return,variable-scope,uninitialized-local
    try IERC721(_token).supportsInterface{gas : 30000}(type(IERC721).interfaceId) returns (bool result){
      return result;
    } catch {
      return false;
    }
  }

  /// @dev Return true if given token is ERC20 token
  function isERC20(address _token) external view override returns (bool) {
    return _isERC20(_token);
  }

  //noinspection NoReturn
  function _isERC20(address _token) private view returns (bool) {
    //slither-disable-next-line unused-return,variable-scope,uninitialized-local
    try IERC20(_token).totalSupply{gas : 30000}() returns (uint256){
      return true;
    } catch {
      return false;
    }
  }

  /// @inheritdoc ITetuPawnShop
  function openPositionsSize() external view override returns (uint256) {
    return openPositions.length;
  }

  /// @inheritdoc ITetuPawnShop
  function auctionBidSize(uint256 posId) external view override returns (uint256) {
    return positionToBidIds[posId].length;
  }

  function positionsByCollateralSize(address collateral) external view override returns (uint256) {
    return positionsByCollateral[collateral].length;
  }

  function positionsByAcquiredSize(address acquiredToken) external view override returns (uint256) {
    return positionsByAcquired[acquiredToken].length;
  }

  function borrowerPositionsSize(address borrower) external view override returns (uint256) {
    return borrowerPositions[borrower].length;
  }

  function lenderPositionsSize(address lender) external view override returns (uint256) {
    return lenderPositions[lender].length;
  }

  /// @inheritdoc ITetuPawnShop
  function getPosition(uint256 posId) external view override returns (Position memory) {
    return positions[posId];
  }

  /// @inheritdoc ITetuPawnShop
  function getAuctionBid(uint256 bidId) external view override returns (AuctionBid memory) {
    return auctionBids[bidId];
  }

  // ************* GOVERNANCE ACTIONS *************

  /// @inheritdoc ITetuPawnShop
  function announceGovernanceAction(
    GovernanceAction id,
    address addressValue,
    uint256 uintValue
  ) external onlyOwner override {
    require(timeLocks[id].time == 0, "TPS: Already announced");
    timeLocks[id] = TimeLock(
      block.timestamp + TIME_LOCK,
      addressValue,
      uintValue
    );
    emit GovernanceActionAnnounced(uint256(id), addressValue, uintValue);
  }

  /// @inheritdoc ITetuPawnShop
  function setOwner(address _newOwner) external onlyOwner override
  checkTimeLock(GovernanceAction.ChangeOwner, _newOwner, 0) {
    require(_newOwner != address(0), "TPS: Zero address");
    emit OwnerChanged(owner, _newOwner);
    owner = _newOwner;
  }

  /// @inheritdoc ITetuPawnShop
  function setFeeRecipient(address _newFeeRecipient) external onlyOwner override
  checkTimeLock(GovernanceAction.ChangeFeeRecipient, _newFeeRecipient, 0) {
    require(_newFeeRecipient != address(0), "TPS: Zero address");
    emit FeeRecipientChanged(feeRecipient, _newFeeRecipient);
    feeRecipient = _newFeeRecipient;
  }

  /// @inheritdoc ITetuPawnShop
  function setPlatformFee(uint256 _value) external onlyOwner override
  checkTimeLock(GovernanceAction.ChangePlatformFee, address(0), _value) {
    require(_value <= PLATFORM_FEE_MAX, "TPS: Too high fee");
    emit PlatformFeeChanged(platformFee, _value);
    platformFee = _value;
  }

  /// @inheritdoc ITetuPawnShop
  function setPositionDepositAmount(uint256 _value) external onlyOwner override
  checkTimeLock(GovernanceAction.ChangePositionDepositAmount, address(0), _value) {
    emit DepositAmountChanged(positionDepositAmount, _value);
    positionDepositAmount = _value;
  }

  /// @inheritdoc ITetuPawnShop
  function setPositionDepositToken(address _value) external onlyOwner override
  checkTimeLock(GovernanceAction.ChangePositionDepositToken, _value, 0) {
    emit DepositTokenChanged(positionDepositToken, _value);
    positionDepositToken = _value;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
  /**
   * @dev See {IERC721Receiver-onERC721Received}.
   *
   * Always returns `IERC721Receiver.onERC721Received.selector`.
   */
  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
  /**
   * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
   */
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
   */
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
   */
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /**
   * @dev Returns the number of tokens in ``owner``'s account.
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  /**
   * @dev Returns the owner of the `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function ownerOf(uint256 tokenId) external view returns (address owner);

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Transfers `tokenId` token from `from` to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account.
   * The approval is cleared when the token is transferred.
   *
   * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
   *
   * Requirements:
   *
   * - The caller must own the token or be an approved operator.
   * - `tokenId` must exist.
   *
   * Emits an {Approval} event.
   */
  function approve(address to, uint256 tokenId) external;

  /**
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(uint256 tokenId) external view returns (address operator);

  /**
   * @dev Approve or remove `operator` as an operator for the caller.
   * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
   *
   * Requirements:
   *
   * - The `operator` cannot be the caller.
   *
   * Emits an {ApprovalForAll} event.
   */
  function setApprovalForAll(address operator, bool _approved) external;

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}
   */
  function isApprovedForAll(address owner, address operator) external view returns (bool);

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {IERC20-approve}, and its usage is discouraged.
   *
   * Whenever possible, use {safeIncreaseAllowance} and
   * {safeDecreaseAllowance} instead.
   */
  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
  unchecked {
    uint256 oldAllowance = token.allowance(address(this), spender);
    require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
    uint256 newAllowance = oldAllowance - value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   */
  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
  // Booleans are more expensive than uint256 or any type that takes up a full
  // word because each write operation emits an extra SLOAD to first read the
  // slot's contents, replace the bits taken up by the boolean, and then write
  // back. This is the compiler's defense against contract upgrades and
  // pointer aliasing, and it cannot be disabled.

  // The values being non-zero value makes deployment a bit more expensive,
  // but in exchange the refund on every call to nonReentrant will be lower in
  // amount. Since refunds are capped to a percentage of the total
  // transaction's gas, it is best to keep them low in cases like this one, to
  // increase the likelihood of the full refund coming into effect.
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor() {
    _status = _NOT_ENTERED;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and make it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
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

/// @title Library for useful functions for address and uin256 arrays
/// @author bogdoslav, belbix
library ArrayLib {

  string constant INDEX_OUT_OF_BOUND = "ArrayLib: Index out of bounds";
  string constant NOT_UNIQUE_ITEM = "ArrayLib: Not unique item";
  string constant ITEM_NOT_FOUND = "ArrayLib: Item not found";

  /// @dev Return true if given item found in address array
  function contains(address[] storage array, address _item) internal view returns (bool) {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == _item) return true;
    }
    return false;
  }

  /// @dev Return true if given item found in uin256 array
  function contains(uint256[] storage array, uint256 _item) internal view returns (bool) {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == _item) return true;
    }
    return false;
  }

  // -----------------------------------

  /// @dev If token not exist in the array push it, otherwise throw an error
  function addUnique(address[] storage array, address _item) internal {
    require(!contains(array, _item), NOT_UNIQUE_ITEM);
    array.push(_item);
  }

  /// @dev If token not exist in the array push it, otherwise throw an error
  function addUnique(uint256[] storage array, uint256 _item) internal {
    require(!contains(array, _item), NOT_UNIQUE_ITEM);
    array.push(_item);
  }

  // -----------------------------------

  /// @dev Call addUnique for the given items array
  function addUniqueArray(address[] storage array, address[] memory _items) internal {
    for (uint256 i = 0; i < _items.length; i++) {
      addUnique(array, _items[i]);
    }
  }

  /// @dev Call addUnique for the given items array
  function addUniqueArray(uint256[] storage array, uint256[] memory _items) internal {
    for (uint i = 0; i < _items.length; i++) {
      addUnique(array, _items[i]);
    }
  }

  // -----------------------------------

  /// @dev Remove an item by given index.
  /// @param keepSorting If true the function will shift elements to the place of removed item
  ///                    If false will move the last element on the place of removed item
  function removeByIndex(address[] storage array, uint256 index, bool keepSorting) internal {
    require(index < array.length, INDEX_OUT_OF_BOUND);

    if (keepSorting) {
      // shift all elements to the place of removed item
      // the loop must not include the last element
      for (uint256 i = index; i < array.length - 1; i++) {
        array[i] = array[i + 1];
      }
    } else {
      // copy the last address in the array
      array[index] = array[array.length - 1];
    }
    array.pop();
  }

  /// @dev Remove an item by given index.
  /// @param keepSorting If true the function will shift elements to the place of removed item
  ///                    If false will move the last element on the place of removed item
  function removeByIndex(uint256[] storage array, uint256 index, bool keepSorting) internal {
    require(index < array.length, INDEX_OUT_OF_BOUND);

    if (keepSorting) {
      // shift all elements to the place of removed item
      // the loop must not include the last element
      for (uint256 i = index; i < array.length - 1; i++) {
        array[i] = array[i + 1];
      }
    } else {
      // copy the last address in the array
      array[index] = array[array.length - 1];
    }
    array.pop();
  }

  // -----------------------------------

  /// @dev Find given item in the array and call removeByIndex function if exist. If not throw an error
  function findAndRemove(address[] storage array, address _item, bool keepSorting) internal {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == _item) {
        removeByIndex(array, i, keepSorting);
        return;
      }
    }
    revert(ITEM_NOT_FOUND);
  }

  /// @dev Find given item in the array and call removeByIndex function if exist. If not throw an error
  function findAndRemove(uint256[] storage array, uint256 _item, bool keepSorting) internal {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == _item) {
        removeByIndex(array, i, keepSorting);
        return;
      }
    }
    revert(ITEM_NOT_FOUND);
  }

  // -----------------------------------

  /// @dev Call findAndRemove function for given item array
  function findAndRemoveArray(address[] storage array, address[] memory _items, bool keepSorting) internal {
    for (uint256 i = 0; i < _items.length; i++) {
      findAndRemove(array, _items[i], keepSorting);
    }
  }

  /// @dev Call findAndRemove function for given item array
  function findAndRemoveArray(uint256[] storage array, uint256[] memory _items, bool keepSorting) internal {
    for (uint256 i = 0; i < _items.length; i++) {
      findAndRemove(array, _items[i], keepSorting);
    }
  }

  // -----------------------------------

  /// @dev Remove from array the item with given id and move the last item on it place
  ///      Use with mapping for keeping indexes in correct ordering
  function removeIndexed(
    uint256[] storage array,
    mapping(uint256 => uint256) storage indexes,
    uint256 id
  ) internal {
    uint256 lastId = array[array.length - 1];
    uint256 index = indexes[id];
    indexes[lastId] = index;
    indexes[id] = type(uint256).max;
    array[index] = lastId;
    array.pop();
  }

  // ************* SORTING *******************

  /// @dev Insertion sorting algorithm for using with arrays fewer than 10 elements
  ///      Based on https://medium.com/coinmonks/sorting-in-solidity-without-comparison-4eb47e04ff0d
  function sortAddressesByUint(address[] storage addressArray, mapping(address => uint) storage uintMap) internal {
    for (uint i = 1; i < addressArray.length; i++) {
      address key = addressArray[i];
      uint j = i - 1;
      while ((int(j) >= 0) && uintMap[addressArray[j]] > uintMap[key]) {
        addressArray[j + 1] = addressArray[j];
      unchecked {j--;}
      }
    unchecked {
      addressArray[j + 1] = key;
    }
    }
  }

  /// @dev Insertion sorting algorithm for using with arrays fewer than 10 elements
  ///      Based on https://medium.com/coinmonks/sorting-in-solidity-without-comparison-4eb47e04ff0d
  function sortAddressesByUintReverted(address[] storage addressArray, mapping(address => uint) storage uintMap) internal {
    for (uint i = 1; i < addressArray.length; i++) {
      address key = addressArray[i];
      uint j = i - 1;
      while ((int(j) >= 0) && uintMap[addressArray[j]] < uintMap[key]) {
        addressArray[j + 1] = addressArray[j];
      unchecked {j--;}
      }
    unchecked {
      addressArray[j + 1] = key;
    }
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
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
  /**
   * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
   * by `operator` from `from`, this function is called.
   *
   * It must return its Solidity selector to confirm the token transfer.
   * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
   *
   * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
   */
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30 000 gas.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain `call` is an unsafe replacement for a function call: use this
   * function instead.
   *
   * If `target` reverts with a revert reason, it is bubbled up by this
   * function (like regular Solidity function calls).
   *
   * Returns the raw returned data. To convert to the expected return value,
   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
   *
   * Requirements:
   *
   * - `target` must be a contract.
   * - calling `target` with `data` must not revert.
   *
   * _Available since v3.1._
   */
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
   * `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but also transferring `value` wei to `target`.
   *
   * Requirements:
   *
   * - the calling contract must have an ETH balance of at least `value`.
   * - the called Solidity function must be `payable`.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    require(isContract(target), "Address: call to non-contract");

    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, "Address: low-level delegate call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
   * revert reason using the provided one.
   *
   * _Available since v4.3._
   */
  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}