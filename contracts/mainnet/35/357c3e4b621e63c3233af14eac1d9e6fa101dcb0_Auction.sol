// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/utils/math/Math.sol";

import "../StabilizedPoolExtensions/StabilizedPoolUnit.sol";
import "../StabilizedPoolExtensions/LiquidityExtensionExtension.sol";
import "../StabilizedPoolExtensions/StabilizerNodeExtension.sol";
import "../StabilizedPoolExtensions/DataLabExtension.sol";
import "../StabilizedPoolExtensions/DexHandlerExtension.sol";
import "../StabilizedPoolExtensions/ProfitDistributorExtension.sol";
import "../interfaces/IMaltDataLab.sol";
import "../interfaces/IDexHandler.sol";
import "../interfaces/ILiquidityExtension.sol";
import "../interfaces/IAuctionStartController.sol";

struct AccountCommitment {
  uint256 commitment;
  uint256 redeemed;
  uint256 maltPurchased;
  uint256 exited;
}

struct AuctionData {
  // The full amount of commitments required to return to peg
  uint256 fullRequirement;
  // total maximum desired commitments to this auction
  uint256 maxCommitments;
  // Quantity of sale currency committed to this auction
  uint256 commitments;
  // Quantity of commitments that have been exited early
  uint256 exited;
  // Malt purchased and burned using current commitments
  uint256 maltPurchased;
  // Desired starting price for the auction
  uint256 startingPrice;
  // Desired lowest price for the arbitrage token
  uint256 endingPrice;
  // Price of arbitrage tokens at conclusion of auction. This is either
  // when the duration elapses or the maxCommitments is reached
  uint256 finalPrice;
  // The peg price for the liquidity pool
  uint256 pegPrice;
  // Time when auction started
  uint256 startingTime;
  uint256 endingTime;
  // The reserve ratio at the start of the auction
  uint256 preAuctionReserveRatio;
  // The amount of arb tokens that have been executed and are now claimable
  uint256 claimableTokens;
  // The finally calculated realBurnBudget
  uint256 finalBurnBudget;
  // Is the auction currently accepting commitments?
  bool active;
  // Has this auction been finalized? Meaning any additional stabilizing
  // has been done
  bool finalized;
  // A map of all commitments to this auction by specific accounts
  mapping(address => AccountCommitment) accountCommitments;
}

