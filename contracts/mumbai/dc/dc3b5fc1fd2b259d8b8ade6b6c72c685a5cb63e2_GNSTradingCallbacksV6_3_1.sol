// SPDX-License-Identifier: MIT
import {Initializable} from "@openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/StorageInterfaceV5.sol";
import "./interfaces/GNSPairInfosInterfaceV6.sol";
// import "./interfaces/GNSReferralsInterfaceV6_2.sol";
// import "./interfaces/GNSStakingInterfaceV6_2.sol";
import "./utils/ChainUtils.sol";

pragma solidity 0.8.17;

contract GNSTradingCallbacksV6_3_1 is Initializable {
    // Contracts (constant)
    StorageInterfaceV5 public storageT;
    NftRewardsInterfaceV6_3_1 public nftRewards;
    GNSPairInfosInterfaceV6 public pairInfos;
    // GNSReferralsInterfaceV6_2 public referrals;
    // GNSStakingInterfaceV6_2 public staking;

    // Params (constant)
    uint256 constant PRECISION = 1e10; // 10 decimals

    uint256 constant MAX_SL_P = 75; // -75% PNL
    uint256 constant MAX_GAIN_P = 900; // 900% PnL (10x)
    uint256 constant MAX_EXECUTE_TIMEOUT = 5; // 5 blocks

    // Params (adjustable)
    uint256 public daiVaultFeeP; // % of closing fee going to DAI vault (eg. 40)
    uint256 public lpFeeP; // % of closing fee going to GNS/DAI LPs (eg. 20)
    uint256 public sssFeeP; // % of closing fee going to GNS staking (eg. 40)

    // State
    bool public isPaused; // Prevent opening new trades
    bool public isDone; // Prevent any interaction with the contract
    uint256 public canExecuteTimeout; // How long an update to TP/SL/Limit has to wait before it is executable

    // Last Updated State
    mapping(
        address
            => mapping(
                uint256
                    => mapping(
                        uint256
                            => mapping(
                                // Market, Limit
                                TradeType => LastUpdated
                            )
                    )
            )
    ) public tradeLastUpdated; // Block numbers for last updated

    // Custom data types
    struct AggregatorAnswer {
        uint256 orderId;
        uint256 price;
        uint256 spreadP;
    }

    // Useful to avoid stack too deep errors
    struct Values {
        uint256 posDai;
        uint256 levPosDai;
        uint256 tokenPriceDai;
        int256 profitP;
        uint256 price;
        uint256 liqPrice;
        uint256 daiSentToTrader;
        uint256 reward1;
        uint256 reward2;
        uint256 reward3;
    }

    struct SimplifiedTradeId {
        address trader;
        uint256 pairIndex;
        uint256 index;
        TradeType tradeType;
    }

    struct LastUpdated {
        uint32 tp;
        uint32 sl;
        uint32 limit;
        uint32 created;
    }

    enum TradeType {
        MARKET,
        LIMIT
    }

    // Events
    event MarketExecuted(
        uint256 indexed orderId,
        StorageInterfaceV5.Trade t,
        bool open,
        uint256 price,
        uint256 priceImpactP,
        uint256 positionSizeDai,
        int256 percentProfit,
        uint256 daiSentToTrader
    );

    event LimitExecuted(
        uint256 indexed orderId,
        uint256 limitIndex,
        StorageInterfaceV5.Trade t,
        address indexed nftHolder,
        StorageInterfaceV5.LimitOrder orderType,
        uint256 price,
        uint256 priceImpactP,
        uint256 positionSizeDai,
        int256 percentProfit,
        uint256 daiSentToTrader
    );

    event MarketOpenCanceled(uint256 indexed orderId, address indexed trader, uint256 indexed pairIndex);
    event MarketCloseCanceled(
        uint256 indexed orderId, address indexed trader, uint256 indexed pairIndex, uint256 index
    );

    event SlUpdated(
        uint256 indexed orderId, address indexed trader, uint256 indexed pairIndex, uint256 index, uint256 newSl
    );
    event SlCanceled(uint256 indexed orderId, address indexed trader, uint256 indexed pairIndex, uint256 index);

    event ClosingFeeSharesPUpdated(uint256 daiVaultFeeP, uint256 lpFeeP, uint256 sssFeeP);
    event CanExecuteTimeoutUpdated(uint256 newValue);

    event Pause(bool paused);
    event Done(bool done);

    event DevGovFeeCharged(address indexed trader, uint256 valueDai);
    event ReferralFeeCharged(address indexed trader, uint256 valueDai);
    event NftBotFeeCharged(address indexed trader, uint256 valueDai);
    event SssFeeCharged(address indexed trader, uint256 valueDai);
    event DaiVaultFeeCharged(address indexed trader, uint256 valueDai);
    event LpFeeCharged(address indexed trader, uint256 valueDai);

    function initialize(
        StorageInterfaceV5 _storageT,
        NftRewardsInterfaceV6_3_1 _nftRewards,
        GNSPairInfosInterfaceV6 _pairInfos,
        // GNSReferralsInterfaceV6_2 _referrals,
        // GNSStakingInterfaceV6_2 _staking,
        address vaultToApprove,
        uint256 _daiVaultFeeP,
        uint256 _lpFeeP,
        uint256 _sssFeeP,
        uint256 _canExecuteTimeout
    ) external initializer {
        require(
            address(_storageT) != address(0) && address(_nftRewards) != address(0) && address(_pairInfos) != address(0)
            /* && address(_referrals) != address(0) && address(_staking) != address(0) **/
            && vaultToApprove != address(0) && _daiVaultFeeP + _lpFeeP + _sssFeeP == 100
                && _canExecuteTimeout <= MAX_EXECUTE_TIMEOUT,
            "WRONG_PARAMS"
        );

        storageT = _storageT;
        nftRewards = _nftRewards;
        pairInfos = _pairInfos;
        // referrals = _referrals;
        // staking = _staking;

        daiVaultFeeP = _daiVaultFeeP;
        lpFeeP = _lpFeeP;
        sssFeeP = _sssFeeP;

        canExecuteTimeout = _canExecuteTimeout;

        TokenInterfaceV5 t = storageT.dai();
        // create infinite allowance to spend from this contract
        // t.approve(address(staking), type(uint256).max);
        t.approve(vaultToApprove, type(uint256).max);
    }

    // Modifiers
    modifier onlyGov() {
        isGov();
        _;
    }

    modifier onlyPriceAggregator() {
        isPriceAggregator();
        _;
    }

    modifier notDone() {
        isNotDone();
        _;
    }

    modifier onlyTrading() {
        isTrading();
        _;
    }

    // Saving code size by calling these functions inside modifiers
    function isGov() private view {
        require(msg.sender == storageT.gov(), "GOV_ONLY");
    }

    function isPriceAggregator() private view {
        require(msg.sender == address(storageT.priceAggregator()), "AGGREGATOR_ONLY");
    }

    function isNotDone() private view {
        require(!isDone, "DONE");
    }

    function isTrading() private view {
        require(msg.sender == storageT.trading(), "TRADING_ONLY");
    }

    // Manage params
    function setClosingFeeSharesP(uint256 _daiVaultFeeP, uint256 _lpFeeP, uint256 _sssFeeP) external onlyGov {
        require(_daiVaultFeeP + _lpFeeP + _sssFeeP == 100, "SUM_NOT_100");

        daiVaultFeeP = _daiVaultFeeP;
        lpFeeP = _lpFeeP;
        sssFeeP = _sssFeeP;

        emit ClosingFeeSharesPUpdated(_daiVaultFeeP, _lpFeeP, _sssFeeP);
    }

    function setCanExecuteTimeout(uint256 _canExecuteTimeout) external onlyGov {
        require(_canExecuteTimeout <= MAX_EXECUTE_TIMEOUT, "GT_MAX");
        canExecuteTimeout = _canExecuteTimeout;
        emit CanExecuteTimeoutUpdated(_canExecuteTimeout);
    }

    // Manage state
    function pause() external onlyGov {
        isPaused = !isPaused;

        emit Pause(isPaused);
    }

    function done() external onlyGov {
        isDone = !isDone;

        emit Done(isDone);
    }

    // Callbacks
    function openTradeMarketCallback(AggregatorAnswer memory a) external onlyPriceAggregator notDone {
        StorageInterfaceV5.PendingMarketOrder memory o = getPendingMarketOrder(a.orderId);

        if (o.block == 0) return;

        StorageInterfaceV5.Trade memory t = o.trade;

        // priceImpactP: PERCENTAGE
        (uint256 priceImpactP, uint256 priceAfterImpact) = pairInfos.getTradePriceImpact(
            marketExecutionPrice(a.price, a.spreadP, o.spreadReductionP, t.buy),
            t.pairIndex,
            t.buy,
            t.positionSizeDai * t.leverage
        );

        t.openPrice = priceAfterImpact;

        uint256 maxSlippage = o.wantedPrice * o.slippageP / 100 / PRECISION;

        if (
            isPaused || a.price == 0
                || (t.buy ? t.openPrice > o.wantedPrice + maxSlippage : t.openPrice < o.wantedPrice - maxSlippage)
                || (t.tp > 0 && (t.buy ? t.openPrice >= t.tp : t.openPrice <= t.tp))
                || (t.sl > 0 && (t.buy ? t.openPrice <= t.sl : t.openPrice >= t.sl))
                || !withinExposureLimits(t.pairIndex, t.buy, t.positionSizeDai, t.leverage)
                || priceImpactP * t.leverage > pairInfos.maxNegativePnlOnOpenP()
        ) {
            uint256 devGovFeesDai = storageT.handleDevGovFees(t.pairIndex, t.positionSizeDai * t.leverage, true, true);

            transferFromStorageToAddress(t.trader, t.positionSizeDai - devGovFeesDai);

            emit DevGovFeeCharged(t.trader, devGovFeesDai);

            emit MarketOpenCanceled(a.orderId, t.trader, t.pairIndex);
        } else {
            (StorageInterfaceV5.Trade memory finalTrade, uint256 tokenPriceDai) = registerTrade(t, 1500, 0);

            emit MarketExecuted(
                a.orderId,
                finalTrade,
                true,
                finalTrade.openPrice,
                priceImpactP,
                finalTrade.initialPosToken * tokenPriceDai / PRECISION,
                0,
                0
            );
        }

        storageT.unregisterPendingMarketOrder(a.orderId, true);
    }

    function closeTradeMarketCallback(AggregatorAnswer memory a) external onlyPriceAggregator notDone {
        StorageInterfaceV5.PendingMarketOrder memory o = getPendingMarketOrder(a.orderId);

        if (o.block == 0) return;

        StorageInterfaceV5.Trade memory t = getOpenTrade(o.trade.trader, o.trade.pairIndex, o.trade.index);

        if (t.leverage > 0) {
            StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(t.trader, t.pairIndex, t.index);

            AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();
            PairsStorageInterfaceV6 pairsStorage = aggregator.pairsStorage();

            Values memory v;

            v.levPosDai = t.initialPosToken * i.tokenPriceDai * t.leverage / PRECISION;
            v.tokenPriceDai = aggregator.tokenPriceDai();

            if (a.price == 0) {
                // Dev / gov rewards to pay for oracle cost
                // Charge in DAI if collateral in storage or token if collateral in vault
                v.reward1 = t.positionSizeDai > 0
                    ? storageT.handleDevGovFees(t.pairIndex, v.levPosDai, true, true)
                    : storageT.handleDevGovFees(t.pairIndex, v.levPosDai * PRECISION / v.tokenPriceDai, false, true)
                        * v.tokenPriceDai / PRECISION;

                t.initialPosToken -= v.reward1 * PRECISION / i.tokenPriceDai;
                storageT.updateTrade(t);

                emit DevGovFeeCharged(t.trader, v.reward1);

                emit MarketCloseCanceled(a.orderId, t.trader, t.pairIndex, t.index);
            } else {
                v.profitP = currentPercentProfit(t.openPrice, a.price, t.buy, t.leverage);
                v.posDai = v.levPosDai / t.leverage;

                v.daiSentToTrader = unregisterTrade(
                    t,
                    true,
                    v.profitP,
                    v.posDai,
                    i.openInterestDai / t.leverage,
                    v.levPosDai * pairsStorage.pairCloseFeeP(t.pairIndex) / 100 / PRECISION,
                    v.levPosDai * pairsStorage.pairNftLimitOrderFeeP(t.pairIndex) / 100 / PRECISION,
                    v.tokenPriceDai
                );

                emit MarketExecuted(a.orderId, t, false, a.price, 0, v.posDai, v.profitP, v.daiSentToTrader);
            }
        }

        storageT.unregisterPendingMarketOrder(a.orderId, false);
    }

    function executeNftOpenOrderCallback(AggregatorAnswer memory a) external onlyPriceAggregator notDone {
        StorageInterfaceV5.PendingNftOrder memory n = storageT.reqID_pendingNftOrder(a.orderId);

        if (!isPaused && a.price > 0 && storageT.hasOpenLimitOrder(n.trader, n.pairIndex, n.index)) {
            StorageInterfaceV5.OpenLimitOrder memory o = storageT.getOpenLimitOrder(n.trader, n.pairIndex, n.index);

            NftRewardsInterfaceV6_3_1.OpenLimitOrderType t =
                nftRewards.openLimitOrderTypes(n.trader, n.pairIndex, n.index);

            (uint256 priceImpactP, uint256 priceAfterImpact) = pairInfos.getTradePriceImpact(
                marketExecutionPrice(a.price, a.spreadP, o.spreadReductionP, o.buy),
                o.pairIndex,
                o.buy,
                o.positionSize * o.leverage
            );

            a.price = priceAfterImpact;

            if (
                (
                    t == NftRewardsInterfaceV6_3_1.OpenLimitOrderType.LEGACY
                        ? (a.price >= o.minPrice && a.price <= o.maxPrice)
                        : (
                            t == NftRewardsInterfaceV6_3_1.OpenLimitOrderType.REVERSAL
                                ? (o.buy ? a.price <= o.maxPrice : a.price >= o.minPrice)
                                : (o.buy ? a.price >= o.minPrice : a.price <= o.maxPrice)
                        )
                ) && withinExposureLimits(o.pairIndex, o.buy, o.positionSize, o.leverage)
                    && priceImpactP * o.leverage <= pairInfos.maxNegativePnlOnOpenP()
            ) {
                (StorageInterfaceV5.Trade memory finalTrade, uint256 tokenPriceDai) = registerTrade(
                    StorageInterfaceV5.Trade(
                        o.trader,
                        o.pairIndex,
                        0,
                        0,
                        o.positionSize,
                        t == NftRewardsInterfaceV6_3_1.OpenLimitOrderType.REVERSAL
                            ? o.maxPrice // o.minPrice = o.maxPrice in that case
                            : a.price,
                        o.buy,
                        o.leverage,
                        o.tp,
                        o.sl
                    ),
                    n.nftId,
                    n.index
                );

                storageT.unregisterOpenLimitOrder(o.trader, o.pairIndex, o.index);

                emit LimitExecuted(
                    a.orderId,
                    n.index,
                    finalTrade,
                    n.nftHolder,
                    StorageInterfaceV5.LimitOrder.OPEN,
                    finalTrade.openPrice,
                    priceImpactP,
                    finalTrade.initialPosToken * tokenPriceDai / PRECISION,
                    0,
                    0
                );
            }
        }

        nftRewards.unregisterTrigger(
            NftRewardsInterfaceV6_3_1.TriggeredLimitId(n.trader, n.pairIndex, n.index, n.orderType)
        );

        storageT.unregisterPendingNftOrder(a.orderId);
    }

    function executeNftCloseOrderCallback(AggregatorAnswer memory a) external onlyPriceAggregator notDone {
        StorageInterfaceV5.PendingNftOrder memory o = storageT.reqID_pendingNftOrder(a.orderId);
        NftRewardsInterfaceV6_3_1.TriggeredLimitId memory triggeredLimitId =
            NftRewardsInterfaceV6_3_1.TriggeredLimitId(o.trader, o.pairIndex, o.index, o.orderType);
        StorageInterfaceV5.Trade memory t = getOpenTrade(o.trader, o.pairIndex, o.index);

        AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();

        if (a.price > 0 && t.leverage > 0) {
            StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(t.trader, t.pairIndex, t.index);

            PairsStorageInterfaceV6 pairsStored = aggregator.pairsStorage();

            Values memory v;

            v.price = pairsStored.guaranteedSlEnabled(t.pairIndex)
                ? o.orderType == StorageInterfaceV5.LimitOrder.TP
                    ? t.tp
                    : o.orderType == StorageInterfaceV5.LimitOrder.SL ? t.sl : a.price
                : a.price;

            v.profitP = currentPercentProfit(t.openPrice, v.price, t.buy, t.leverage);
            v.levPosDai = t.initialPosToken * i.tokenPriceDai * t.leverage / PRECISION;
            v.posDai = v.levPosDai / t.leverage;

            if (o.orderType == StorageInterfaceV5.LimitOrder.LIQ) {
                v.liqPrice = pairInfos.getTradeLiquidationPrice(
                    t.trader, t.pairIndex, t.index, t.openPrice, t.buy, v.posDai, t.leverage
                );

                // NFT reward in DAI
                v.reward1 = (t.buy ? a.price <= v.liqPrice : a.price >= v.liqPrice) ? v.posDai * 5 / 100 : 0;
            } else {
                // NFT reward in DAI
                v.reward1 = (
                    o.orderType == StorageInterfaceV5.LimitOrder.TP && t.tp > 0
                        && (t.buy ? a.price >= t.tp : a.price <= t.tp)
                        || o.orderType == StorageInterfaceV5.LimitOrder.SL && t.sl > 0
                            && (t.buy ? a.price <= t.sl : a.price >= t.sl)
                ) ? v.levPosDai * pairsStored.pairNftLimitOrderFeeP(t.pairIndex) / 100 / PRECISION : 0;
            }

            // If can be triggered
            if (v.reward1 > 0) {
                v.tokenPriceDai = aggregator.tokenPriceDai();

                v.daiSentToTrader = unregisterTrade(
                    t,
                    false,
                    v.profitP,
                    v.posDai,
                    i.openInterestDai / t.leverage,
                    o.orderType == StorageInterfaceV5.LimitOrder.LIQ
                        ? v.reward1
                        : v.levPosDai * pairsStored.pairCloseFeeP(t.pairIndex) / 100 / PRECISION,
                    v.reward1,
                    v.tokenPriceDai
                );

                // Convert NFT bot fee from DAI to token value
                v.reward2 = v.reward1 * PRECISION / v.tokenPriceDai;

                nftRewards.distributeNftReward(triggeredLimitId, v.reward2, v.tokenPriceDai);

                storageT.increaseNftRewards(o.nftId, v.reward2);

                emit NftBotFeeCharged(t.trader, v.reward1);

                emit LimitExecuted(
                    a.orderId, o.index, t, o.nftHolder, o.orderType, v.price, 0, v.posDai, v.profitP, v.daiSentToTrader
                );
            }
        }

        nftRewards.unregisterTrigger(triggeredLimitId);

        storageT.unregisterPendingNftOrder(a.orderId);
    }

    function updateSlCallback(AggregatorAnswer memory a) external onlyPriceAggregator notDone {
        AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();
        AggregatorInterfaceV6_2.PendingSl memory o = aggregator.pendingSlOrders(a.orderId);

        StorageInterfaceV5.Trade memory t = getOpenTrade(o.trader, o.pairIndex, o.index);

        if (t.leverage > 0) {
            StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(o.trader, o.pairIndex, o.index);

            Values memory v;

            v.tokenPriceDai = aggregator.tokenPriceDai();
            v.levPosDai = t.initialPosToken * i.tokenPriceDai * t.leverage / PRECISION / 2;

            // Charge in DAI if collateral in storage or token if collateral in vault
            v.reward1 = t.positionSizeDai > 0
                ? storageT.handleDevGovFees(t.pairIndex, v.levPosDai, true, false)
                : storageT.handleDevGovFees(t.pairIndex, v.levPosDai * PRECISION / v.tokenPriceDai, false, false)
                    * v.tokenPriceDai / PRECISION;

            t.initialPosToken -= v.reward1 * PRECISION / i.tokenPriceDai;
            storageT.updateTrade(t);

            emit DevGovFeeCharged(t.trader, v.reward1);

            if (
                a.price > 0 && t.buy == o.buy && t.openPrice == o.openPrice
                    && (t.buy ? o.newSl <= a.price : o.newSl >= a.price)
            ) {
                storageT.updateSl(o.trader, o.pairIndex, o.index, o.newSl);
                LastUpdated storage l = tradeLastUpdated[o.trader][o.pairIndex][o.index][TradeType.MARKET];
                l.sl = uint32(ChainUtils.getBlockNumber());

                emit SlUpdated(a.orderId, o.trader, o.pairIndex, o.index, o.newSl);
            } else {
                emit SlCanceled(a.orderId, o.trader, o.pairIndex, o.index);
            }
        }

        aggregator.unregisterPendingSlOrder(a.orderId);
    }

    // Shared code between market & limit callbacks
    function registerTrade(StorageInterfaceV5.Trade memory trade, uint256 nftId, uint256 limitIndex)
        private
        returns (StorageInterfaceV5.Trade memory, uint256)
    {
        AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();
        PairsStorageInterfaceV6 pairsStored = aggregator.pairsStorage();

        Values memory v;

        v.levPosDai = trade.positionSizeDai * trade.leverage;
        v.tokenPriceDai = aggregator.tokenPriceDai();

        /**
         * // 1. Charge referral fee (if applicable) and send DAI amount to vault
         *
         *      if (referrals.getTraderReferrer(trade.trader) != address(0)) {
         *          // Use this variable to store lev pos dai for dev/gov fees after referral fees
         *          // and before volumeReferredDai increases
         *          v.posDai = v.levPosDai * (100 * PRECISION - referrals.getPercentOfOpenFeeP(trade.trader)) / 100 / PRECISION;
         *
         *          v.reward1 = referrals.distributePotentialReward(
         *              trade.trader, v.levPosDai, pairsStored.pairOpenFeeP(trade.pairIndex), v.tokenPriceDai
         *          );
         *
         *          sendToVault(v.reward1, trade.trader);
         *          trade.positionSizeDai -= v.reward1;
         *
         *          emit ReferralFeeCharged(trade.trader, v.reward1);
         *      }
         */

        // 2. Charge opening fee - referral fee (if applicable)
        v.reward2 = storageT.handleDevGovFees(trade.pairIndex, (v.posDai > 0 ? v.posDai : v.levPosDai), true, true);

        trade.positionSizeDai -= v.reward2;

        emit DevGovFeeCharged(trade.trader, v.reward2);

        // 3. Charge NFT / SSS fee
        v.reward2 = v.levPosDai * pairsStored.pairNftLimitOrderFeeP(trade.pairIndex) / 100 / PRECISION;
        trade.positionSizeDai -= v.reward2;

        // 3.1 Distribute NFT fee and send DAI amount to vault (if applicable)
        if (nftId < 1500) {
            sendToVault(v.reward2, trade.trader);

            // Convert NFT bot fee from DAI to token value
            v.reward3 = v.reward2 * PRECISION / v.tokenPriceDai;

            nftRewards.distributeNftReward(
                NftRewardsInterfaceV6_3_1.TriggeredLimitId(
                    trade.trader, trade.pairIndex, limitIndex, StorageInterfaceV5.LimitOrder.OPEN
                ),
                v.reward3,
                v.tokenPriceDai
            );
            storageT.increaseNftRewards(nftId, v.reward3);

            emit NftBotFeeCharged(trade.trader, v.reward2);

            // 3.2 Distribute SSS fee (if applicable)
        } /* else {
            distributeStakingReward(trade.trader, v.reward2);
        } **/

        // 4. Set trade final details
        trade.index = storageT.firstEmptyTradeIndex(trade.trader, trade.pairIndex);
        trade.initialPosToken = trade.positionSizeDai * PRECISION / v.tokenPriceDai;

        trade.tp = correctTp(trade.openPrice, trade.leverage, trade.tp, trade.buy);
        trade.sl = correctSl(trade.openPrice, trade.leverage, trade.sl, trade.buy);

        // 5. Call other contracts
        pairInfos.storeTradeInitialAccFees(trade.trader, trade.pairIndex, trade.index, trade.buy);
        pairsStored.updateGroupCollateral(trade.pairIndex, trade.positionSizeDai, trade.buy, true);

        // 6. Store final trade in storage contract
        storageT.storeTrade(
            trade, StorageInterfaceV5.TradeInfo(0, v.tokenPriceDai, trade.positionSizeDai * trade.leverage, 0, 0, false)
        );

        // 7. Store tradeLastUpdated
        LastUpdated storage lastUpdated = tradeLastUpdated[trade.trader][trade.pairIndex][trade.index][TradeType.MARKET];
        uint32 currBlock = uint32(ChainUtils.getBlockNumber());
        lastUpdated.tp = currBlock;
        lastUpdated.sl = currBlock;
        lastUpdated.created = currBlock;

        return (trade, v.tokenPriceDai);
    }

    function unregisterTrade(
        StorageInterfaceV5.Trade memory trade,
        bool marketOrder,
        int256 percentProfit, // PRECISION
        uint256 currentDaiPos, // 1e18
        uint256 initialDaiPos, // 1e18
        uint256 closingFeeDai, // 1e18
        uint256 nftFeeDai, // 1e18 (= SSS reward if market order)
        uint256 tokenPriceDai // PRECISION
    ) private returns (uint256 daiSentToTrader) {
        // 1. Calculate net PnL (after all closing fees)
        daiSentToTrader = pairInfos.getTradeValue(
            trade.trader,
            trade.pairIndex,
            trade.index,
            trade.buy,
            currentDaiPos,
            trade.leverage,
            percentProfit,
            closingFeeDai + nftFeeDai
        );

        Values memory v;
        IGToken vault = storageT.vault();

        // 2. LP reward
        if (lpFeeP > 0) {
            v.reward1 = closingFeeDai * lpFeeP / 100;
            storageT.distributeLpRewards(v.reward1 * PRECISION / tokenPriceDai);

            emit LpFeeCharged(trade.trader, v.reward1);
        }

        // 3.1 If collateral in storage (opened after update)
        if (trade.positionSizeDai > 0) {
            // 3.1.1 DAI vault reward
            v.reward2 = closingFeeDai * daiVaultFeeP / 100;
            transferFromStorageToAddress(address(this), v.reward2);
            vault.distributeReward(v.reward2);

            emit DaiVaultFeeCharged(trade.trader, v.reward2);

            // 3.1.2 SSS reward
            v.reward3 = marketOrder ? nftFeeDai + closingFeeDai * sssFeeP / 100 : closingFeeDai * sssFeeP / 100;

            // distributeStakingReward(trade.trader, v.reward3);

            // 3.1.3 Take DAI from vault if winning trade
            // or send DAI to vault if losing trade
            uint256 daiLeftInStorage = currentDaiPos - v.reward3 - v.reward2;

            if (daiSentToTrader > daiLeftInStorage) {
                vault.sendAssets(daiSentToTrader - daiLeftInStorage, trade.trader);
                transferFromStorageToAddress(trade.trader, daiLeftInStorage);
            } else {
                sendToVault(daiLeftInStorage - daiSentToTrader, trade.trader);
                transferFromStorageToAddress(trade.trader, daiSentToTrader);
            }

            // 3.2 If collateral in vault (opened before update)
        } else {
            vault.sendAssets(daiSentToTrader, trade.trader);
        }

        // 4. Calls to other contracts
        getPairsStorage().updateGroupCollateral(trade.pairIndex, initialDaiPos, trade.buy, false);

        // 5. Unregister trade from storage
        storageT.unregisterTrade(trade.trader, trade.pairIndex, trade.index);
    }

    // Utils (external)
    function setTradeLastUpdated(SimplifiedTradeId calldata _id, LastUpdated memory _lastUpdated)
        external
        onlyTrading
    {
        tradeLastUpdated[_id.trader][_id.pairIndex][_id.index][_id.tradeType] = _lastUpdated;
    }

    // Utils (getters)
    function withinExposureLimits(uint256 pairIndex, bool buy, uint256 positionSizeDai, uint256 leverage)
        private
        view
        returns (bool)
    {
        PairsStorageInterfaceV6 pairsStored = getPairsStorage();

        return storageT.openInterestDai(pairIndex, buy ? 0 : 1) + positionSizeDai * leverage
            <= storageT.openInterestDai(pairIndex, 2)
            && pairsStored.groupCollateral(pairIndex, buy) + positionSizeDai <= pairsStored.groupMaxCollateral(pairIndex);
    }

    function currentPercentProfit(uint256 openPrice, uint256 currentPrice, bool buy, uint256 leverage)
        private
        pure
        returns (int256 p)
    {
        int256 maxPnlP = int256(MAX_GAIN_P) * int256(PRECISION);

        p = (buy ? int256(currentPrice) - int256(openPrice) : int256(openPrice) - int256(currentPrice)) * 100
            * int256(PRECISION) * int256(leverage) / int256(openPrice);

        p = p > maxPnlP ? maxPnlP : p;
    }

    function correctTp(uint256 openPrice, uint256 leverage, uint256 tp, bool buy) private pure returns (uint256) {
        if (tp == 0 || currentPercentProfit(openPrice, tp, buy, leverage) == int256(MAX_GAIN_P) * int256(PRECISION)) {
            uint256 tpDiff = openPrice * MAX_GAIN_P / leverage / 100;

            return buy ? openPrice + tpDiff : (tpDiff <= openPrice ? openPrice - tpDiff : 0);
        }

        return tp;
    }

    function correctSl(uint256 openPrice, uint256 leverage, uint256 sl, bool buy) private pure returns (uint256) {
        if (sl > 0 && currentPercentProfit(openPrice, sl, buy, leverage) < int256(MAX_SL_P) * int256(PRECISION) * -1) {
            uint256 slDiff = openPrice * MAX_SL_P / leverage / 100;

            return buy ? openPrice - slDiff : openPrice + slDiff;
        }

        return sl;
    }

    function marketExecutionPrice(uint256 price, uint256 spreadP, uint256 spreadReductionP, bool long)
        private
        pure
        returns (uint256)
    {
        uint256 priceDiff = price * (spreadP - spreadP * spreadReductionP / 100) / 100 / PRECISION;

        return long ? price + priceDiff : price - priceDiff;
    }

    function getPendingMarketOrder(uint256 orderId)
        private
        view
        returns (StorageInterfaceV5.PendingMarketOrder memory)
    {
        return storageT.reqID_pendingMarketOrder(orderId);
    }

    function getPairsStorage() private view returns (PairsStorageInterfaceV6) {
        return storageT.priceAggregator().pairsStorage();
    }

    function getOpenTrade(address trader, uint256 pairIndex, uint256 index)
        private
        view
        returns (StorageInterfaceV5.Trade memory)
    {
        return storageT.openTrades(trader, pairIndex, index);
    }

    // Utils (private)
    // function distributeStakingReward(address trader, uint256 amountDai) private {
    //     transferFromStorageToAddress(address(this), amountDai);
    //     staking.distributeRewardDai(amountDai);
    //     emit SssFeeCharged(trader, amountDai);
    // }

    function sendToVault(uint256 amountDai, address trader) private {
        transferFromStorageToAddress(address(this), amountDai);
        storageT.vault().receiveAssets(amountDai, trader);
    }

    function transferFromStorageToAddress(address to, uint256 amountDai) private {
        storageT.transferDai(address(storageT), to, amountDai);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
import "./TokenInterfaceV5.sol";
import "./NftInterfaceV5.sol";
import "./IGToken.sol";
import "./PairsStorageInterfaceV6.sol";
import "./ChainlinkFeedInterfaceV5.sol";

pragma solidity ^0.8.11;

interface PoolInterfaceV5 {
    function increaseAccTokensPerLp(uint256) external;
}

interface PausableInterfaceV5 {
    function isPaused() external view returns (bool);
}

interface StorageInterfaceV5 {
    enum LimitOrder {
        TP,
        SL,
        LIQ,
        OPEN
    }

    struct Trade {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 initialPosToken; // 1e18
        uint256 positionSizeDai; // 1e18
        uint256 openPrice; // PRECISION
        bool buy;
        uint256 leverage;
        uint256 tp; // PRECISION
        uint256 sl; // PRECISION
    }

    struct TradeInfo {
        uint256 tokenId;
        uint256 tokenPriceDai; // PRECISION
        uint256 openInterestDai; // 1e18
        uint256 tpLastUpdated;
        uint256 slLastUpdated;
        bool beingMarketClosed;
    }

    struct OpenLimitOrder {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 positionSize; // 1e18 (DAI or GFARM2)
        uint256 spreadReductionP;
        bool buy;
        uint256 leverage;
        uint256 tp; // PRECISION (%)
        uint256 sl; // PRECISION (%)
        uint256 minPrice; // PRECISION
        uint256 maxPrice; // PRECISION
        uint256 block;
        uint256 tokenId; // index in supportedTokens
    }

    struct PendingMarketOrder {
        Trade trade;
        uint256 block;
        uint256 wantedPrice; // PRECISION
        uint256 slippageP; // PRECISION (%)
        uint256 spreadReductionP;
        uint256 tokenId; // index in supportedTokens
    }

    struct PendingNftOrder {
        address nftHolder;
        uint256 nftId;
        address trader;
        uint256 pairIndex;
        uint256 index;
        LimitOrder orderType;
    }

    function PRECISION() external pure returns (uint256);
    function gov() external view returns (address);
    function dev() external view returns (address);
    function dai() external view returns (TokenInterfaceV5);
    function token() external view returns (TokenInterfaceV5);
    function linkErc677() external view returns (TokenInterfaceV5);
    function priceAggregator() external view returns (AggregatorInterfaceV6_2);
    function vault() external view returns (IGToken);
    function trading() external view returns (address);
    function callbacks() external view returns (address);
    function handleTokens(address, uint256, bool) external;
    function transferDai(address, address, uint256) external;
    function transferLinkToAggregator(address, uint256, uint256) external;
    function unregisterTrade(address, uint256, uint256) external;
    function unregisterPendingMarketOrder(uint256, bool) external;
    function unregisterOpenLimitOrder(address, uint256, uint256) external;
    function hasOpenLimitOrder(address, uint256, uint256) external view returns (bool);
    function storePendingMarketOrder(PendingMarketOrder memory, uint256, bool) external;
    function openTrades(address, uint256, uint256) external view returns (Trade memory);
    function openTradesInfo(address, uint256, uint256) external view returns (TradeInfo memory);
    function updateSl(address, uint256, uint256, uint256) external;
    function updateTp(address, uint256, uint256, uint256) external;
    function getOpenLimitOrder(address, uint256, uint256) external view returns (OpenLimitOrder memory);
    function spreadReductionsP(uint256) external view returns (uint256);
    function storeOpenLimitOrder(OpenLimitOrder memory) external;
    function reqID_pendingMarketOrder(uint256) external view returns (PendingMarketOrder memory);
    function storePendingNftOrder(PendingNftOrder memory, uint256) external;
    function updateOpenLimitOrder(OpenLimitOrder calldata) external;
    function firstEmptyTradeIndex(address, uint256) external view returns (uint256);
    function firstEmptyOpenLimitIndex(address, uint256) external view returns (uint256);
    function increaseNftRewards(uint256, uint256) external;
    function nftSuccessTimelock() external view returns (uint256);
    function reqID_pendingNftOrder(uint256) external view returns (PendingNftOrder memory);
    function updateTrade(Trade memory) external;
    function nftLastSuccess(uint256) external view returns (uint256);
    function unregisterPendingNftOrder(uint256) external;
    function handleDevGovFees(uint256, uint256, bool, bool) external returns (uint256);
    function distributeLpRewards(uint256) external;
    function storeTrade(Trade memory, TradeInfo memory) external;
    function openLimitOrdersCount(address, uint256) external view returns (uint256);
    function openTradesCount(address, uint256) external view returns (uint256);
    function pendingMarketOpenCount(address, uint256) external view returns (uint256);
    function pendingMarketCloseCount(address, uint256) external view returns (uint256);
    function maxTradesPerPair() external view returns (uint256);
    function pendingOrderIdsCount(address) external view returns (uint256);
    function maxPendingMarketOrders() external view returns (uint256);
    function openInterestDai(uint256, uint256) external view returns (uint256);
    function getPendingOrderIds(address) external view returns (uint256[] memory);
    function nfts(uint256) external view returns (NftInterfaceV5);
    function fakeBlockNumber() external view returns (uint256); // Testing
}

interface IStateCopyUtils {
    function getOpenLimitOrders() external view returns (StorageInterfaceV5.OpenLimitOrder[] memory);
    function nftRewards() external view returns (NftRewardsInterfaceV6_3_1);
}

interface AggregatorInterfaceV6_2 {
    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE,
        UPDATE_SL
    }

    function pairsStorage() external view returns (PairsStorageInterfaceV6);
    function getPrice(uint256, OrderType, uint256) external returns (uint256);
    function tokenPriceDai() external returns (uint256);
    function linkFee(uint256, uint256) external view returns (uint256);
    function openFeeP(uint256) external view returns (uint256);
    function pendingSlOrders(uint256) external view returns (PendingSl memory);
    function storePendingSlOrder(uint256 orderId, PendingSl calldata p) external;
    function unregisterPendingSlOrder(uint256 orderId) external;

    struct PendingSl {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 openPrice;
        bool buy;
        uint256 newSl;
    }
}

interface AggregatorInterfaceV6_3_1 is AggregatorInterfaceV6_2 {
    function linkPriceFeed() external view returns (ChainlinkFeedInterfaceV5);
}

interface NftRewardsInterfaceV6_3_1 {
    struct TriggeredLimitId {
        address trader;
        uint256 pairIndex;
        uint256 index;
        StorageInterfaceV5.LimitOrder order;
    }

    enum OpenLimitOrderType {
        LEGACY,
        REVERSAL,
        MOMENTUM
    }

    function storeFirstToTrigger(TriggeredLimitId calldata, address, uint256) external;
    function storeTriggerSameBlock(TriggeredLimitId calldata, address) external;
    function unregisterTrigger(TriggeredLimitId calldata) external;
    function distributeNftReward(TriggeredLimitId calldata, uint256, uint256) external;
    function openLimitOrderTypes(address, uint256, uint256) external view returns (OpenLimitOrderType);
    function setOpenLimitOrderType(address, uint256, uint256, OpenLimitOrderType) external;
    function triggered(TriggeredLimitId calldata) external view returns (bool);
    function timedOut(TriggeredLimitId calldata) external view returns (bool);
    function botInUse(bytes32) external view returns (bool);
    function getNftBotHashes(uint256, address, uint256, address, uint256, uint256)
        external
        pure
        returns (bytes32, bytes32);
    function setNftBotInUse(bytes32, bytes32) external;
    function nftBotInUse(bytes32, bytes32) external view returns (bool);
    function linkToTokenRewards(uint256, uint256) external view returns (uint256);
}

interface TradingCallbacksV6_3_1 {
    enum TradeType {
        MARKET,
        LIMIT
    }

    struct SimplifiedTradeId {
        address trader;
        uint256 pairIndex;
        uint256 index;
        TradeType tradeType;
    }

    struct LastUpdated {
        uint32 tp;
        uint32 sl;
        uint32 limit;
        uint32 created;
    }

    function tradeLastUpdated(address, uint256, uint256, TradeType) external view returns (LastUpdated memory);
    function setTradeLastUpdated(SimplifiedTradeId calldata, LastUpdated memory) external;
    function canExecuteTimeout() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface GNSPairInfosInterfaceV6 {
    function maxNegativePnlOnOpenP() external view returns (uint256); // PRECISION (%)

    function storeTradeInitialAccFees(address trader, uint256 pairIndex, uint256 index, bool long) external;

    function getTradePriceImpact(
        uint256 openPrice, // PRECISION
        uint256 pairIndex,
        bool long,
        uint256 openInterest // 1e18 (DAI)
    )
        external
        view
        returns (
            uint256 priceImpactP, // PRECISION (%)
            uint256 priceAfterImpact
        ); // PRECISION

    function getTradeLiquidationPrice(
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 openPrice, // PRECISION
        bool long,
        uint256 collateral, // 1e18 (DAI)
        uint256 leverage
    ) external view returns (uint256); // PRECISION

    function getTradeValue(
        address trader,
        uint256 pairIndex,
        uint256 index,
        bool long,
        uint256 collateral, // 1e18 (DAI)
        uint256 leverage,
        int256 percentProfit, // PRECISION (%)
        uint256 closingFee // 1e18 (DAI)
    ) external returns (uint256); // 1e18 (DAI)
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IArbSys.sol";

library ChainUtils {
    uint256 public constant ARBITRUM_MAINNET = 42161;
    uint256 public constant ARBITRUM_GOERLI = 421613;
    IArbSys public constant ARB_SYS = IArbSys(address(100));

    function getBlockNumber() internal view returns (uint256) {
        if (block.chainid == ARBITRUM_MAINNET || block.chainid == ARBITRUM_GOERLI) {
            return ARB_SYS.arbBlockNumber();
        }

        return block.number;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
pragma solidity ^0.8.7;

interface TokenInterfaceV5 {
    function burn(address, uint256) external;
    function mint(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function hasRole(bytes32, address) external view returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function getFreeDAI() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface NftInterfaceV5 {
    function balanceOf(address) external view returns (uint256);
    function ownerOf(uint256) external view returns (address);
    function transferFrom(address, address, uint256) external;
    function tokenOfOwnerByIndex(address, uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IGToken {
    function manager() external view returns (address);
    function admin() external view returns (address);
    function currentEpoch() external view returns (uint256);
    function currentEpochStart() external view returns (uint256);
    function currentEpochPositiveOpenPnl() external view returns (uint256);
    function updateAccPnlPerTokenUsed(uint256 prevPositiveOpenPnl, uint256 newPositiveOpenPnl)
        external
        returns (uint256);

    struct LockedDeposit {
        address owner;
        uint256 shares; // 1e18
        uint256 assetsDeposited; // 1e18
        uint256 assetsDiscount; // 1e18
        uint256 atTimestamp; // timestamp
        uint256 lockDuration; // timestamp
    }

    function getLockedDeposit(uint256 depositId) external view returns (LockedDeposit memory);

    function sendAssets(uint256 assets, address receiver) external;
    function receiveAssets(uint256 assets, address user) external;
    function distributeReward(uint256 assets) external;

    function currentBalanceDai() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface PairsStorageInterfaceV6 {
    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE
    } // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)

    struct Feed {
        address feed1;
        address feed2;
        FeedCalculation feedCalculation;
        uint256 maxDeviationP;
    } // PRECISION (%)

    function incrementCurrentOrderId() external returns (uint256);
    function updateGroupCollateral(uint256, uint256, bool, bool) external;
    function pairJob(uint256) external returns (string memory, string memory, bytes32, uint256);
    function pairFeed(uint256) external view returns (Feed memory);
    function pairSpreadP(uint256) external view returns (uint256);
    function pairMinLeverage(uint256) external view returns (uint256);
    function pairMaxLeverage(uint256) external view returns (uint256);
    function groupMaxCollateral(uint256) external view returns (uint256);
    function groupCollateral(uint256, bool) external view returns (uint256);
    function guaranteedSlEnabled(uint256) external view returns (bool);
    function pairOpenFeeP(uint256) external view returns (uint256);
    function pairCloseFeeP(uint256) external view returns (uint256);
    function pairOracleFeeP(uint256) external view returns (uint256);
    function pairNftLimitOrderFeeP(uint256) external view returns (uint256);
    function pairReferralFeeP(uint256) external view returns (uint256);
    function pairMinLevPosDai(uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ChainlinkFeedInterfaceV5 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.9.0;

/**
 * @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface IArbSys {
    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external pure returns (uint256);

    function arbChainID() external view returns (uint256);

    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty calldataForL1.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination) external payable returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @param destination recipient address on L1
     * @param calldataForL1 (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata calldataForL1) external payable returns (uint256);

    /**
     * @notice get the number of transactions issued by the given external account or the account sequence number of the given contract
     * @param account target account
     * @return the number of transactions issued by the given external account or the account sequence number of the given contract
     */
    function getTransactionCount(address account) external view returns (uint256);

    /**
     * @notice get the value of target L2 storage slot
     * This function is only callable from address 0 to prevent contracts from being able to call it
     * @param account target account
     * @param index target index of storage slot
     * @return stotage value for the given account at the given index
     */
    function getStorageAt(address account, uint256 index) external view returns (uint256);

    /**
     * @notice check if current call is coming from l1
     * @return true if the caller of this was called directly from L1
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param dest destination address
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address dest) external pure returns (address);

    /**
     * @notice get the caller's amount of available storage gas
     * @return amount of storage gas available to the caller
     */
    function getStorageGasAvailable() external view returns (uint256);

    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );
}