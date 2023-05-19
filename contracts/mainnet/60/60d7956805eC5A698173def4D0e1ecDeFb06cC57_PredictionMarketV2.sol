pragma solidity ^0.8.18;

// openzeppelin imports
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library CeilDiv {
  // calculates ceil(x/y)
  function ceildiv(uint256 x, uint256 y) internal pure returns (uint256) {
    if (x > 0) return ((x - 1) / y) + 1;
    return x / y;
  }
}

interface IRealityETH_ERC20 {
  function askQuestionERC20(
    uint256 template_id,
    string calldata question,
    address arbitrator,
    uint32 timeout,
    uint32 opening_ts,
    uint256 nonce,
    uint256 tokens
  ) external returns (bytes32);

  function claimMultipleAndWithdrawBalance(
    bytes32[] calldata question_ids,
    uint256[] calldata lengths,
    bytes32[] calldata hist_hashes,
    address[] calldata addrs,
    uint256[] calldata bonds,
    bytes32[] calldata answers
  ) external;

  function claimWinnings(
    bytes32 question_id,
    bytes32[] calldata history_hashes,
    address[] calldata addrs,
    uint256[] calldata bonds,
    bytes32[] calldata answers
  ) external;

  function notifyOfArbitrationRequest(
    bytes32 question_id,
    address requester,
    uint256 max_previous
  ) external;

  function submitAnswerERC20(
    bytes32 question_id,
    bytes32 answer,
    uint256 max_previous,
    uint256 tokens
  ) external;

  function questions(bytes32)
    external
    view
    returns (
      bytes32 content_hash,
      address arbitrator,
      uint32 opening_ts,
      uint32 timeout,
      uint32 finalize_ts,
      bool is_pending_arbitration,
      uint256 bounty,
      bytes32 best_answer,
      bytes32 history_hash,
      uint256 bond,
      uint256 min_bond
    );

  function resultFor(bytes32 question_id) external view returns (bytes32);
}

interface IWETH {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256) external;

  function approve(address guy, uint256 wad) external returns (bool);
}