/// @title Malt Arbitrage Auction
/// @author 0xScotch <[email protected]>
/// @notice The under peg Malt mechanism of dutch arbitrage auctions is implemented here
contract Auction is
  StabilizedPoolUnit,
  LiquidityExtensionExtension,
  StabilizerNodeExtension,
  DataLabExtension,
  DexHandlerExtension,
  ProfitDistributorExtension
{
  using SafeERC20 for ERC20;

  bytes32 public immutable AUCTION_AMENDER_ROLE;
  bytes32 public immutable PROFIT_ALLOCATOR_ROLE;

  address public amender;

  uint256 public unclaimedArbTokens;
  uint256 public replenishingAuctionId;
  uint256 public currentAuctionId;
  uint256 public claimableArbitrageRewards;
  uint256 public nextCommitmentId;
  uint256 public auctionLength = 600; // 10 minutes
  uint256 public arbTokenReplenishSplitBps = 7000; // 70%
  uint256 public maxAuctionEndBps = 9000; // 90% of target price
  uint256 public auctionEndReserveBps = 9000; // 90% of collateral
  uint256 public priceLookback = 0;
  uint256 public reserveRatioLookback = 30; // 30 seconds
  uint256 public dustThreshold = 1e15;
  uint256 public earlyEndThreshold;
  uint256 public costBufferBps = 1000;
  uint256 private _replenishLimit = 10;

  address public auctionStartController;

  mapping(uint256 => AuctionData) internal idToAuction;
  mapping(address => uint256[]) internal accountCommitmentEpochs;

  event AuctionCommitment(
    uint256 commitmentId,
    uint256 auctionId,
    address indexed account,
    uint256 commitment,
    uint256 purchased
  );

  event ClaimArbTokens(
    uint256 auctionId,
    address indexed account,
    uint256 amountTokens
  );

  event AuctionEnded(
    uint256 id,
    uint256 commitments,
    uint256 startingPrice,
    uint256 finalPrice,
    uint256 maltPurchased
  );

  event AuctionStarted(
    uint256 id,
    uint256 maxCommitments,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 startingTime,
    uint256 endingTime
  );

  event ArbTokenAllocation(
    uint256 replenishingAuctionId,
    uint256 maxArbAllocation
  );

  event SetAuctionLength(uint256 length);
  event SetAuctionEndReserveBps(uint256 bps);
  event SetDustThreshold(uint256 threshold);
  event SetReserveRatioLookback(uint256 lookback);
  event SetPriceLookback(uint256 lookback);
  event SetMaxAuctionEnd(uint256 maxEnd);
  event SetTokenReplenishSplit(uint256 split);
  event SetAuctionStartController(address controller);
  event SetAuctionReplenishId(uint256 id);
  event SetEarlyEndThreshold(uint256 threshold);
  event SetCostBufferBps(uint256 costBuffer);

  constructor(
    address timelock,
    address repository,
    address poolFactory,
    uint256 _auctionLength,
    uint256 _earlyEndThreshold
  ) StabilizedPoolUnit(timelock, repository, poolFactory) {
    auctionLength = _auctionLength;
    earlyEndThreshold = _earlyEndThreshold;

    // keccak256("AUCTION_AMENDER_ROLE")
    AUCTION_AMENDER_ROLE = 0x7cfd4d3ca87651951a5df4ff76005c956036fd9aa4b22e6e574caaa56f487f68;
    // keccak256("PROFIT_ALLOCATOR_ROLE")
    PROFIT_ALLOCATOR_ROLE = 0x00ed6845b200b0f3e6539c45853016f38cb1b785c1d044aea74da930e58c7c4c;
  }

  function setupContracts(
    address _collateralToken,
    address _liquidityExtension,
    address _stabilizerNode,
    address _maltDataLab,
    address _dexHandler,
    address _amender,
    address _profitDistributor,
    address pool
  ) external onlyRoleMalt(POOL_FACTORY_ROLE, "Must be pool factory") {
    require(!contractActive, "Auction: Already setup");
    require(_collateralToken != address(0), "Auction: Col addr(0)");
    require(_liquidityExtension != address(0), "Auction: LE addr(0)");
    require(_stabilizerNode != address(0), "Auction: StabNode addr(0)");
    require(_maltDataLab != address(0), "Auction: DataLab addr(0)");
    require(_dexHandler != address(0), "Auction: DexHandler addr(0)");
    require(_amender != address(0), "Auction: Amender addr(0)");
    require(_profitDistributor != address(0), "Auction: ProfitDist addr(0)");

    contractActive = true;

    _roleSetup(AUCTION_AMENDER_ROLE, _amender);
    _roleSetup(PROFIT_ALLOCATOR_ROLE, _profitDistributor);
    _setupRole(STABILIZER_NODE_ROLE, _stabilizerNode);

    collateralToken = ERC20(_collateralToken);
    liquidityExtension = ILiquidityExtension(_liquidityExtension);
    stabilizerNode = IStabilizerNode(_stabilizerNode);
    maltDataLab = IMaltDataLab(_maltDataLab);
    dexHandler = IDexHandler(_dexHandler);
    amender = _amender;
    profitDistributor = IProfitDistributor(_profitDistributor);

    (, address updater, ) = poolFactory.getPool(pool);
    _setPoolUpdater(updater);
  }

  function _beforeSetStabilizerNode(address _stabilizerNode) internal override {
    _transferRole(
      _stabilizerNode,
      address(stabilizerNode),
      STABILIZER_NODE_ROLE
    );
  }

  function _beforeSetProfitDistributor(address _profitDistributor)
    internal
    override
  {
    _transferRole(
      _profitDistributor,
      address(profitDistributor),
      PROFIT_ALLOCATOR_ROLE
    );
  }

  /*
   * PUBLIC METHODS
   */
  function purchaseArbitrageTokens(uint256 amount, uint256 minPurchased)
    external
    nonReentrant
    onlyActive
  {
    uint256 currentAuction = currentAuctionId;
    require(auctionActive(currentAuction), "No auction running");
    require(amount != 0, "purchaseArb: 0 amount");

    uint256 oldBalance = collateralToken.balanceOf(address(liquidityExtension));

    collateralToken.safeTransferFrom(
      msg.sender,
      address(liquidityExtension),
      amount
    );

    uint256 realAmount = collateralToken.balanceOf(
      address(liquidityExtension)
    ) - oldBalance;

    require(realAmount <= amount, "Invalid amount");

    uint256 realCommitment = _capCommitment(currentAuction, realAmount);
    require(realCommitment != 0, "ArbTokens: Real Commitment 0");

    uint256 purchased = liquidityExtension.purchaseAndBurn(realCommitment);
    require(purchased >= minPurchased, "ArbTokens: Insufficient output");

    AuctionData storage auction = idToAuction[currentAuction];

    require(
      auction.startingTime <= block.timestamp,
      "Auction hasn't started yet"
    );
    require(auction.endingTime > block.timestamp, "Auction is already over");
    require(auction.active == true, "Auction is not active");

    auction.commitments = auction.commitments + realCommitment;

    if (auction.accountCommitments[msg.sender].commitment == 0) {
      accountCommitmentEpochs[msg.sender].push(currentAuction);
    }
    auction.accountCommitments[msg.sender].commitment =
      auction.accountCommitments[msg.sender].commitment +
      realCommitment;
    auction.accountCommitments[msg.sender].maltPurchased =
      auction.accountCommitments[msg.sender].maltPurchased +
      purchased;
    auction.maltPurchased = auction.maltPurchased + purchased;

    emit AuctionCommitment(
      nextCommitmentId,
      currentAuction,
      msg.sender,
      realCommitment,
      purchased
    );

    nextCommitmentId = nextCommitmentId + 1;

    if (auction.commitments + auction.pegPrice >= auction.maxCommitments) {
      _endAuction(currentAuction);
    }
  }

  function claimArbitrage(uint256 _auctionId) external nonReentrant onlyActive {
    uint256 amountTokens = userClaimableArbTokens(msg.sender, _auctionId);

    require(amountTokens > 0, "No claimable Arb tokens");

    AuctionData storage auction = idToAuction[_auctionId];

    require(!auction.active, "Cannot claim tokens on an active auction");

    AccountCommitment storage commitment = auction.accountCommitments[
      msg.sender
    ];

    uint256 redemption = (amountTokens * auction.finalPrice) / auction.pegPrice;
    uint256 remaining = commitment.commitment -
      commitment.redeemed -
      commitment.exited;

    if (redemption > remaining) {
      redemption = remaining;
    }

    commitment.redeemed = commitment.redeemed + redemption;

    // Unclaimed represents total outstanding, but not necessarily
    // claimable yet.
    // claimableArbitrageRewards represents total amount that is now
    // available to be claimed
    if (amountTokens > unclaimedArbTokens) {
      unclaimedArbTokens = 0;
    } else {
      unclaimedArbTokens = unclaimedArbTokens - amountTokens;
    }

    if (amountTokens > claimableArbitrageRewards) {
      claimableArbitrageRewards = 0;
    } else {
      claimableArbitrageRewards = claimableArbitrageRewards - amountTokens;
    }

    uint256 totalBalance = collateralToken.balanceOf(address(this));
    if (amountTokens + dustThreshold >= totalBalance) {
      amountTokens = totalBalance;
    }

    collateralToken.safeTransfer(msg.sender, amountTokens);

    emit ClaimArbTokens(_auctionId, msg.sender, amountTokens);
  }

  function endAuctionEarly() external onlyActive {
    uint256 currentId = currentAuctionId;
    AuctionData storage auction = idToAuction[currentId];
    require(
      auction.active && block.timestamp >= auction.startingTime,
      "No auction running"
    );
    require(
      auction.commitments >= (auction.maxCommitments - earlyEndThreshold),
      "Too early to end"
    );

    _endAuction(currentId);
  }

  /*
   * PUBLIC VIEW FUNCTIONS
   */
  function isAuctionFinished(uint256 _id) public view returns (bool) {
    AuctionData storage auction = idToAuction[_id];

    return
      auction.endingTime > 0 &&
      (block.timestamp >= auction.endingTime ||
        auction.finalPrice > 0 ||
        auction.commitments + auction.pegPrice >= auction.maxCommitments);
  }

  function auctionActive(uint256 _id) public view returns (bool) {
    AuctionData storage auction = idToAuction[_id];

    return auction.active && block.timestamp >= auction.startingTime;
  }

  function isAuctionFinalized(uint256 _id) public view returns (bool) {
    AuctionData storage auction = idToAuction[_id];
    return auction.finalized;
  }

  function userClaimableArbTokens(address account, uint256 auctionId)
    public
    view
    returns (uint256)
  {
    AuctionData storage auction = idToAuction[auctionId];

    if (
      auction.claimableTokens == 0 ||
      auction.finalPrice == 0 ||
      auction.commitments == 0
    ) {
      return 0;
    }

    AccountCommitment storage commitment = auction.accountCommitments[account];

    uint256 totalTokens = (auction.commitments * auction.pegPrice) /
      auction.finalPrice;

    uint256 claimablePerc = (auction.claimableTokens * auction.pegPrice) /
      totalTokens;

    uint256 amountTokens = (commitment.commitment * auction.pegPrice) /
      auction.finalPrice;
    uint256 redeemedTokens = (commitment.redeemed * auction.pegPrice) /
      auction.finalPrice;
    uint256 exitedTokens = (commitment.exited * auction.pegPrice) /
      auction.finalPrice;

    uint256 amountOut = ((amountTokens * claimablePerc) / auction.pegPrice) -
      redeemedTokens -
      exitedTokens;

    // Avoid leaving dust behind
    if (amountOut < dustThreshold) {
      return 0;
    }

    return amountOut;
  }

  function balanceOfArbTokens(uint256 _auctionId, address account)
    public
    view
    returns (uint256)
  {
    AuctionData storage auction = idToAuction[_auctionId];

    AccountCommitment storage commitment = auction.accountCommitments[account];

    uint256 remaining = commitment.commitment -
      commitment.redeemed -
      commitment.exited;

    uint256 price = auction.finalPrice;

    if (auction.finalPrice == 0) {
      price = currentPrice(_auctionId);
    }

    return (remaining * auction.pegPrice) / price;
  }

  function averageMaltPrice(uint256 _id) external view returns (uint256) {
    AuctionData storage auction = idToAuction[_id];

    if (auction.maltPurchased == 0) {
      return 0;
    }

    return (auction.commitments * auction.pegPrice) / auction.maltPurchased;
  }

  function currentPrice(uint256 _id) public view returns (uint256) {
    AuctionData storage auction = idToAuction[_id];

    if (auction.startingTime == 0) {
      return maltDataLab.priceTarget();
    }

    uint256 secondsSinceStart = 0;

    if (block.timestamp > auction.startingTime) {
      secondsSinceStart = block.timestamp - auction.startingTime;
    }

    uint256 auctionDuration = auction.endingTime - auction.startingTime;

    if (secondsSinceStart >= auctionDuration) {
      return auction.endingPrice;
    }

    uint256 totalPriceDelta = auction.startingPrice - auction.endingPrice;

    uint256 currentPriceDelta = (totalPriceDelta * secondsSinceStart) /
      auctionDuration;

    return auction.startingPrice - currentPriceDelta;
  }

  function getAuctionCommitments(uint256 _id)
    public
    view
    returns (uint256 commitments, uint256 maxCommitments)
  {
    AuctionData storage auction = idToAuction[_id];

    return (auction.commitments, auction.maxCommitments);
  }

  function getAuctionPrices(uint256 _id)
    public
    view
    returns (
      uint256 startingPrice,
      uint256 endingPrice,
      uint256 finalPrice
    )
  {
    AuctionData storage auction = idToAuction[_id];

    return (auction.startingPrice, auction.endingPrice, auction.finalPrice);
  }

  function auctionExists(uint256 _id) public view returns (bool) {
    AuctionData storage auction = idToAuction[_id];

    return auction.startingTime > 0;
  }

  function auctionLive() public view returns (bool) {
    return auctionExists(currentAuctionId);
  }

  function getAccountCommitments(address account)
    external
    view
    returns (
      uint256[] memory auctions,
      uint256[] memory commitments,
      uint256[] memory awardedTokens,
      uint256[] memory redeemedTokens,
      uint256[] memory exitedTokens,
      uint256[] memory finalPrice,
      uint256[] memory claimable,
      bool[] memory finished
    )
  {
    uint256[] memory epochCommitments = accountCommitmentEpochs[account];

    auctions = new uint256[](epochCommitments.length);
    commitments = new uint256[](epochCommitments.length);
    awardedTokens = new uint256[](epochCommitments.length);
    redeemedTokens = new uint256[](epochCommitments.length);
    exitedTokens = new uint256[](epochCommitments.length);
    finalPrice = new uint256[](epochCommitments.length);
    claimable = new uint256[](epochCommitments.length);
    finished = new bool[](epochCommitments.length);

    for (uint256 i = 0; i < epochCommitments.length; ++i) {
      AuctionData storage auction = idToAuction[epochCommitments[i]];

      AccountCommitment storage commitment = auction.accountCommitments[
        account
      ];

      uint256 price = auction.finalPrice;

      if (auction.finalPrice == 0) {
        price = currentPrice(epochCommitments[i]);
      }

      auctions[i] = epochCommitments[i];
      commitments[i] = commitment.commitment;
      awardedTokens[i] = (commitment.commitment * auction.pegPrice) / price;
      redeemedTokens[i] = (commitment.redeemed * auction.pegPrice) / price;
      exitedTokens[i] = (commitment.exited * auction.pegPrice) / price;
      finalPrice[i] = price;
      claimable[i] = userClaimableArbTokens(account, epochCommitments[i]);
      finished[i] = isAuctionFinished(epochCommitments[i]);
    }
  }

  function getAccountCommitmentAuctions(address account)
    external
    view
    returns (uint256[] memory)
  {
    return accountCommitmentEpochs[account];
  }

  function getAuctionParticipationForAccount(address account, uint256 auctionId)
    external
    view
    returns (
      uint256 commitment,
      uint256 redeemed,
      uint256 maltPurchased,
      uint256 exited
    )
  {
    AccountCommitment storage _commitment = idToAuction[auctionId]
      .accountCommitments[account];

    return (
      _commitment.commitment,
      _commitment.redeemed,
      _commitment.maltPurchased,
      _commitment.exited
    );
  }

  function hasOngoingAuction() external view returns (bool) {
    AuctionData storage auction = idToAuction[currentAuctionId];

    return auction.startingTime > 0 && !auction.finalized;
  }

  function getActiveAuction()
    external
    view
    returns (
      uint256 auctionId,
      uint256 maxCommitments,
      uint256 commitments,
      uint256 maltPurchased,
      uint256 startingPrice,
      uint256 endingPrice,
      uint256 finalPrice,
      uint256 pegPrice,
      uint256 startingTime,
      uint256 endingTime,
      uint256 finalBurnBudget
    )
  {
    AuctionData storage auction = idToAuction[currentAuctionId];

    return (
      currentAuctionId,
      auction.maxCommitments,
      auction.commitments,
      auction.maltPurchased,
      auction.startingPrice,
      auction.endingPrice,
      auction.finalPrice,
      auction.pegPrice,
      auction.startingTime,
      auction.endingTime,
      auction.finalBurnBudget
    );
  }

  function getAuction(uint256 _id)
    public
    view
    returns (
      uint256 fullRequirement,
      uint256 maxCommitments,
      uint256 commitments,
      uint256 startingPrice,
      uint256 endingPrice,
      uint256 finalPrice,
      uint256 pegPrice,
      uint256 startingTime,
      uint256 endingTime,
      uint256 finalBurnBudget,
      uint256 exited
    )
  {
    AuctionData storage auction = idToAuction[_id];

    return (
      auction.fullRequirement,
      auction.maxCommitments,
      auction.commitments,
      auction.startingPrice,
      auction.endingPrice,
      auction.finalPrice,
      auction.pegPrice,
      auction.startingTime,
      auction.endingTime,
      auction.finalBurnBudget,
      auction.exited
    );
  }

  function getAuctionCore(uint256 _id)
    public
    view
    returns (
      uint256 auctionId,
      uint256 commitments,
      uint256 maltPurchased,
      uint256 startingPrice,
      uint256 finalPrice,
      uint256 pegPrice,
      uint256 startingTime,
      uint256 endingTime,
      uint256 preAuctionReserveRatio,
      bool active
    )
  {
    AuctionData storage auction = idToAuction[_id];

    return (
      _id,
      auction.commitments,
      auction.maltPurchased,
      auction.startingPrice,
      auction.finalPrice,
      auction.pegPrice,
      auction.startingTime,
      auction.endingTime,
      auction.preAuctionReserveRatio,
      auction.active
    );
  }

  /*
   * INTERNAL FUNCTIONS
   */
  function _triggerAuction(
    uint256 pegPrice,
    uint256 rRatio,
    uint256 purchaseAmount
  ) internal returns (bool) {
    if (auctionStartController != address(0)) {
      bool success = IAuctionStartController(auctionStartController)
        .checkForStart();
      if (!success) {
        return false;
      }
    }
    uint256 _auctionIndex = currentAuctionId;

    (uint256 startingPrice, uint256 endingPrice) = _calculateAuctionPricing(
      rRatio,
      purchaseAmount
    );

    AuctionData storage auction = idToAuction[_auctionIndex];

    uint256 decimals = collateralToken.decimals();
    uint256 maxCommitments = _calcRealMaxRaise(
      purchaseAmount,
      rRatio,
      decimals
    );

    if (maxCommitments == 0) {
      return false;
    }

    auction.fullRequirement = purchaseAmount; // fullRequirement
    auction.maxCommitments = maxCommitments;
    auction.startingPrice = startingPrice;
    auction.endingPrice = endingPrice;
    auction.pegPrice = pegPrice;
    auction.startingTime = block.timestamp; // startingTime
    auction.endingTime = block.timestamp + auctionLength; // endingTime
    auction.active = true; // active
    auction.preAuctionReserveRatio = rRatio; // preAuctionReserveRatio
    auction.finalized = false; // finalized

    require(
      auction.endingTime == uint256(uint64(auction.endingTime)),
      "ending not eq"
    );

    emit AuctionStarted(
      _auctionIndex,
      auction.maxCommitments,
      auction.startingPrice,
      auction.endingPrice,
      auction.startingTime,
      auction.endingTime
    );
    return true;
  }

  function _capCommitment(uint256 _id, uint256 _commitment)
    internal
    view
    returns (uint256 realCommitment)
  {
    AuctionData storage auction = idToAuction[_id];

    realCommitment = _commitment;

    if (auction.commitments + _commitment >= auction.maxCommitments) {
      realCommitment = auction.maxCommitments - auction.commitments;
    }
  }

  function _endAuction(uint256 _id) internal {
    AuctionData storage auction = idToAuction[_id];

    require(auction.active == true, "Auction is already over");

    auction.active = false;
    auction.finalPrice = currentPrice(_id);

    uint256 amountArbTokens = (auction.commitments * auction.pegPrice) /
      auction.finalPrice;
    unclaimedArbTokens = unclaimedArbTokens + amountArbTokens;

    emit AuctionEnded(
      _id,
      auction.commitments,
      auction.startingPrice,
      auction.finalPrice,
      auction.maltPurchased
    );
  }

  function _finalizeAuction(uint256 auctionId) internal {
    (
      uint256 avgMaltPrice,
      uint256 commitments,
      uint256 fullRequirement,
      uint256 maltPurchased,
      uint256 finalPrice,
      uint256 preAuctionReserveRatio
    ) = _setupAuctionFinalization(auctionId);

    if (commitments >= fullRequirement) {
      return;
    }

    uint256 priceTarget = maltDataLab.priceTarget();

    // priceTarget - preAuctionReserveRatio represents maximum deficit per token
    // priceTarget divided by the max deficit is equivalent to 1 over the max deficit given we are in uint decimal
    // (commitments * 1/maxDeficit) - commitments
    uint256 maxBurnSpend = (commitments * priceTarget) /
      (priceTarget - preAuctionReserveRatio) -
      commitments;

    uint256 totalTokens = (commitments * priceTarget) / finalPrice;

    uint256 premiumExcess = 0;

    // The assumption here is that each token will be worth 1 Malt when redeemed.
    // Therefore if totalTokens is greater than the malt purchased then there is a net supply growth
    // After the tokens are repaid. We want this process to be neutral to supply at the very worst.
    if (totalTokens > maltPurchased) {
      // This also assumes current purchase price of Malt is $1, which is higher than it will be in practice.
      // So the premium excess will actually ensure slight net negative supply growth.
      premiumExcess = totalTokens - maltPurchased;
    }

    uint256 realBurnBudget = maltDataLab.getRealBurnBudget(
      maxBurnSpend,
      premiumExcess
    );

    if (realBurnBudget > 0) {
      AuctionData storage auction = idToAuction[auctionId];

      auction.finalBurnBudget = realBurnBudget;
      liquidityExtension.allocateBurnBudget(realBurnBudget);
    }
  }

  function _setupAuctionFinalization(uint256 auctionId)
    internal
    returns (
      uint256 avgMaltPrice,
      uint256 commitments,
      uint256 fullRequirement,
      uint256 maltPurchased,
      uint256 finalPrice,
      uint256 preAuctionReserveRatio
    )
  {
    AuctionData storage auction = idToAuction[auctionId];
    require(auction.startingTime > 0, "No auction available for the given id");

    auction.finalized = true;

    if (auction.maltPurchased > 0) {
      avgMaltPrice =
        (auction.commitments * auction.pegPrice) /
        auction.maltPurchased;
    }

    return (
      avgMaltPrice,
      auction.commitments,
      auction.fullRequirement,
      auction.maltPurchased,
      auction.finalPrice,
      auction.preAuctionReserveRatio
    );
  }

  function _calcRealMaxRaise(
    uint256 purchaseAmount,
    uint256 rRatio,
    uint256 decimals
  ) internal pure returns (uint256) {
    uint256 unity = 10**decimals;
    uint256 realBurn = (purchaseAmount * Math.min(rRatio, unity)) / unity;

    if (purchaseAmount > realBurn) {
      return purchaseAmount - realBurn;
    }

    return 0;
  }

  function _calculateAuctionPricing(uint256 rRatio, uint256 maxCommitments)
    internal
    view
    returns (uint256 startingPrice, uint256 endingPrice)
  {
    uint256 priceTarget = maltDataLab.priceTarget();
    if (rRatio > priceTarget) {
      rRatio = priceTarget;
    }
    startingPrice = maltDataLab.maltPriceAverage(priceLookback);
    uint256 liquidityExtensionBalance = collateralToken.balanceOf(
      address(liquidityExtension)
    );

    (uint256 latestPrice, ) = maltDataLab.lastMaltPrice();
    uint256 expectedMaltCost = priceTarget;
    if (latestPrice < priceTarget) {
      expectedMaltCost =
        latestPrice +
        ((priceTarget - latestPrice) * (5000 + costBufferBps)) /
        10000;
    }

    // rRatio should never be large enough for this to overflow
    // uint256 absoluteBottom = rRatio * auctionEndReserveBps / 10000;

    // Absolute bottom is the lowest price
    uint256 decimals = collateralToken.decimals();
    uint256 unity = 10**decimals;
    uint256 absoluteBottom = (maxCommitments * unity) /
      (liquidityExtensionBalance +
        ((maxCommitments * unity) / expectedMaltCost));

    uint256 idealBottom = 1; // 1wei just to avoid any issues with it being 0

    if (expectedMaltCost > rRatio) {
      idealBottom = expectedMaltCost - rRatio;
    }

    // price should never go below absoluteBottom
    if (idealBottom < absoluteBottom) {
      idealBottom = absoluteBottom;
    }

    // price should never start above the peg price
    if (startingPrice > priceTarget) {
      startingPrice = priceTarget;
    }

    if (idealBottom < startingPrice) {
      endingPrice = idealBottom;
    } else if (absoluteBottom < startingPrice) {
      endingPrice = absoluteBottom;
    } else {
      // There are no bottom prices that work with
      // the startingPrice so set start and end to
      // the absoluteBottom
      startingPrice = absoluteBottom;
      endingPrice = absoluteBottom;
    }

    // priceTarget should never be large enough to overflow here
    uint256 maxPrice = (priceTarget * maxAuctionEndBps) / 10000;

    if (endingPrice > maxPrice && maxPrice > absoluteBottom) {
      endingPrice = maxPrice;
    }
  }

  function _checkAuctionFinalization() internal {
    uint256 currentAuction = currentAuctionId;

    if (isAuctionFinished(currentAuction)) {
      if (auctionActive(currentAuction)) {
        _endAuction(currentAuction);
      }

      if (!isAuctionFinalized(currentAuction)) {
        _finalizeAuction(currentAuction);
      }
      currentAuctionId = currentAuction + 1;
    }
  }

  /*
   * PRIVILEDGED FUNCTIONS
   */
  function checkAuctionFinalization()
    external
    onlyRoleMalt(STABILIZER_NODE_ROLE, "Must be stabilizer node")
    onlyActive
  {
    _checkAuctionFinalization();
  }

  function accountExit(
    address account,
    uint256 auctionId,
    uint256 amount
  )
    external
    onlyRoleMalt(AUCTION_AMENDER_ROLE, "Only auction amender")
    onlyActive
  {
    AuctionData storage auction = idToAuction[auctionId];
    require(
      auction.accountCommitments[account].commitment >= amount,
      "amend: amount underflows"
    );

    if (auction.finalPrice == 0) {
      return;
    }

    auction.exited += amount;
    auction.accountCommitments[account].exited += amount;

    uint256 amountArbTokens = (amount * auction.pegPrice) / auction.finalPrice;

    if (amountArbTokens > unclaimedArbTokens) {
      unclaimedArbTokens = 0;
    } else {
      unclaimedArbTokens = unclaimedArbTokens - amountArbTokens;
    }
  }

  function allocateArbRewards(uint256 rewarded)
    external
    onlyRoleMalt(PROFIT_ALLOCATOR_ROLE, "Must be profit allocator node")
    onlyActive
    returns (uint256)
  {
    AuctionData storage auction;
    uint256 replenishingId = replenishingAuctionId; // gas
    uint256 absorbedCapital;
    uint256 count = 1;
    uint256 maxArbAllocation = (rewarded * arbTokenReplenishSplitBps) / 10000;

    // Limit iterations to avoid unbounded loops
    while (count < _replenishLimit) {
      auction = idToAuction[replenishingId];

      if (
        auction.finalPrice == 0 ||
        auction.startingTime == 0 ||
        !auction.finalized
      ) {
        // if finalPrice or startingTime are not set then this auction has not happened yet
        // So we are at the end of the journey
        break;
      }

      if (auction.commitments > 0) {
        uint256 totalTokens = (auction.commitments * auction.pegPrice) /
          auction.finalPrice;

        if (auction.claimableTokens < totalTokens) {
          uint256 requirement = totalTokens - auction.claimableTokens;

          uint256 usable = maxArbAllocation - absorbedCapital;

          if (absorbedCapital + requirement < maxArbAllocation) {
            usable = requirement;
          }

          auction.claimableTokens = auction.claimableTokens + usable;
          rewarded = rewarded - usable;
          claimableArbitrageRewards = claimableArbitrageRewards + usable;

          absorbedCapital += usable;

          emit ArbTokenAllocation(replenishingId, usable);

          if (auction.claimableTokens < totalTokens) {
            break;
          }
        }
      }

      replenishingId += 1;
      count += 1;
    }

    replenishingAuctionId = replenishingId;

    if (absorbedCapital != 0) {
      collateralToken.safeTransferFrom(
        address(profitDistributor),
        address(this),
        absorbedCapital
      );
    }

    return rewarded;
  }

  function triggerAuction(uint256 pegPrice, uint256 purchaseAmount)
    external
    onlyRoleMalt(STABILIZER_NODE_ROLE, "Must be stabilizer node")
    onlyActive
    returns (bool)
  {
    if (purchaseAmount == 0 || auctionExists(currentAuctionId)) {
      return false;
    }

    // Data is consistent here as this method as the stabilizer
    // calls maltDataLab.trackPool at the start of stabilize
    (uint256 rRatio, ) = liquidityExtension.reserveRatioAverage(
      reserveRatioLookback
    );

    return _triggerAuction(pegPrice, rRatio, purchaseAmount);
  }

  function setAuctionLength(uint256 _length)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_length > 0, "Length must be larger than 0");
    auctionLength = _length;
    emit SetAuctionLength(_length);
  }

  function setAuctionReplenishId(uint256 _id)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    replenishingAuctionId = _id;
    emit SetAuctionReplenishId(_id);
  }

  function setAuctionAmender(address _amender)
    external
    onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater privilege")
  {
    require(_amender != address(0), "Cannot set 0 address");
    _transferRole(_amender, amender, AUCTION_AMENDER_ROLE);
    amender = _amender;
  }

  function setAuctionStartController(address _controller)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    // This is allowed to be set to address(0) as its checked before calling methods on it
    auctionStartController = _controller;
    emit SetAuctionStartController(_controller);
  }

  function setTokenReplenishSplit(uint256 _split)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_split != 0 && _split <= 10000, "Must be between 0-100%");
    arbTokenReplenishSplitBps = _split;
    emit SetTokenReplenishSplit(_split);
  }

  function setMaxAuctionEnd(uint256 _maxEnd)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_maxEnd != 0 && _maxEnd <= 10000, "Must be between 0-100%");
    maxAuctionEndBps = _maxEnd;
    emit SetMaxAuctionEnd(_maxEnd);
  }

  function setPriceLookback(uint256 _lookback)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_lookback > 0, "Must be above 0");
    priceLookback = _lookback;
    emit SetPriceLookback(_lookback);
  }

  function setReserveRatioLookback(uint256 _lookback)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_lookback > 0, "Must be above 0");
    reserveRatioLookback = _lookback;
    emit SetReserveRatioLookback(_lookback);
  }

  function setAuctionEndReserveBps(uint256 _bps)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_bps != 0 && _bps < 10000, "Must be between 0-100%");
    auctionEndReserveBps = _bps;
    emit SetAuctionEndReserveBps(_bps);
  }

  function setDustThreshold(uint256 _threshold)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_threshold > 0, "Must be between greater than 0");
    dustThreshold = _threshold;
    emit SetDustThreshold(_threshold);
  }

  function setEarlyEndThreshold(uint256 _threshold)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_threshold > 0, "Must be between greater than 0");
    earlyEndThreshold = _threshold;
    emit SetEarlyEndThreshold(_threshold);
  }

  function setCostBufferBps(uint256 _costBuffer)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_costBuffer != 0 && _costBuffer <= 5000, "Must be > 0 && <= 5000");
    costBufferBps = _costBuffer;
    emit SetCostBufferBps(_costBuffer);
  }

  function adminEndAuction()
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    uint256 currentId = currentAuctionId;
    require(auctionActive(currentId), "No auction running");
    _endAuction(currentId);
  }

  function setReplenishLimit(uint256 _limit)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_limit != 0, "Not 0");
    _replenishLimit = _limit;
  }

  function _accessControl()
    internal
    override(
      LiquidityExtensionExtension,
      StabilizerNodeExtension,
      DataLabExtension,
      DexHandlerExtension,
      ProfitDistributorExtension
    )
  {
    _onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../Permissions.sol";
import "../interfaces/IBurnMintableERC20.sol";
import "../libraries/uniswap/IUniswapV2Pair.sol";
import "../interfaces/IStabilizedPoolFactory.sol";

/// @title Pool Unit
/// @author 0xScotch <[email protected]>
/// @notice An abstract contract inherited by all contracts that are part of a stabilized pool deployment
/// @dev This helps reduce boilerplate across the codebase declaring all the other contracts in the pool
abstract contract StabilizedPoolUnit is Permissions {
  bytes32 public immutable POOL_FACTORY_ROLE;
  bytes32 public immutable POOL_UPDATER_ROLE;
  bytes32 public immutable STABILIZER_NODE_ROLE;
  bytes32 public immutable LIQUIDITY_MINE_ROLE;
  bytes32 public immutable AUCTION_ROLE;
  bytes32 public immutable REWARD_THROTTLE_ROLE;

  bool internal contractActive;

  /* Permanent Members */
  IBurnMintableERC20 public malt;
  ERC20 public collateralToken;
  IUniswapV2Pair public stakeToken;

  /* Updatable */
  IStabilizedPoolFactory public poolFactory;

  event SetPoolUpdater(address updater);

  constructor(
    address _timelock,
    address _repository,
    address _poolFactory
  ) {
    require(_timelock != address(0), "Timelock addr(0)");
    require(_repository != address(0), "Repo addr(0)");
    _initialSetup(_repository);

    POOL_FACTORY_ROLE = 0x598cee9ad6a01a66130d639a08dbc750d4a51977e842638d2fc97de81141dc74;
    POOL_UPDATER_ROLE = 0xb70e81d43273d7b57d823256e2fd3d6bb0b670e5f5e1253ffd1c5f776a989c34;
    STABILIZER_NODE_ROLE = 0x9aebf7c4e2f9399fa54d66431d5afb53d5ce943832be8ebbced058f5450edf1b;
    LIQUIDITY_MINE_ROLE = 0xb8fddb29c347bbf5ee0bb24db027d53d603215206359b1142519846b9c87707f;
    AUCTION_ROLE = 0xc5e2d1653feba496cf5ce3a744b90ea18acf0df3d036aba9b2f85992a1467906;
    REWARD_THROTTLE_ROLE = 0x0beda4984192b677bceea9b67542fab864a133964c43188171c1c68a84cd3514;
    _roleSetup(
      0x598cee9ad6a01a66130d639a08dbc750d4a51977e842638d2fc97de81141dc74,
      _poolFactory
    );
    _setupRole(
      0x598cee9ad6a01a66130d639a08dbc750d4a51977e842638d2fc97de81141dc74,
      _timelock
    );
    _roleSetup(
      0x9aebf7c4e2f9399fa54d66431d5afb53d5ce943832be8ebbced058f5450edf1b,
      _timelock
    );
    _roleSetup(
      0xb8fddb29c347bbf5ee0bb24db027d53d603215206359b1142519846b9c87707f,
      _timelock
    );
    _roleSetup(
      0xc5e2d1653feba496cf5ce3a744b90ea18acf0df3d036aba9b2f85992a1467906,
      _timelock
    );
    _roleSetup(
      0x0beda4984192b677bceea9b67542fab864a133964c43188171c1c68a84cd3514,
      _timelock
    );

    poolFactory = IStabilizedPoolFactory(_poolFactory);
  }

  function setPoolUpdater(address _updater)
    internal
    onlyRoleMalt(POOL_FACTORY_ROLE, "Must have pool factory role")
  {
    _setPoolUpdater(_updater);
  }

  function setPoolFactory(address _poolFactory)
    internal
    onlyRoleMalt(getRoleAdmin(POOL_FACTORY_ROLE), "Must be pool factory admin role")
  {
    _transferRole(_poolFactory, address(poolFactory), POOL_FACTORY_ROLE);
    poolFactory = IStabilizedPoolFactory(_poolFactory);
  }

  function _setPoolUpdater(address _updater) internal {
    require(_updater != address(0), "Cannot use addr(0)");
    _grantRole(POOL_UPDATER_ROLE, _updater);
    emit SetPoolUpdater(_updater);
  }

  modifier onlyActive() {
    require(contractActive, "Contract not active");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/ILiquidityExtension.sol";

/// @title Liquidity Extension Extension
/// @author 0xScotch <[email protected]>
/// @notice An abstract contract inherited by all contracts that need access to the LiquidityExtension
/// @dev This helps reduce boilerplate across the codebase declaring all the other contracts in the pool
abstract contract LiquidityExtensionExtension {
  ILiquidityExtension public liquidityExtension;

  event SetLiquidityExtension(address liquidityExtension);

  /// @notice Method for setting the address of the liquidityExtension
  /// @param _liquidityExtension The contract address of the LiquidityExtension instance
  /// @dev Only callable via the PoolUpdater contract
  function setLiquidityExtension(address _liquidityExtension) external {
    _accessControl();
    require(_liquidityExtension != address(0), "Cannot use addr(0)");
    _beforeSetLiquidityExtension(_liquidityExtension);
    liquidityExtension = ILiquidityExtension(_liquidityExtension);
    emit SetLiquidityExtension(_liquidityExtension);
  }

  function _beforeSetLiquidityExtension(address _liquidityExtension)
    internal
    virtual
  {}

  function _accessControl() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/IStabilizerNode.sol";

/// @title Stabilizer Node Extension
/// @author 0xScotch <[email protected]>
/// @notice An abstract contract inherited by all contracts that need access to the StabilizerNode
/// @dev This helps reduce boilerplate across the codebase declaring all the other contracts in the pool
abstract contract StabilizerNodeExtension {
  IStabilizerNode public stabilizerNode;

  event SetStablizerNode(address stabilizerNode);

  /// @notice Privileged method for setting the address of the stabilizerNode
  /// @param _stabilizerNode The contract address of the StabilizerNode instance
  /// @dev Only callable via the PoolUpdater contract
  function setStablizerNode(address _stabilizerNode) external {
    _accessControl();
    require(_stabilizerNode != address(0), "Cannot use addr(0)");
    _beforeSetStabilizerNode(_stabilizerNode);
    stabilizerNode = IStabilizerNode(_stabilizerNode);
    emit SetStablizerNode(_stabilizerNode);
  }

  function _beforeSetStabilizerNode(address _stabilizerNode) internal virtual {}

  function _accessControl() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/IMaltDataLab.sol";

/// @title Malt Data Lab Extension
/// @author 0xScotch <[email protected]>
/// @notice An abstract contract inherited by all contracts that need access to the MaltDataLab
/// @dev This helps reduce boilerplate across the codebase declaring all the other contracts in the pool
abstract contract DataLabExtension {
  IMaltDataLab public maltDataLab;

  event SetMaltDataLab(address maltDataLab);

  /// @notice Privileged method for setting the address of the maltDataLab
  /// @param _maltDataLab The contract address of the MaltDataLab instance
  /// @dev Only callable via the PoolUpdater contract
  function setMaltDataLab(address _maltDataLab) external {
    _accessControl();
    require(_maltDataLab != address(0), "Cannot use addr(0)");
    _beforeSetMaltDataLab(_maltDataLab);
    maltDataLab = IMaltDataLab(_maltDataLab);
    emit SetMaltDataLab(_maltDataLab);
  }

  function _beforeSetMaltDataLab(address _maltDataLab) internal virtual {}

  function _accessControl() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/IDexHandler.sol";

/// @title Dex Handler Extension
/// @author 0xScotch <[email protected]>
/// @notice An abstract contract inherited by all contracts that need access to the DexHandler
/// @dev This helps reduce boilerplate across the codebase declaring all the other contracts in the pool
abstract contract DexHandlerExtension {
  IDexHandler public dexHandler;

  event SetDexHandler(address dexHandler);

  /// @notice Privileged method for setting the address of the dexHandler
  /// @param _dexHandler The contract address of the DexHandler instance
  /// @dev Only callable via the PoolUpdater contract
  function setDexHandler(address _dexHandler) external {
    _accessControl();
    require(_dexHandler != address(0), "Cannot use addr(0)");
    _beforeSetDexHandler(_dexHandler);
    dexHandler = IDexHandler(_dexHandler);
    emit SetDexHandler(_dexHandler);
  }

  function _beforeSetDexHandler(address _dexHandler) internal virtual {}

  function _accessControl() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/IProfitDistributor.sol";

/// @title Profit Distributor Extension
/// @author 0xScotch <[email protected]>
/// @notice An abstract contract inherited by all contracts that need access to the ProfitDistributor
/// @dev This helps reduce boilerplate across the codebase declaring all the other contracts in the pool
abstract contract ProfitDistributorExtension {
  IProfitDistributor public profitDistributor;

  event SetProfitDistributor(address profitDistributor);

  /// @notice Privileged method for setting the address of the profitDistributor
  /// @param _profitDistributor The contract address of the ProfitDistributor instance
  /// @dev Only callable via the PoolUpdater contract
  function setProfitDistributor(address _profitDistributor) external {
    _accessControl();
    require(_profitDistributor != address(0), "Cannot use addr(0)");
    _beforeSetProfitDistributor(_profitDistributor);
    profitDistributor = IProfitDistributor(_profitDistributor);
    emit SetProfitDistributor(_profitDistributor);
  }

  function _beforeSetProfitDistributor(address _profitDistributor)
    internal
    virtual
  {}

  function _accessControl() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IGlobalImpliedCollateralService.sol";
import "./IMovingAverage.sol";

interface IMaltDataLab {
  function priceTarget() external view returns (uint256);

  function smoothedMaltPrice() external view returns (uint256);

  function globalIC() external view returns (IGlobalImpliedCollateralService);

  function smoothedK() external view returns (uint256);

  function smoothedReserves() external view returns (uint256);

  function maltPriceAverage(uint256 _lookback) external view returns (uint256);

  function kAverage(uint256 _lookback) external view returns (uint256);

  function poolReservesAverage(uint256 _lookback)
    external
    view
    returns (uint256, uint256);

  function lastMaltPrice() external view returns (uint256, uint64);

  function lastPoolReserves()
    external
    view
    returns (
      uint256,
      uint256,
      uint64
    );

  function lastK() external view returns (uint256, uint64);

  function realValueOfLPToken(uint256 amount) external view returns (uint256);

  function trackPool() external returns (bool);

  function trustedTrackPool(
    uint256,
    uint256,
    uint256,
    uint256
  ) external;

  function collateralToken() external view returns (address);

  function malt() external view returns (address);

  function stakeToken() external view returns (address);

  function getInternalAuctionEntryPrice()
    external
    view
    returns (uint256 auctionEntryPrice);

  function getSwingTraderEntryPrice()
    external
    view
    returns (uint256 stPriceTarget);

  function getActualPriceTarget() external view returns (uint256);

  function getRealBurnBudget(uint256, uint256) external view returns (uint256);

  function maltToRewardDecimals(uint256 maltAmount)
    external
    view
    returns (uint256);

  function rewardToMaltDecimals(uint256 amount) external view returns (uint256);

  function smoothedMaltRatio() external view returns (uint256);

  function ratioMA() external view returns (IMovingAverage);

  function trustedTrackMaltRatio(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IDexHandler {
  function buyMalt(uint256, uint256) external returns (uint256 purchased);

  function sellMalt(uint256, uint256) external returns (uint256 rewards);

  function addLiquidity(
    uint256,
    uint256,
    uint256
  )
    external
    returns (
      uint256 maltUsed,
      uint256 rewardUsed,
      uint256 liquidityCreated
    );

  function removeLiquidity(uint256, uint256)
    external
    returns (uint256 amountMalt, uint256 amountReward);

  function calculateMintingTradeSize(uint256 priceTarget)
    external
    view
    returns (uint256);

  function calculateBurningTradeSize(uint256 priceTarget)
    external
    view
    returns (uint256);

  function reserves()
    external
    view
    returns (uint256 maltSupply, uint256 rewardSupply);

  function maltMarketPrice()
    external
    view
    returns (uint256 price, uint256 decimals);

  function getOptimalLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidityB
  ) external view returns (uint256 liquidityA);

  function setupContracts(
    address,
    address,
    address,
    address,
    address[] memory,
    address[] memory,
    address[] memory,
    address[] memory
  ) external;

  function addBuyer(address) external;

  function removeBuyer(address) external;

  function addSeller(address) external;

  function removeSeller(address) external;

  function addLiquidityAdder(address) external;

  function removeLiquidityAdder(address) external;

  function addLiquidityRemover(address) external;

  function removeLiquidityRemover(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ILiquidityExtension {
  function hasMinimumReserves() external view returns (bool);

  function collateralDeficit() external view returns (uint256, uint256);

  function reserveRatio() external view returns (uint256, uint256);

  function reserveRatioAverage(uint256)
    external
    view
    returns (uint256, uint256);

  function purchaseAndBurn(uint256 amount) external returns (uint256 purchased);

  function allocateBurnBudget(uint256 amount) external;

  function buyBack(uint256 maltAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IAuctionStartController {
  function checkForStart() external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/access/AccessControl.sol";
import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/security/ReentrancyGuard.sol";
import "./interfaces/IRepository.sol";

/// @title Permissions
/// @author 0xScotch <[email protected]>
/// @notice Inherited by almost all Malt contracts to provide access control
contract Permissions is AccessControl, ReentrancyGuard {
  using SafeERC20 for ERC20;

  // Timelock has absolute power across the system
  bytes32 public constant TIMELOCK_ROLE =
    0xf66846415d2bf9eabda9e84793ff9c0ea96d87f50fc41e66aa16469c6a442f05;
  bytes32 public constant ADMIN_ROLE =
    0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775;
  bytes32 public constant INTERNAL_WHITELIST_ROLE =
    0xe5b3f2579db3f05863c923698749c1a62f6272567d652899a476ff0172381367;

  IRepository public repository;

  function _initialSetup(address _repository) internal {
    require(_repository != address(0), "Perm: Repo setup 0x0");
    _setRoleAdmin(TIMELOCK_ROLE, TIMELOCK_ROLE);
    _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    _setRoleAdmin(INTERNAL_WHITELIST_ROLE, ADMIN_ROLE);

    repository = IRepository(_repository);
  }

  function grantRoleMultiple(bytes32 role, address[] calldata addresses)
    external
    onlyRoleMalt(getRoleAdmin(role), "Only role admin")
  {
    uint256 length = addresses.length;
    for (uint256 i; i < length; ++i) {
      address account = addresses[i];
      require(account != address(0), "0x0");
      _grantRole(role, account);
    }
  }

  function emergencyWithdrawGAS(address payable destination)
    external
    onlyRoleMalt(TIMELOCK_ROLE, "Must have timelock role")
  {
    require(destination != address(0), "Withdraw: addr(0)");
    // Transfers the entire balance of the Gas token to destination
    (bool success, ) = destination.call{value: address(this).balance}("");
    require(success, "emergencyWithdrawGAS error");
  }

  function emergencyWithdraw(address _token, address destination)
    external
    onlyRoleMalt(TIMELOCK_ROLE, "Must have timelock role")
  {
    require(destination != address(0), "Withdraw: addr(0)");
    // Transfers the entire balance of an ERC20 token at _token to destination
    ERC20 token = ERC20(_token);
    token.safeTransfer(destination, token.balanceOf(address(this)));
  }

  function partialWithdrawGAS(address payable destination, uint256 amount)
    external
    onlyRoleMalt(TIMELOCK_ROLE, "Must have timelock role")
  {
    require(destination != address(0), "Withdraw: addr(0)");
    (bool success, ) = destination.call{value: amount}("");
    require(success, "partialWithdrawGAS error");
  }

  function partialWithdraw(
    address _token,
    address destination,
    uint256 amount
  ) external onlyRoleMalt(TIMELOCK_ROLE, "Must have timelock role") {
    require(destination != address(0), "Withdraw: addr(0)");
    ERC20 token = ERC20(_token);
    token.safeTransfer(destination, amount);
  }

  function hasRole(bytes32 role, address account)
    public
    view
    override
    returns (bool)
  {
    if (super.hasRole(role, account)) {
      return true;
    }

    if (address(repository) == address(0)) {
      return false;
    }
    return repository.hasRole(role, account);
  }

  /*
   * INTERNAL METHODS
   */
  function _transferRole(
    address newAccount,
    address oldAccount,
    bytes32 role
  ) internal {
    _revokeRole(role, oldAccount);
    _grantRole(role, newAccount);
  }

  function _roleSetup(bytes32 role, address account) internal {
    _grantRole(role, account);
    _setRoleAdmin(role, ADMIN_ROLE);
  }

  function _onlyRoleMalt(bytes32 role, string memory reason) internal view {
    require(hasRole(role, _msgSender()), reason);
  }

  // Using internal function calls here reduces compiled bytecode size
  modifier onlyRoleMalt(bytes32 role, string memory reason) {
    _onlyRoleMalt(role, reason);
    _;
  }

  // verifies that the caller is not a contract.
  modifier onlyEOA() {
    require(
      hasRole(INTERNAL_WHITELIST_ROLE, _msgSender()) || msg.sender == tx.origin,
      "Perm: Only EOA"
    );
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IBurnMintableERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  function decimals() external view returns (uint256);

  function burn(address account, uint256 amount) external;

  function mint(address account, uint256 amount) external;

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
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.11;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(
    address indexed sender,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../StabilizedPool/StabilizedPool.sol";

interface IStabilizedPoolFactory {
  function getPool(address pool)
    external
    view
    returns (
      address collateralToken,
      address updater,
      string memory name
    );

  function getPeripheryContracts(address pool)
    external
    view
    returns (
      address dataLab,
      address dexHandler,
      address transferVerifier,
      address keeper,
      address dualMA
    );

  function getRewardSystemContracts(address pool)
    external
    view
    returns (
      address vestingDistributor,
      address linearDistributor,
      address rewardOverflow,
      address rewardThrottle
    );

  function getStakingContracts(address pool)
    external
    view
    returns (
      address bonding,
      address miningService,
      address vestedMine,
      address forfeitHandler,
      address linearMine,
      address reinvestor
    );

  function getCoreContracts(address pool)
    external
    view
    returns (
      address auction,
      address auctionEscapeHatch,
      address impliedCollateralService,
      address liquidityExtension,
      address profitDistributor,
      address stabilizerNode,
      address swingTrader,
      address swingTraderManager
    );

  function getStabilizedPool(address)
    external
    view
    returns (StabilizedPool memory);

  function setCurrentPool(address, StabilizedPool memory) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IAuction.sol";

interface IStabilizerNode {
  function stabilize() external;

  function auction() external view returns (IAuction);

  function priceAveragePeriod() external view returns (uint256);

  function upperStabilityThresholdBps() external view returns (uint256);

  function lowerStabilityThresholdBps() external view returns (uint256);

  function onlyStabilizeToPeg() external view returns (bool);

  function primedWindowData() external view returns (bool, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IProfitDistributor {
  function handleProfit(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../StabilityPod/PoolCollateral.sol";

interface IGlobalImpliedCollateralService {
  function sync(PoolCollateral memory) external;

  function syncArbTokens(address, uint256) external;

  function totalPhantomMalt() external view returns (uint256);

  function totalCollateral() external view returns (uint256);

  function totalSwingTraderCollateral() external view returns (uint256);

  function totalSwingTraderMalt() external view returns (uint256);

  function totalArbTokens() external view returns (uint256);

  function collateralRatio() external view returns (uint256);

  function swingTraderCollateralRatio() external view returns (uint256);

  function swingTraderCollateralDeficit() external view returns (uint256);

  function setPoolUpdater(address, address) external;

  function proposeNewUpdaterManager(address) external;

  function acceptUpdaterManagerRole() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IMovingAverage {
  function getValue() external view returns (uint256);

  function getValueWithLookback(uint256 _lookbackTime)
    external
    view
    returns (uint256);

  function getLiveSample()
    external
    view
    returns (
      uint64,
      uint256,
      uint256,
      uint256
    );

  function update(uint256 newValue) external;

  function sampleLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IRepository {
  function hasRole(bytes32 role, address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

struct Core {
  address auction;
  address auctionEscapeHatch;
  address impliedCollateralService;
  address liquidityExtension;
  address profitDistributor;
  address stabilizerNode;
  address swingTrader;
  address swingTraderManager;
}

struct Staking {
  address bonding;
  address forfeitHandler;
  address linearMine;
  address miningService;
  address reinvestor;
  address vestedMine;
}

struct RewardSystem {
  address linearDistributor;
  address rewardOverflow;
  address rewardThrottle;
  address vestingDistributor;
}

struct Periphery {
  address dataLab;
  address dexHandler;
  address dualMA;
  address keeper;
  address swingTraderMaltRatioMA;
  address transferVerifier;
}

struct StabilizedPool {
  address collateralToken;
  Core core;
  string name;
  Periphery periphery;
  address pool;
  RewardSystem rewardSystem;
  Staking staking;
  address updater;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IAuction {
  function unclaimedArbTokens() external view returns (uint256);

  function replenishingAuctionId() external view returns (uint256);

  function currentAuctionId() external view returns (uint256);

  function purchaseArbitrageTokens(uint256 amount, uint256 minPurchased)
    external;

  function claimArbitrage(uint256 _auctionId) external;

  function isAuctionFinished(uint256 _id) external view returns (bool);

  function auctionActive(uint256 _id) external view returns (bool);

  function isAuctionFinalized(uint256 _id) external view returns (bool);

  function userClaimableArbTokens(address account, uint256 auctionId)
    external
    view
    returns (uint256);

  function balanceOfArbTokens(uint256 _auctionId, address account)
    external
    view
    returns (uint256);

  function averageMaltPrice(uint256 _id) external view returns (uint256);

  function currentPrice(uint256 _id) external view returns (uint256);

  function getAuctionCommitments(uint256 _id)
    external
    view
    returns (uint256 commitments, uint256 maxCommitments);

  function getAuctionPrices(uint256 _id)
    external
    view
    returns (
      uint256 startingPrice,
      uint256 endingPrice,
      uint256 finalPrice
    );

  function auctionExists(uint256 _id) external view returns (bool);

  function getAccountCommitments(address account)
    external
    view
    returns (
      uint256[] memory auctions,
      uint256[] memory commitments,
      uint256[] memory awardedTokens,
      uint256[] memory redeemedTokens,
      uint256[] memory finalPrice,
      uint256[] memory claimable,
      uint256[] memory exitedTokens,
      bool[] memory finished
    );

  function getAccountCommitmentAuctions(address account)
    external
    view
    returns (uint256[] memory);

  function hasOngoingAuction() external view returns (bool);

  function getActiveAuction()
    external
    view
    returns (
      uint256 auctionId,
      uint256 maxCommitments,
      uint256 commitments,
      uint256 maltPurchased,
      uint256 startingPrice,
      uint256 endingPrice,
      uint256 finalPrice,
      uint256 pegPrice,
      uint256 startingTime,
      uint256 endingTime,
      uint256 finalBurnBudget,
      uint256 finalPurchased
    );

  function getAuction(uint256 _id)
    external
    view
    returns (
      uint256 maxCommitments,
      uint256 commitments,
      uint256 startingPrice,
      uint256 endingPrice,
      uint256 finalPrice,
      uint256 pegPrice,
      uint256 startingTime,
      uint256 endingTime,
      uint256 finalBurnBudget,
      uint256 finalPurchased
    );

  function getAuctionCore(uint256 _id)
    external
    view
    returns (
      uint256 auctionId,
      uint256 commitments,
      uint256 maltPurchased,
      uint256 startingPrice,
      uint256 finalPrice,
      uint256 pegPrice,
      uint256 startingTime,
      uint256 endingTime,
      uint256 preAuctionReserveRatio,
      bool active
    );

  function checkAuctionFinalization() external;

  function allocateArbRewards(uint256 rewarded) external returns (uint256);

  function triggerAuction(uint256 pegPrice, uint256 purchaseAmount)
    external
    returns (bool);

  function getAuctionParticipationForAccount(address account, uint256 auctionId)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    );

  function accountExit(
    address account,
    uint256 auctionId,
    uint256 amount
  ) external;

  function endAuctionEarly() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

struct CoreCollateral {
  uint256 total;
  uint256 rewardOverflow;
  uint256 liquidityExtension;
  uint256 swingTrader;
  uint256 swingTraderMalt;
  uint256 arbTokens;
}

struct PoolCollateral {
  address lpPool;
  uint256 total;
  uint256 rewardOverflow;
  uint256 liquidityExtension;
  uint256 swingTrader;
  uint256 swingTraderMalt;
  uint256 arbTokens;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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