/// @title Market Contract Factory
contract PredictionMarketV2 is ReentrancyGuard {
  using SafeERC20 for IERC20;
  using CeilDiv for uint256;

  // ------ Events ------

  event MarketCreated(
    address indexed user,
    uint256 indexed marketId,
    uint256 outcomes,
    string question,
    string image,
    IERC20 token
  );

  event MarketActionTx(
    address indexed user,
    MarketAction indexed action,
    uint256 indexed marketId,
    uint256 outcomeId,
    uint256 shares,
    uint256 value,
    uint256 timestamp
  );

  event MarketOutcomeShares(uint256 indexed marketId, uint256 timestamp, uint256[] outcomeShares, uint256 liquidity);

  event MarketOutcomePrice(uint256 indexed marketId, uint256 indexed outcomeId, uint256 value, uint256 timestamp);

  event MarketLiquidity(
    uint256 indexed marketId,
    uint256 value, // total liquidity
    uint256 price, // value of one liquidity share; max: 1 (even odds situation)
    uint256 timestamp
  );

  event MarketResolved(address indexed user, uint256 indexed marketId, uint256 outcomeId, uint256 timestamp);

  // ------ Events End ------

  uint256 public constant MAX_UINT_256 = type(uint256).max;

  uint256 public constant ONE = 10**18;

  uint256 public constant MAX_OUTCOMES = 2**5;

  uint256 public constant MAX_FEE = 5 * 10**16; // 5%

  enum MarketState {
    open,
    closed,
    resolved
  }
  enum MarketAction {
    buy,
    sell,
    addLiquidity,
    removeLiquidity,
    claimWinnings,
    claimLiquidity,
    claimFees,
    claimVoided
  }

  struct Market {
    // market details
    uint256 closesAtTimestamp;
    uint256 balance; // total stake
    uint256 liquidity; // stake held
    uint256 sharesAvailable; // shares held (all outcomes)
    mapping(address => uint256) liquidityShares;
    mapping(address => bool) liquidityClaims; // wether user has claimed liquidity earnings
    MarketState state; // resolution variables
    MarketResolution resolution; // fees
    MarketFees fees;
    // market outcomes
    uint256 outcomeCount;
    mapping(uint256 => MarketOutcome) outcomes;
    IERC20 token; // ERC20 token market will use for trading
  }

  struct MarketFees {
    uint256 fee; // fee % taken from every transaction
    uint256 poolWeight; // internal var used to ensure pro-rate fee distribution
    mapping(address => uint256) claimed;
    address treasury; // address to send treasury fees to
    uint256 treasuryFee; // fee % taken from every transaction to a treasury address
  }

  struct MarketResolution {
    bool resolved;
    uint256 outcomeId;
    bytes32 questionId; // realitio questionId
  }

  struct MarketOutcome {
    uint256 marketId;
    uint256 id;
    Shares shares;
  }

  struct Shares {
    uint256 total; // number of shares
    uint256 available; // available shares
    mapping(address => uint256) holders;
    mapping(address => bool) claims; // wether user has claimed winnings
    mapping(address => bool) voidedClaims; // wether user has claimed voided market shares
  }

  struct CreateMarketDescription {
    uint256 value;
    uint256 closesAt;
    uint256 outcomes;
    IERC20 token;
    uint256[] distribution;
    string question;
    string image;
    address arbitrator;
    uint256 fee;
    uint256 treasuryFee;
    address treasury;
  }

  uint256[] marketIds;
  mapping(uint256 => Market) markets;
  uint256 public marketIndex;

  // realitio configs
  address public immutable realitioAddress;
  uint256 public immutable realitioTimeout;
  // market creation
  IERC20 public immutable requiredBalanceToken; // token used for rewards / market creation
  uint256 public immutable requiredBalance; // required balance for market creation
  // weth configs
  IWETH public immutable WETH;

  // ------ Modifiers ------

  modifier isMarket(uint256 marketId) {
    require(marketId < marketIndex, "Market not found");
    _;
  }

  modifier timeTransitions(uint256 marketId) {
    if (block.timestamp > markets[marketId].closesAtTimestamp && markets[marketId].state == MarketState.open) {
      nextState(marketId);
    }
    _;
  }

  modifier atState(uint256 marketId, MarketState state) {
    require(markets[marketId].state == state, "Market in incorrect state");
    _;
  }

  modifier notAtState(uint256 marketId, MarketState state) {
    require(markets[marketId].state != state, "Market in incorrect state");
    _;
  }

  modifier transitionNext(uint256 marketId) {
    _;
    nextState(marketId);
  }

  modifier mustHoldRequiredBalance() {
    require(
      requiredBalance == 0 || requiredBalanceToken.balanceOf(msg.sender) >= requiredBalance,
      "minimum erc20 balance not held"
    );
    _;
  }

  modifier isWETHMarket(uint256 marketId) {
    require(address(WETH) != address(0), "WETH address is address 0");
    require(address(markets[marketId].token) == address(WETH), "Market token is not WETH");
    _;
  }

  // ------ Modifiers End ------

  /// @dev protocol is immutable and has no ownership
  constructor(
    IERC20 _requiredBalanceToken,
    uint256 _requiredBalance,
    address _realitioAddress,
    uint256 _realitioTimeout,
    IWETH _WETH
  ) {
    require(_realitioAddress != address(0), "_realitioAddress is address 0");
    require(_realitioTimeout > 0, "timeout must be positive");

    requiredBalanceToken = _requiredBalanceToken;
    requiredBalance = _requiredBalance;
    realitioAddress = _realitioAddress;
    realitioTimeout = _realitioTimeout;
    WETH = _WETH;
  }

  receive() external payable {
    assert(msg.sender == address(WETH)); // only accept ETH via fallback from the WETH contract
  }

  // ------ Core Functions ------

  /// @dev Creates a market, initializes the outcome shares pool and submits a question in Realitio
  function _createMarket(CreateMarketDescription memory desc) private mustHoldRequiredBalance returns (uint256) {
    uint256 marketId = marketIndex;
    marketIds.push(marketId);

    Market storage market = markets[marketId];

    require(desc.value > 0, "stake needs to be > 0");
    require(desc.closesAt > block.timestamp, "resolution before current date");
    require(desc.arbitrator != address(0), "invalid arbitrator address");
    require(desc.outcomes > 0 && desc.outcomes <= MAX_OUTCOMES, "outcome count not between 1-32");
    require(desc.fee <= MAX_FEE, "fee must be <= 5%");
    require(desc.treasuryFee <= MAX_FEE, "treasury fee must be <= 5%");

    market.token = desc.token;
    market.closesAtTimestamp = desc.closesAt;
    market.state = MarketState.open;
    market.fees.fee = desc.fee;
    market.fees.treasuryFee = desc.treasuryFee;
    market.fees.treasury = desc.treasury;
    // setting intial value to an integer that does not map to any outcomeId
    market.resolution.outcomeId = MAX_UINT_256;
    market.outcomeCount = desc.outcomes;

    // creating question in realitio
    market.resolution.questionId = IRealityETH_ERC20(realitioAddress).askQuestionERC20(
      2,
      desc.question,
      desc.arbitrator,
      uint32(realitioTimeout),
      uint32(desc.closesAt),
      0,
      0
    );

    _addLiquidity(marketId, desc.value, desc.distribution);

    // emiting initial price events
    emitMarketActionEvents(marketId);
    emit MarketCreated(msg.sender, marketId, desc.outcomes, desc.question, desc.image, desc.token);

    // incrementing market array index
    marketIndex = marketIndex + 1;

    return marketId;
  }

  function createMarket(CreateMarketDescription calldata desc) external returns (uint256) {
    uint256 marketId = _createMarket(
      CreateMarketDescription({
        value: desc.value,
        closesAt: desc.closesAt,
        outcomes: desc.outcomes,
        token: desc.token,
        distribution: desc.distribution,
        question: desc.question,
        image: desc.image,
        arbitrator: desc.arbitrator,
        fee: desc.fee,
        treasuryFee: desc.treasuryFee,
        treasury: desc.treasury
      })
    );
    // transferring funds
    desc.token.safeTransferFrom(msg.sender, address(this), desc.value);

    return marketId;
  }

  function createMarketWithETH(CreateMarketDescription calldata desc) external payable returns (uint256) {
    require(address(desc.token) == address(WETH), "Market token is not WETH");
    require(msg.value == desc.value, "value does not match arguments");
    uint256 marketId = _createMarket(
      CreateMarketDescription({
        value: desc.value,
        closesAt: desc.closesAt,
        outcomes: desc.outcomes,
        token: desc.token,
        distribution: desc.distribution,
        question: desc.question,
        image: desc.image,
        arbitrator: desc.arbitrator,
        fee: desc.fee,
        treasuryFee: desc.treasuryFee,
        treasury: desc.treasury
      })
    );
    // transferring funds
    IWETH(WETH).deposit{value: msg.value}();

    return marketId;
  }

  /// @dev Calculates the number of shares bought with "amount" balance
  function calcBuyAmount(
    uint256 amount,
    uint256 marketId,
    uint256 outcomeId
  ) public view returns (uint256) {
    uint256[] memory outcomesShares = getMarketOutcomesShares(marketId);
    uint256 fee = getMarketFee(marketId);
    uint256 amountMinusFees = amount - ((amount * fee) / ONE);
    uint256 buyTokenPoolBalance = outcomesShares[outcomeId];
    uint256 endingOutcomeBalance = buyTokenPoolBalance * ONE;
    for (uint256 i = 0; i < outcomesShares.length; ++i) {
      if (i != outcomeId) {
        uint256 outcomeShares = outcomesShares[i];
        endingOutcomeBalance = (endingOutcomeBalance * outcomeShares).ceildiv(outcomeShares + amountMinusFees);
      }
    }
    require(endingOutcomeBalance > 0, "must have non-zero balances");

    return buyTokenPoolBalance + amountMinusFees - (endingOutcomeBalance.ceildiv(ONE));
  }

  /// @dev Calculates the number of shares needed to be sold in order to receive "amount" in balance
  function calcSellAmount(
    uint256 amount,
    uint256 marketId,
    uint256 outcomeId
  ) public view returns (uint256 outcomeTokenSellAmount) {
    uint256[] memory outcomesShares = getMarketOutcomesShares(marketId);
    uint256 fee = getMarketFee(marketId);
    uint256 amountPlusFees = (amount * ONE) / (ONE - fee);
    uint256 sellTokenPoolBalance = outcomesShares[outcomeId];
    uint256 endingOutcomeBalance = sellTokenPoolBalance * ONE;
    for (uint256 i = 0; i < outcomesShares.length; ++i) {
      if (i != outcomeId) {
        uint256 outcomeShares = outcomesShares[i];
        endingOutcomeBalance = (endingOutcomeBalance * outcomeShares).ceildiv(outcomeShares - amountPlusFees);
      }
    }
    require(endingOutcomeBalance > 0, "must have non-zero balances");

    return amountPlusFees + endingOutcomeBalance.ceildiv(ONE) - sellTokenPoolBalance;
  }

  /// @dev Buy shares of a market outcome
  function _buy(
    uint256 marketId,
    uint256 outcomeId,
    uint256 minOutcomeSharesToBuy,
    uint256 value
  ) private timeTransitions(marketId) atState(marketId, MarketState.open) {
    Market storage market = markets[marketId];

    uint256 shares = calcBuyAmount(value, marketId, outcomeId);
    require(shares >= minOutcomeSharesToBuy, "minimum buy amount not reached");
    require(shares > 0, "shares amount is 0");

    // subtracting fee from transaction value
    uint256 feeAmount = (value * market.fees.fee) / ONE;
    market.fees.poolWeight = market.fees.poolWeight + feeAmount;
    uint256 valueMinusFees = value - feeAmount;

    uint256 treasuryFeeAmount = (value * market.fees.treasuryFee) / ONE;
    valueMinusFees = valueMinusFees - treasuryFeeAmount;

    MarketOutcome storage outcome = market.outcomes[outcomeId];

    // Funding market shares with received funds
    addSharesToMarket(marketId, valueMinusFees);

    require(outcome.shares.available >= shares, "shares pool balance is too low");

    transferOutcomeSharesfromPool(msg.sender, marketId, outcomeId, shares);

    emit MarketActionTx(msg.sender, MarketAction.buy, marketId, outcomeId, shares, value, block.timestamp);
    emitMarketActionEvents(marketId);

    // transfering treasury fee to treasury address
    if (treasuryFeeAmount > 0) {
      market.token.safeTransfer(market.fees.treasury, treasuryFeeAmount);
    }
  }

  /// @dev Buy shares of a market outcome
  function buy(
    uint256 marketId,
    uint256 outcomeId,
    uint256 minOutcomeSharesToBuy,
    uint256 value
  ) external nonReentrant {
    Market storage market = markets[marketId];
    market.token.safeTransferFrom(msg.sender, address(this), value);
    _buy(marketId, outcomeId, minOutcomeSharesToBuy, value);
  }

  function buyWithETH(
    uint256 marketId,
    uint256 outcomeId,
    uint256 minOutcomeSharesToBuy
  ) external payable isWETHMarket(marketId) nonReentrant {
    uint256 value = msg.value;
    // wrapping and depositing funds
    IWETH(WETH).deposit{value: value}();
    _buy(marketId, outcomeId, minOutcomeSharesToBuy, value);
  }

  /// @dev Sell shares of a market outcome
  function _sell(
    uint256 marketId,
    uint256 outcomeId,
    uint256 value,
    uint256 maxOutcomeSharesToSell
  ) private timeTransitions(marketId) atState(marketId, MarketState.open) {
    Market storage market = markets[marketId];
    MarketOutcome storage outcome = market.outcomes[outcomeId];

    uint256 shares = calcSellAmount(value, marketId, outcomeId);

    require(shares <= maxOutcomeSharesToSell, "maximum sell amount exceeded");
    require(shares > 0, "shares amount is 0");
    require(outcome.shares.holders[msg.sender] >= shares, "insufficient shares balance");

    transferOutcomeSharesToPool(msg.sender, marketId, outcomeId, shares);

    // adding fees to transaction value
    uint256 fee = getMarketFee(marketId);
    {
      uint256 feeAmount = (value * market.fees.fee) / (ONE - fee);
      market.fees.poolWeight = market.fees.poolWeight + feeAmount;
    }
    uint256 valuePlusFees = value + (value * fee) / (ONE - fee);

    require(market.balance >= valuePlusFees, "insufficient market balance");

    // Rebalancing market shares
    removeSharesFromMarket(marketId, valuePlusFees);

    emit MarketActionTx(msg.sender, MarketAction.sell, marketId, outcomeId, shares, value, block.timestamp);
    emitMarketActionEvents(marketId);

    {
      uint256 treasuryFeeAmount = (value * market.fees.treasuryFee) / (ONE - fee);
      // transfering treasury fee to treasury address
      if (treasuryFeeAmount > 0) {
        market.token.safeTransfer(market.fees.treasury, treasuryFeeAmount);
      }
    }
  }

  function sell(
    uint256 marketId,
    uint256 outcomeId,
    uint256 value,
    uint256 maxOutcomeSharesToSell
  ) external nonReentrant {
    _sell(marketId, outcomeId, value, maxOutcomeSharesToSell);
    // Transferring funds to user
    Market storage market = markets[marketId];
    market.token.safeTransfer(msg.sender, value);
  }

  function sellToETH(
    uint256 marketId,
    uint256 outcomeId,
    uint256 value,
    uint256 maxOutcomeSharesToSell
  ) external isWETHMarket(marketId) nonReentrant {
    Market storage market = markets[marketId];
    require(address(market.token) == address(WETH), "market token is not WETH");

    _sell(marketId, outcomeId, value, maxOutcomeSharesToSell);

    IWETH(WETH).withdraw(value);
    (bool sent, ) = payable(msg.sender).call{value: value}("");
    require(sent, "Failed to send Ether");
  }

  /// @dev Adds liquidity to a market - external
  function _addLiquidity(
    uint256 marketId,
    uint256 value,
    uint256[] memory distribution
  ) private timeTransitions(marketId) atState(marketId, MarketState.open) {
    Market storage market = markets[marketId];

    require(value > 0, "stake has to be greater than 0.");

    uint256 liquidityAmount;

    uint256[] memory outcomesShares = getMarketOutcomesShares(marketId);
    uint256[] memory sendBackAmounts = new uint256[](outcomesShares.length);
    uint256 poolWeight = 0;

    if (market.liquidity > 0) {
      require(distribution.length == 0, "market already funded");

      // part of the liquidity is exchanged for outcome shares if market is not balanced
      for (uint256 i = 0; i < outcomesShares.length; ++i) {
        uint256 outcomeShares = outcomesShares[i];
        if (poolWeight < outcomeShares) poolWeight = outcomeShares;
      }

      for (uint256 i = 0; i < outcomesShares.length; ++i) {
        uint256 remaining = (value * outcomesShares[i]) / poolWeight;
        sendBackAmounts[i] = value - remaining;
      }

      liquidityAmount = (value * market.liquidity) / poolWeight;

      // re-balancing fees pool
      rebalanceFeesPool(marketId, liquidityAmount, MarketAction.addLiquidity);
    } else {
      // funding market with no liquidity
      if (distribution.length > 0) {
        require(distribution.length == outcomesShares.length, "distribution length not matching");

        uint256 maxHint = 0;
        for (uint256 i = 0; i < distribution.length; ++i) {
          uint256 hint = distribution[i];
          if (maxHint < hint) maxHint = hint;
        }

        for (uint256 i = 0; i < distribution.length; ++i) {
          uint256 remaining = (value * distribution[i]) / maxHint;
          require(remaining > 0, "must hint a valid distribution");
          sendBackAmounts[i] = value - remaining;
        }
      }

      // funding market with total liquidity amount
      liquidityAmount = value;
    }

    // funding market
    market.liquidity = market.liquidity + liquidityAmount;
    market.liquidityShares[msg.sender] = market.liquidityShares[msg.sender] + liquidityAmount;

    addSharesToMarket(marketId, value);

    {
      // transform sendBackAmounts to array of amounts added
      for (uint256 i = 0; i < sendBackAmounts.length; ++i) {
        if (sendBackAmounts[i] > 0) {
          transferOutcomeSharesfromPool(msg.sender, marketId, i, sendBackAmounts[i]);
        }
      }

      // emitting events, using outcome 0 for price reference
      uint256 referencePrice = getMarketOutcomePrice(marketId, 0);

      for (uint256 i = 0; i < sendBackAmounts.length; ++i) {
        if (sendBackAmounts[i] > 0) {
          // outcome price = outcome shares / reference outcome shares * reference outcome price
          uint256 outcomePrice = (referencePrice * market.outcomes[0].shares.available) /
            market.outcomes[i].shares.available;

          emit MarketActionTx(
            msg.sender,
            MarketAction.buy,
            marketId,
            i,
            sendBackAmounts[i],
            (sendBackAmounts[i] * outcomePrice) / ONE, // price * shares
            block.timestamp
          );
        }
      }
    }

    uint256 liquidityPrice = getMarketLiquidityPrice(marketId);
    uint256 liquidityValue = (liquidityPrice * liquidityAmount) / ONE;

    emit MarketActionTx(
      msg.sender,
      MarketAction.addLiquidity,
      marketId,
      0,
      liquidityAmount,
      liquidityValue,
      block.timestamp
    );
    emit MarketLiquidity(marketId, market.liquidity, liquidityPrice, block.timestamp);
  }

  function addLiquidity(uint256 marketId, uint256 value) external {
    uint256[] memory distribution = new uint256[](0);
    _addLiquidity(marketId, value, distribution);

    Market storage market = markets[marketId];
    market.token.safeTransferFrom(msg.sender, address(this), value);
  }

  function addLiquidityWithETH(uint256 marketId) external payable isWETHMarket(marketId) {
    uint256 value = msg.value;
    uint256[] memory distribution = new uint256[](0);
    _addLiquidity(marketId, value, distribution);
    // wrapping and depositing funds
    IWETH(WETH).deposit{value: value}();
  }

  /// @dev Removes liquidity to a market - external
  function _removeLiquidity(uint256 marketId, uint256 shares)
    private
    timeTransitions(marketId)
    atState(marketId, MarketState.open)
    returns (uint256)
  {
    Market storage market = markets[marketId];

    require(market.liquidityShares[msg.sender] >= shares, "insufficient shares balance");
    // claiming any pending fees
    claimFees(marketId);

    // re-balancing fees pool
    rebalanceFeesPool(marketId, shares, MarketAction.removeLiquidity);

    uint256[] memory outcomesShares = getMarketOutcomesShares(marketId);
    uint256[] memory sendAmounts = new uint256[](outcomesShares.length);
    uint256 poolWeight = MAX_UINT_256;

    // part of the liquidity is exchanged for outcome shares if market is not balanced
    for (uint256 i = 0; i < outcomesShares.length; ++i) {
      uint256 outcomeShares = outcomesShares[i];
      if (poolWeight > outcomeShares) poolWeight = outcomeShares;
    }

    uint256 liquidityAmount = (shares * poolWeight) / market.liquidity;

    for (uint256 i = 0; i < outcomesShares.length; ++i) {
      sendAmounts[i] = (outcomesShares[i] * shares) / market.liquidity;
      sendAmounts[i] = sendAmounts[i] - liquidityAmount;
    }

    // removing liquidity from market
    removeSharesFromMarket(marketId, liquidityAmount);
    market.liquidity = market.liquidity - shares;
    // removing liquidity tokens from market creator
    market.liquidityShares[msg.sender] = market.liquidityShares[msg.sender] - shares;

    for (uint256 i = 0; i < outcomesShares.length; ++i) {
      if (sendAmounts[i] > 0) {
        transferOutcomeSharesfromPool(msg.sender, marketId, i, sendAmounts[i]);
      }
    }

    // emitting events, using outcome 0 for price reference
    uint256 referencePrice = getMarketOutcomePrice(marketId, 0);

    for (uint256 i = 0; i < outcomesShares.length; ++i) {
      if (sendAmounts[i] > 0) {
        // outcome price = outcome shares / reference outcome shares * reference outcome price
        uint256 outcomePrice = (referencePrice * market.outcomes[0].shares.available) /
          market.outcomes[i].shares.available;

        emit MarketActionTx(
          msg.sender,
          MarketAction.buy,
          marketId,
          i,
          sendAmounts[i],
          (sendAmounts[i] * outcomePrice) / ONE, // price * shares
          block.timestamp
        );
      }
    }

    emit MarketActionTx(
      msg.sender,
      MarketAction.removeLiquidity,
      marketId,
      0,
      shares,
      liquidityAmount,
      block.timestamp
    );
    emit MarketLiquidity(marketId, market.liquidity, getMarketLiquidityPrice(marketId), block.timestamp);

    return liquidityAmount;
  }

  function removeLiquidity(uint256 marketId, uint256 shares) external {
    uint256 value = _removeLiquidity(marketId, shares);
    // transferring user funds from liquidity removed
    Market storage market = markets[marketId];
    market.token.safeTransfer(msg.sender, value);
  }

  function removeLiquidityToETH(uint256 marketId, uint256 shares) external isWETHMarket(marketId) {
    uint256 value = _removeLiquidity(marketId, shares);
    // unwrapping and transferring user funds from liquidity removed
    IWETH(WETH).withdraw(value);
    (bool sent, ) = payable(msg.sender).call{value: value}("");
    require(sent, "Failed to send Ether");
  }

  /// @dev Fetches winning outcome from Realitio and resolves the market
  function resolveMarketOutcome(uint256 marketId)
    external
    timeTransitions(marketId)
    atState(marketId, MarketState.closed)
    transitionNext(marketId)
    returns (uint256)
  {
    Market storage market = markets[marketId];

    // will fail if question is not finalized
    uint256 outcomeId = uint256(IRealityETH_ERC20(realitioAddress).resultFor(market.resolution.questionId));

    market.resolution.outcomeId = outcomeId;

    emit MarketResolved(msg.sender, marketId, outcomeId, block.timestamp);
    emitMarketActionEvents(marketId);

    return market.resolution.outcomeId;
  }

  /// @dev Allows holders of resolved outcome shares to claim earnings.
  function _claimWinnings(uint256 marketId) private atState(marketId, MarketState.resolved) returns (uint256) {
    Market storage market = markets[marketId];
    MarketOutcome storage resolvedOutcome = market.outcomes[market.resolution.outcomeId];

    require(resolvedOutcome.shares.holders[msg.sender] > 0, "user doesn't hold outcome shares");
    require(resolvedOutcome.shares.claims[msg.sender] == false, "user already claimed winnings");

    // 1 share => price = 1
    uint256 value = resolvedOutcome.shares.holders[msg.sender];

    // assuring market has enough funds
    require(market.balance >= value, "insufficient market balance");

    market.balance = market.balance - value;
    resolvedOutcome.shares.claims[msg.sender] = true;

    emit MarketActionTx(
      msg.sender,
      MarketAction.claimWinnings,
      marketId,
      market.resolution.outcomeId,
      resolvedOutcome.shares.holders[msg.sender],
      value,
      block.timestamp
    );

    return value;
  }

  function claimWinnings(uint256 marketId) external {
    uint256 value = _claimWinnings(marketId);
    // transferring user funds from winnings claimed
    Market storage market = markets[marketId];
    market.token.safeTransfer(msg.sender, value);
  }

  function claimWinningsToETH(uint256 marketId) external isWETHMarket(marketId) {
    uint256 value = _claimWinnings(marketId);
    // unwrapping and transferring user funds from winnings claimed
    IWETH(WETH).withdraw(value);
    (bool sent, ) = payable(msg.sender).call{value: value}("");
    require(sent, "Failed to send Ether");
  }

  /// @dev Allows holders of voided outcome shares to claim balance back.
  function _claimVoidedOutcomeShares(uint256 marketId, uint256 outcomeId)
    private
    atState(marketId, MarketState.resolved)
    returns (uint256)
  {
    Market storage market = markets[marketId];
    MarketOutcome storage outcome = market.outcomes[outcomeId];

    require(isMarketVoided(marketId), "market is not voided");
    require(outcome.shares.holders[msg.sender] > 0, "user doesn't hold outcome shares");
    require(outcome.shares.voidedClaims[msg.sender] == false, "user already claimed shares");

    // voided market - shares are valued at last market price
    uint256 price = getMarketOutcomePrice(marketId, outcomeId);
    uint256 value = (price * outcome.shares.holders[msg.sender]) / ONE;

    // assuring market has enough funds
    require(market.balance >= value, "insufficient market balance");

    market.balance = market.balance - value;
    outcome.shares.voidedClaims[msg.sender] = true;

    emit MarketActionTx(
      msg.sender,
      MarketAction.claimVoided,
      marketId,
      outcomeId,
      outcome.shares.holders[msg.sender],
      value,
      block.timestamp
    );

    return value;
  }

  function claimVoidedOutcomeShares(uint256 marketId, uint256 outcomeId) external {
    uint256 value = _claimVoidedOutcomeShares(marketId, outcomeId);
    // transferring user funds from voided outcome shares claimed
    Market storage market = markets[marketId];
    market.token.safeTransfer(msg.sender, value);
  }

  function claimVoidedOutcomeSharesToETH(uint256 marketId, uint256 outcomeId) external isWETHMarket(marketId) {
    uint256 value = _claimVoidedOutcomeShares(marketId, outcomeId);
    // unwrapping and transferring user funds from voided outcome shares claimed
    IWETH(WETH).withdraw(value);
    (bool sent, ) = payable(msg.sender).call{value: value}("");
    require(sent, "Failed to send Ether");
  }

  /// @dev Allows liquidity providers to claim earnings from liquidity providing.
  function _claimLiquidity(uint256 marketId) private atState(marketId, MarketState.resolved) returns (uint256) {
    Market storage market = markets[marketId];

    // claiming any pending fees
    claimFees(marketId);

    require(market.liquidityShares[msg.sender] > 0, "user doesn't hold shares");
    require(market.liquidityClaims[msg.sender] == false, "user already claimed shares");

    // value = total resolved outcome pool shares * pool share (%)
    uint256 liquidityPrice = getMarketLiquidityPrice(marketId);
    uint256 value = (liquidityPrice * market.liquidityShares[msg.sender]) / ONE;

    // assuring market has enough funds
    require(market.balance >= value, "insufficient market balance");

    market.balance = market.balance - value;
    market.liquidityClaims[msg.sender] = true;

    emit MarketActionTx(
      msg.sender,
      MarketAction.claimLiquidity,
      marketId,
      0,
      market.liquidityShares[msg.sender],
      value,
      block.timestamp
    );

    return value;
  }

  function claimLiquidity(uint256 marketId) external {
    uint256 value = _claimLiquidity(marketId);
    // transferring user funds from liquidity claimed
    Market storage market = markets[marketId];
    market.token.safeTransfer(msg.sender, value);
  }

  function claimLiquidityToETH(uint256 marketId) external isWETHMarket(marketId) {
    uint256 value = _claimLiquidity(marketId);
    // unwrapping and transferring user funds from liquidity claimed
    IWETH(WETH).withdraw(value);
    (bool sent, ) = payable(msg.sender).call{value: value}("");
    require(sent, "Failed to send Ether");
  }

  /// @dev Allows liquidity providers to claim their fees share from fees pool
  function _claimFees(uint256 marketId) private returns (uint256) {
    Market storage market = markets[marketId];

    uint256 claimableFees = getUserClaimableFees(marketId, msg.sender);

    if (claimableFees > 0) {
      market.fees.claimed[msg.sender] = market.fees.claimed[msg.sender] + claimableFees;
    }

    emit MarketActionTx(
      msg.sender,
      MarketAction.claimFees,
      marketId,
      0,
      market.liquidityShares[msg.sender],
      claimableFees,
      block.timestamp
    );

    return claimableFees;
  }

  function claimFees(uint256 marketId) public nonReentrant {
    uint256 value = _claimFees(marketId);
    // transferring user funds from fees claimed
    Market storage market = markets[marketId];
    market.token.safeTransfer(msg.sender, value);
  }

  function claimFeesToETH(uint256 marketId) public isWETHMarket(marketId) nonReentrant {
    uint256 value = _claimFees(marketId);
    // unwrapping and transferring user funds from fees claimed
    IWETH(WETH).withdraw(value);
    (bool sent, ) = payable(msg.sender).call{value: value}("");
    require(sent, "Failed to send Ether");
  }

  /// @dev Rebalances the fees pool. Needed in every AddLiquidity / RemoveLiquidity call
  function rebalanceFeesPool(
    uint256 marketId,
    uint256 liquidityShares,
    MarketAction action
  ) private {
    Market storage market = markets[marketId];

    uint256 poolWeight = (liquidityShares * market.fees.poolWeight) / market.liquidity;

    if (action == MarketAction.addLiquidity) {
      market.fees.poolWeight = market.fees.poolWeight + poolWeight;
      market.fees.claimed[msg.sender] = market.fees.claimed[msg.sender] + poolWeight;
    } else {
      market.fees.poolWeight = market.fees.poolWeight - poolWeight;
      market.fees.claimed[msg.sender] = market.fees.claimed[msg.sender] - poolWeight;
    }
  }

  /// @dev Transitions market to next state
  function nextState(uint256 marketId) private {
    Market storage market = markets[marketId];
    market.state = MarketState(uint256(market.state) + 1);
  }

  /// @dev Emits a outcome price event for every outcome
  function emitMarketActionEvents(uint256 marketId) private {
    Market storage market = markets[marketId];
    uint256[] memory outcomeShares = new uint256[](market.outcomeCount);

    for (uint256 i = 0; i < market.outcomeCount; ++i) {
      outcomeShares[i] = market.outcomes[i].shares.available;
    }

    emit MarketOutcomeShares(marketId, block.timestamp, outcomeShares, market.liquidity);
  }

  /// @dev Adds outcome shares to shares pool
  function addSharesToMarket(uint256 marketId, uint256 shares) private {
    Market storage market = markets[marketId];

    for (uint256 i = 0; i < market.outcomeCount; ++i) {
      MarketOutcome storage outcome = market.outcomes[i];

      outcome.shares.available = outcome.shares.available + shares;
      outcome.shares.total = outcome.shares.total + shares;

      // only adding to market total shares, the available remains
      market.sharesAvailable = market.sharesAvailable + shares;
    }

    market.balance = market.balance + shares;
  }

  /// @dev Removes outcome shares from shares pool
  function removeSharesFromMarket(uint256 marketId, uint256 shares) private {
    Market storage market = markets[marketId];

    for (uint256 i = 0; i < market.outcomeCount; ++i) {
      MarketOutcome storage outcome = market.outcomes[i];

      outcome.shares.available = outcome.shares.available - shares;
      outcome.shares.total = outcome.shares.total - shares;

      // only subtracting from market total shares, the available remains
      market.sharesAvailable = market.sharesAvailable - shares;
    }

    market.balance = market.balance - shares;
  }

  /// @dev Transfer outcome shares from pool to user balance
  function transferOutcomeSharesfromPool(
    address user,
    uint256 marketId,
    uint256 outcomeId,
    uint256 shares
  ) private {
    Market storage market = markets[marketId];
    MarketOutcome storage outcome = market.outcomes[outcomeId];

    // transfering shares from shares pool to user
    outcome.shares.holders[user] = outcome.shares.holders[user] + shares;
    outcome.shares.available = outcome.shares.available - shares;
    market.sharesAvailable = market.sharesAvailable - shares;
  }

  /// @dev Transfer outcome shares from user balance back to pool
  function transferOutcomeSharesToPool(
    address user,
    uint256 marketId,
    uint256 outcomeId,
    uint256 shares
  ) private {
    Market storage market = markets[marketId];
    MarketOutcome storage outcome = market.outcomes[outcomeId];

    // adding shares back to pool
    outcome.shares.holders[user] = outcome.shares.holders[user] - shares;
    outcome.shares.available = outcome.shares.available + shares;
    market.sharesAvailable = market.sharesAvailable + shares;
  }

  // ------ Core Functions End ------

  // ------ Getters ------

  function getUserMarketShares(uint256 marketId, address user) external view returns (uint256, uint256[] memory) {
    Market storage market = markets[marketId];
    uint256[] memory outcomeShares = new uint256[](market.outcomeCount);

    for (uint256 i = 0; i < market.outcomeCount; ++i) {
      outcomeShares[i] = market.outcomes[i].shares.holders[user];
    }

    return (market.liquidityShares[user], outcomeShares);
  }

  function getUserClaimStatus(uint256 marketId, address user)
    external
    view
    returns (
      bool,
      bool,
      bool,
      bool,
      uint256
    )
  {
    Market storage market = markets[marketId];

    // market still not resolved
    if (market.state != MarketState.resolved) {
      return (false, false, false, false, getUserClaimableFees(marketId, user));
    }

    MarketOutcome storage outcome = market.outcomes[market.resolution.outcomeId];

    return (
      outcome.shares.holders[user] > 0,
      outcome.shares.claims[user],
      market.liquidityShares[user] > 0,
      market.liquidityClaims[user],
      getUserClaimableFees(marketId, user)
    );
  }

  function getUserLiquidityPoolShare(uint256 marketId, address user) external view returns (uint256) {
    Market storage market = markets[marketId];

    return (market.liquidityShares[user] * ONE) / market.liquidity;
  }

  function getUserClaimableFees(uint256 marketId, address user) public view returns (uint256) {
    Market storage market = markets[marketId];

    uint256 rawAmount = (market.fees.poolWeight * market.liquidityShares[user]) / market.liquidity;

    // No fees left to claim
    if (market.fees.claimed[user] > rawAmount) return 0;

    return rawAmount - market.fees.claimed[user];
  }

  function getMarkets() external view returns (uint256[] memory) {
    return marketIds;
  }

  function getMarketData(uint256 marketId)
    external
    view
    returns (
      MarketState,
      uint256,
      uint256,
      uint256,
      uint256,
      int256
    )
  {
    Market storage market = markets[marketId];

    return (
      market.state,
      market.closesAtTimestamp,
      market.liquidity,
      market.balance,
      market.sharesAvailable,
      getMarketResolvedOutcome(marketId)
    );
  }

  function getMarketAltData(uint256 marketId)
    external
    view
    returns (
      uint256,
      bytes32,
      uint256,
      IERC20,
      uint256,
      address
    )
  {
    Market storage market = markets[marketId];

    return (
      market.fees.fee,
      market.resolution.questionId,
      uint256(market.resolution.questionId),
      market.token,
      market.fees.treasuryFee,
      market.fees.treasury
    );
  }

  function getMarketQuestion(uint256 marketId) external view returns (bytes32) {
    Market storage market = markets[marketId];

    return (market.resolution.questionId);
  }

  function getMarketPrices(uint256 marketId) external view returns (uint256, uint256[] memory) {
    Market storage market = markets[marketId];
    uint256[] memory prices = new uint256[](market.outcomeCount);

    for (uint256 i = 0; i < market.outcomeCount; ++i) {
      prices[i] = getMarketOutcomePrice(marketId, i);
    }

    return (getMarketLiquidityPrice(marketId), prices);
  }

  function getMarketShares(uint256 marketId) external view returns (uint256, uint256[] memory) {
    Market storage market = markets[marketId];
    uint256[] memory outcomeShares = new uint256[](market.outcomeCount);

    for (uint256 i = 0; i < market.outcomeCount; ++i) {
      outcomeShares[i] = market.outcomes[i].shares.available;
    }

    return (market.liquidity, outcomeShares);
  }

  function getMarketLiquidityPrice(uint256 marketId) public view returns (uint256) {
    Market storage market = markets[marketId];

    if (market.state == MarketState.resolved && !isMarketVoided(marketId)) {
      // resolved market, outcome prices are either 0 or 1
      // final liquidity price = outcome shares / liquidity shares
      return (market.outcomes[market.resolution.outcomeId].shares.available * ONE) / market.liquidity;
    }

    // liquidity price = # outcomes / (liquidity * sum (1 / every outcome shares)
    uint256 marketSharesSum = 0;

    for (uint256 i = 0; i < market.outcomeCount; ++i) {
      MarketOutcome storage outcome = market.outcomes[i];

      marketSharesSum = marketSharesSum + (ONE * ONE) / outcome.shares.available;
    }

    return (market.outcomeCount * ONE * ONE * ONE) / market.liquidity / marketSharesSum;
  }

  function getMarketResolvedOutcome(uint256 marketId) public view returns (int256) {
    Market storage market = markets[marketId];

    // returning -1 if market still not resolved
    if (market.state != MarketState.resolved) {
      return -1;
    }

    return int256(market.resolution.outcomeId);
  }

  function isMarketVoided(uint256 marketId) public view returns (bool) {
    Market storage market = markets[marketId];

    // market still not resolved, still in valid state
    if (market.state != MarketState.resolved) {
      return false;
    }

    // resolved market id does not match any of the market ids
    return market.resolution.outcomeId >= market.outcomeCount;
  }

  function getMarketFee(uint256 marketId) public view returns (uint256) {
    Market storage market = markets[marketId];

    return market.fees.fee + market.fees.treasuryFee;
  }

  // ------ Outcome Getters ------

  function getMarketOutcomeIds(uint256 marketId) external view returns (uint256[] memory) {
    Market storage market = markets[marketId];
    uint256[] memory outcomeIds = new uint256[](market.outcomeCount);

    for (uint256 i = 0; i < market.outcomeCount; ++i) {
      outcomeIds[i] = i;
    }

    return outcomeIds;
  }

  function getMarketOutcomePrice(uint256 marketId, uint256 outcomeId) public view returns (uint256) {
    Market storage market = markets[marketId];

    if (market.state == MarketState.resolved && !isMarketVoided(marketId)) {
      // resolved market, price is either 0 or 1
      return outcomeId == market.resolution.outcomeId ? ONE : 0;
    }

    // outcome price = 1 / (1 + sum(outcome shares / every outcome shares))
    uint256 div = ONE;
    for (uint256 i = 0; i < market.outcomeCount; ++i) {
      if (i == outcomeId) continue;

      div = div + (market.outcomes[outcomeId].shares.available * ONE) / market.outcomes[i].shares.available;
    }

    return (ONE * ONE) / div;
  }

  function getMarketOutcomeData(uint256 marketId, uint256 outcomeId)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    Market storage market = markets[marketId];
    MarketOutcome storage outcome = market.outcomes[outcomeId];

    return (getMarketOutcomePrice(marketId, outcomeId), outcome.shares.available, outcome.shares.total);
  }

  function getMarketOutcomesShares(uint256 marketId) private view returns (uint256[] memory) {
    Market storage market = markets[marketId];

    uint256[] memory shares = new uint256[](market.outcomeCount);
    for (uint256 i = 0; i < market.outcomeCount; ++i) {
      shares[i] = market.outcomes[i].shares.available;
    }

    return shares;
  }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
}