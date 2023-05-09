// SPDX-License-Identifier: MIT
import "./interfaces/StorageInterfaceV5.sol";
import "./interfaces/GNSPairInfosInterfaceV6.sol";
// import "./interfaces/GNSReferralsInterfaceV6_2.sol";
import "./utils/Delegatable.sol";
import "./utils/ChainUtils.sol";
import "./utils/TradeUtils.sol";

pragma solidity 0.8.17;

contract GNSTradingV6_3_1 is Delegatable {
    using TradeUtils for address;

    // Contracts (constant)
    StorageInterfaceV5 public immutable storageT;
    NftRewardsInterfaceV6_3_1 public immutable nftRewards;
    GNSPairInfosInterfaceV6 public immutable pairInfos;
    // GNSReferralsInterfaceV6_2 public immutable referrals;

    // Params (constant)
    uint256 constant PRECISION = 1e10;
    uint256 constant MAX_SL_P = 75; // -75% PNL

    // Params (adjustable)
    uint256 public maxPosDai; // 1e18 (eg. 75000 * 1e18)
    uint256 public marketOrdersTimeout; // block (eg. 30)

    // State
    bool public isPaused; // Prevent opening new trades
    bool public isDone; // Prevent any interaction with the contract

    // Events
    event Done(bool done);
    event Paused(bool paused);

    event NumberUpdated(string name, uint256 value);

    event MarketOrderInitiated(uint256 indexed orderId, address indexed trader, uint256 indexed pairIndex, bool open);

    event OpenLimitPlaced(address indexed trader, uint256 indexed pairIndex, uint256 index);
    event OpenLimitUpdated(
        address indexed trader, uint256 indexed pairIndex, uint256 index, uint256 newPrice, uint256 newTp, uint256 newSl
    );
    event OpenLimitCanceled(address indexed trader, uint256 indexed pairIndex, uint256 index);

    event TpUpdated(address indexed trader, uint256 indexed pairIndex, uint256 index, uint256 newTp);
    event SlUpdated(address indexed trader, uint256 indexed pairIndex, uint256 index, uint256 newSl);
    event SlUpdateInitiated(
        uint256 indexed orderId, address indexed trader, uint256 indexed pairIndex, uint256 index, uint256 newSl
    );

    event NftOrderInitiated(
        uint256 orderId, address indexed nftHolder, address indexed trader, uint256 indexed pairIndex
    );
    event NftOrderSameBlock(address indexed nftHolder, address indexed trader, uint256 indexed pairIndex);

    event ChainlinkCallbackTimeout(uint256 indexed orderId, StorageInterfaceV5.PendingMarketOrder order);
    event CouldNotCloseTrade(address indexed trader, uint256 indexed pairIndex, uint256 index);

    // for debugging
    event Log(string message);

    constructor(
        StorageInterfaceV5 _storageT,
        NftRewardsInterfaceV6_3_1 _nftRewards,
        GNSPairInfosInterfaceV6 _pairInfos,
        // GNSReferralsInterfaceV6_2 _referrals,
        uint256 _maxPosDai,
        uint256 _marketOrdersTimeout
    ) {
        require(
            address(_storageT) != address(0) && address(_nftRewards) != address(0) && address(_pairInfos) != address(0)
            /* && address(_referrals) != address(0) **/
            && _maxPosDai > 0 && _marketOrdersTimeout > 0,
            "WRONG_PARAMS"
        );

        storageT = _storageT;
        nftRewards = _nftRewards;
        pairInfos = _pairInfos;
        // referrals = _referrals;

        maxPosDai = _maxPosDai;
        marketOrdersTimeout = _marketOrdersTimeout;
    }

    // Modifiers
    modifier onlyGov() {
        isGov();
        _;
    }

    modifier notContract() {
        isNotContract();
        _;
    }

    modifier notDone() {
        isNotDone();
        _;
    }

    // Saving code size by calling these functions inside modifiers
    function isGov() private view {
        require(msg.sender == storageT.gov(), "GOV_ONLY");
    }

    function isNotContract() private view {
        require(tx.origin == msg.sender);
    }

    function isNotDone() private view {
        require(!isDone, "DONE");
    }

    // Manage params
    function setMaxPosDai(uint256 value) external onlyGov {
        require(value > 0, "VALUE_0");
        maxPosDai = value;

        emit NumberUpdated("maxPosDai", value);
    }

    function setMarketOrdersTimeout(uint256 value) external onlyGov {
        require(value > 0, "VALUE_0");
        marketOrdersTimeout = value;

        emit NumberUpdated("marketOrdersTimeout", value);
    }

    // Manage state
    function pause() external onlyGov {
        isPaused = !isPaused;

        emit Paused(isPaused);
    }

    function done() external onlyGov {
        isDone = !isDone;

        emit Done(isDone);
    }

    // Open new trade (MARKET/LIMIT)
    function openTrade(
        StorageInterfaceV5.Trade memory t,
        NftRewardsInterfaceV6_3_1.OpenLimitOrderType orderType, // LEGACY => market
        uint256 spreadReductionId,
        uint256 slippageP /*, // for market orders only
        address referrer **/
    ) external notContract notDone {
        require(!isPaused, "PAUSED");
        require(t.openPrice * slippageP < type(uint256).max, "OVERFLOW");

        AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();
        PairsStorageInterfaceV6 pairsStored = aggregator.pairsStorage();

        address sender = _msgSender();

        require(
            storageT.openTradesCount(sender, t.pairIndex) + storageT.pendingMarketOpenCount(sender, t.pairIndex)
                + storageT.openLimitOrdersCount(sender, t.pairIndex) < storageT.maxTradesPerPair(),
            "MAX_TRADES_PER_PAIR"
        );

        require(storageT.pendingOrderIdsCount(sender) < storageT.maxPendingMarketOrders(), "MAX_PENDING_ORDERS");

        require(t.positionSizeDai <= maxPosDai, "ABOVE_MAX_POS");
        require(t.positionSizeDai * t.leverage >= pairsStored.pairMinLevPosDai(t.pairIndex), "BELOW_MIN_POS");

        require(
            t.leverage > 0 && t.leverage >= pairsStored.pairMinLeverage(t.pairIndex)
                && t.leverage <= pairsStored.pairMaxLeverage(t.pairIndex),
            "LEVERAGE_INCORRECT"
        );

        require(
            spreadReductionId == 0 || storageT.nfts(spreadReductionId - 1).balanceOf(sender) > 0,
            "NO_CORRESPONDING_NFT_SPREAD_REDUCTION"
        );

        require(t.tp == 0 || (t.buy ? t.tp > t.openPrice : t.tp < t.openPrice), "WRONG_TP");

        require(t.sl == 0 || (t.buy ? t.sl < t.openPrice : t.sl > t.openPrice), "WRONG_SL");

        (uint256 priceImpactP,) = pairInfos.getTradePriceImpact(0, t.pairIndex, t.buy, t.positionSizeDai * t.leverage);

        require(priceImpactP * t.leverage <= pairInfos.maxNegativePnlOnOpenP(), "PRICE_IMPACT_TOO_HIGH");

        // send dai from the sender to storage
        try storageT.transferDai(sender, address(storageT), t.positionSizeDai) {
        } catch {
            emit Log("transfer failed due to TradingStorage reverting");
        }

        if (orderType != NftRewardsInterfaceV6_3_1.OpenLimitOrderType.LEGACY) {
            uint256 index = storageT.firstEmptyOpenLimitIndex(sender, t.pairIndex);

            storageT.storeOpenLimitOrder(
                StorageInterfaceV5.OpenLimitOrder(
                    sender,
                    t.pairIndex,
                    index,
                    t.positionSizeDai,
                    spreadReductionId > 0 ? storageT.spreadReductionsP(spreadReductionId - 1) : 0,
                    t.buy,
                    t.leverage,
                    t.tp,
                    t.sl,
                    t.openPrice,
                    t.openPrice,
                    block.number,
                    0
                )
            );

            nftRewards.setOpenLimitOrderType(sender, t.pairIndex, index, orderType);
            storageT.callbacks().setTradeLastUpdated(
                sender, t.pairIndex, index, TradingCallbacksV6_3_1.TradeType.LIMIT, ChainUtils.getBlockNumber()
            );

            emit OpenLimitPlaced(sender, t.pairIndex, index);
        } else {
            uint256 orderId = aggregator.getPrice(
                t.pairIndex, AggregatorInterfaceV6_2.OrderType.MARKET_OPEN, t.positionSizeDai * t.leverage
            );

            storageT.storePendingMarketOrder(
                StorageInterfaceV5.PendingMarketOrder(
                    StorageInterfaceV5.Trade(
                        sender, t.pairIndex, 0, 0, t.positionSizeDai, 0, t.buy, t.leverage, t.tp, t.sl
                    ),
                    0,
                    t.openPrice,
                    slippageP,
                    spreadReductionId > 0 ? storageT.spreadReductionsP(spreadReductionId - 1) : 0,
                    0
                ),
                orderId,
                true
            );

            emit MarketOrderInitiated(orderId, sender, t.pairIndex, true);
        }

        // referrals.registerPotentialReferrer(sender, referrer);
    }

    // Close trade (MARKET)
    function closeTradeMarket(uint256 pairIndex, uint256 index) external notContract notDone {
        address sender = _msgSender();

        StorageInterfaceV5.Trade memory t = storageT.openTrades(sender, pairIndex, index);

        StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(sender, pairIndex, index);

        require(storageT.pendingOrderIdsCount(sender) < storageT.maxPendingMarketOrders(), "MAX_PENDING_ORDERS");

        require(!i.beingMarketClosed, "ALREADY_BEING_CLOSED");
        require(t.leverage > 0, "NO_TRADE");

        uint256 orderId = storageT.priceAggregator().getPrice(
            pairIndex,
            AggregatorInterfaceV6_2.OrderType.MARKET_CLOSE,
            t.initialPosToken * i.tokenPriceDai * t.leverage / PRECISION
        );

        storageT.storePendingMarketOrder(
            StorageInterfaceV5.PendingMarketOrder(
                // reset the state of the trade
                StorageInterfaceV5.Trade(sender, pairIndex, index, 0, 0, 0, false, 0, 0, 0),
                0,
                0,
                0,
                0,
                0
            ),
            orderId,
            false
        );

        emit MarketOrderInitiated(orderId, sender, pairIndex, false);
    }

    // Manage limit order (OPEN)
    function updateOpenLimitOrder(
        uint256 pairIndex,
        uint256 index,
        uint256 price, // PRECISION
        uint256 tp,
        uint256 sl
    ) external notContract notDone {
        address sender = _msgSender();

        require(storageT.hasOpenLimitOrder(sender, pairIndex, index), "NO_LIMIT");

        StorageInterfaceV5.OpenLimitOrder memory o = storageT.getOpenLimitOrder(sender, pairIndex, index);

        require(tp == 0 || (o.buy ? tp > price : tp < price), "WRONG_TP");

        require(sl == 0 || (o.buy ? sl < price : sl > price), "WRONG_SL");

        checkNoPendingTrigger(sender, pairIndex, index, StorageInterfaceV5.LimitOrder.OPEN);

        o.minPrice = price;
        o.maxPrice = price;
        o.tp = tp;
        o.sl = sl;

        storageT.updateOpenLimitOrder(o);
        storageT.callbacks().setTradeLastUpdated(
            sender, pairIndex, index, TradingCallbacksV6_3_1.TradeType.LIMIT, ChainUtils.getBlockNumber()
        );

        emit OpenLimitUpdated(sender, pairIndex, index, price, tp, sl);
    }

    function cancelOpenLimitOrder(uint256 pairIndex, uint256 index) external notContract notDone {
        address sender = _msgSender();

        require(storageT.hasOpenLimitOrder(sender, pairIndex, index), "NO_LIMIT");

        StorageInterfaceV5.OpenLimitOrder memory o = storageT.getOpenLimitOrder(sender, pairIndex, index);

        checkNoPendingTrigger(sender, pairIndex, index, StorageInterfaceV5.LimitOrder.OPEN);

        storageT.unregisterOpenLimitOrder(sender, pairIndex, index);
        storageT.transferDai(address(storageT), sender, o.positionSize);

        emit OpenLimitCanceled(sender, pairIndex, index);
    }

    // Manage limit order (TP/SL)
    function updateTp(uint256 pairIndex, uint256 index, uint256 newTp) external notContract notDone {
        address sender = _msgSender();

        checkNoPendingTrigger(sender, pairIndex, index, StorageInterfaceV5.LimitOrder.TP);

        StorageInterfaceV5.Trade memory t = storageT.openTrades(sender, pairIndex, index);

        require(t.leverage > 0, "NO_TRADE");

        storageT.updateTp(sender, pairIndex, index, newTp);
        storageT.callbacks().setTpLastUpdated(
            sender, pairIndex, index, TradingCallbacksV6_3_1.TradeType.MARKET, ChainUtils.getBlockNumber()
        );

        emit TpUpdated(sender, pairIndex, index, newTp);
    }

    function updateSl(uint256 pairIndex, uint256 index, uint256 newSl) external notContract notDone {
        address sender = _msgSender();

        checkNoPendingTrigger(sender, pairIndex, index, StorageInterfaceV5.LimitOrder.SL);

        StorageInterfaceV5.Trade memory t = storageT.openTrades(sender, pairIndex, index);

        StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(sender, pairIndex, index);

        require(t.leverage > 0, "NO_TRADE");

        uint256 maxSlDist = t.openPrice * MAX_SL_P / 100 / t.leverage;

        require(
            newSl == 0 || (t.buy ? newSl >= t.openPrice - maxSlDist : newSl <= t.openPrice + maxSlDist), "SL_TOO_BIG"
        );

        AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();

        if (newSl == 0 || !aggregator.pairsStorage().guaranteedSlEnabled(pairIndex)) {
            storageT.updateSl(sender, pairIndex, index, newSl);
            storageT.callbacks().setSlLastUpdated(
                sender, pairIndex, index, TradingCallbacksV6_3_1.TradeType.MARKET, ChainUtils.getBlockNumber()
            );

            emit SlUpdated(sender, pairIndex, index, newSl);
        } else {
            uint256 orderId = aggregator.getPrice(
                pairIndex,
                AggregatorInterfaceV6_2.OrderType.UPDATE_SL,
                t.initialPosToken * i.tokenPriceDai * t.leverage / PRECISION
            );

            aggregator.storePendingSlOrder(
                orderId, AggregatorInterfaceV6_2.PendingSl(sender, pairIndex, index, t.openPrice, t.buy, newSl)
            );

            emit SlUpdateInitiated(orderId, sender, pairIndex, index, newSl);
        }
    }

    // Execute limit order
    function executeNftOrder(
        StorageInterfaceV5.LimitOrder orderType,
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 nftId,
        uint256 nftType
    ) external notContract notDone {
        address sender = _msgSender();

        require(nftType >= 1 && nftType <= 5, "WRONG_NFT_TYPE");
        require(storageT.nfts(nftType - 1).ownerOf(nftId) == sender, "NO_NFT");

        require(block.number >= storageT.nftLastSuccess(nftId) + storageT.nftSuccessTimelock(), "SUCCESS_TIMELOCK");
        require(
            canExecute(
                orderType,
                TradingCallbacksV6_3_1.SimplifiedTradeId(
                    trader,
                    pairIndex,
                    index,
                    orderType == StorageInterfaceV5.LimitOrder.OPEN
                        ? TradingCallbacksV6_3_1.TradeType.LIMIT
                        : TradingCallbacksV6_3_1.TradeType.MARKET
                )
            ),
            "IN_TIMEOUT"
        );

        {
            (bytes32 nftHash, bytes32 botHash) =
                nftRewards.getNftBotHashes(block.number, sender, nftId, trader, pairIndex, index);
            require(!nftRewards.nftBotInUse(nftHash, botHash), "BOT_IN_USE");

            nftRewards.setNftBotInUse(nftHash, botHash);
        }

        StorageInterfaceV5.Trade memory t;

        if (orderType == StorageInterfaceV5.LimitOrder.OPEN) {
            require(storageT.hasOpenLimitOrder(trader, pairIndex, index), "NO_LIMIT");
        } else {
            t = storageT.openTrades(trader, pairIndex, index);

            require(t.leverage > 0, "NO_TRADE");

            if (orderType == StorageInterfaceV5.LimitOrder.LIQ) {
                uint256 liqPrice = pairInfos.getTradeLiquidationPrice(
                    t.trader,
                    t.pairIndex,
                    t.index,
                    t.openPrice,
                    t.buy,
                    t.initialPosToken * storageT.openTradesInfo(t.trader, t.pairIndex, t.index).tokenPriceDai
                        / PRECISION,
                    t.leverage
                );

                require(t.sl == 0 || (t.buy ? liqPrice > t.sl : liqPrice < t.sl), "HAS_SL");
            } else {
                require(orderType != StorageInterfaceV5.LimitOrder.SL || t.sl > 0, "NO_SL");
                require(orderType != StorageInterfaceV5.LimitOrder.TP || t.tp > 0, "NO_TP");
            }
        }

        NftRewardsInterfaceV6_3_1.TriggeredLimitId memory triggeredLimitId =
            NftRewardsInterfaceV6_3_1.TriggeredLimitId(trader, pairIndex, index, orderType);

        if (!nftRewards.triggered(triggeredLimitId) || nftRewards.timedOut(triggeredLimitId)) {
            uint256 leveragedPosDai;

            if (orderType == StorageInterfaceV5.LimitOrder.OPEN) {
                StorageInterfaceV5.OpenLimitOrder memory l = storageT.getOpenLimitOrder(trader, pairIndex, index);

                leveragedPosDai = l.positionSize * l.leverage;

                (uint256 priceImpactP,) = pairInfos.getTradePriceImpact(0, l.pairIndex, l.buy, leveragedPosDai);

                require(priceImpactP * l.leverage <= pairInfos.maxNegativePnlOnOpenP(), "PRICE_IMPACT_TOO_HIGH");
            } else {
                leveragedPosDai = t.initialPosToken * storageT.openTradesInfo(trader, pairIndex, index).tokenPriceDai
                    * t.leverage / PRECISION;
            }

            storageT.transferLinkToAggregator(sender, pairIndex, leveragedPosDai);

            AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();
            uint256 orderId = aggregator.getPrice(
                pairIndex,
                orderType == StorageInterfaceV5.LimitOrder.OPEN
                    ? AggregatorInterfaceV6_2.OrderType.LIMIT_OPEN
                    : AggregatorInterfaceV6_2.OrderType.LIMIT_CLOSE,
                leveragedPosDai
            );

            storageT.storePendingNftOrder(
                StorageInterfaceV5.PendingNftOrder(sender, nftId, trader, pairIndex, index, orderType), orderId
            );

            nftRewards.storeFirstToTrigger(triggeredLimitId, sender, aggregator.linkFee(pairIndex, leveragedPosDai));

            emit NftOrderInitiated(orderId, sender, trader, pairIndex);
        } else {
            nftRewards.storeTriggerSameBlock(triggeredLimitId, sender);

            emit NftOrderSameBlock(sender, trader, pairIndex);
        }
    }

    // Market timeout
    function openTradeMarketTimeout(uint256 _order) external notContract notDone {
        address sender = _msgSender();

        StorageInterfaceV5.PendingMarketOrder memory o = storageT.reqID_pendingMarketOrder(_order);

        StorageInterfaceV5.Trade memory t = o.trade;

        require(o.block > 0 && block.number >= o.block + marketOrdersTimeout, "WAIT_TIMEOUT");

        require(t.trader == sender, "NOT_YOUR_ORDER");
        require(t.leverage > 0, "WRONG_MARKET_ORDER_TYPE");

        storageT.unregisterPendingMarketOrder(_order, true);
        storageT.transferDai(address(storageT), sender, t.positionSizeDai);

        emit ChainlinkCallbackTimeout(_order, o);
    }

    function closeTradeMarketTimeout(uint256 _order) external notContract notDone {
        address sender = _msgSender();

        StorageInterfaceV5.PendingMarketOrder memory o = storageT.reqID_pendingMarketOrder(_order);

        StorageInterfaceV5.Trade memory t = o.trade;

        require(o.block > 0 && block.number >= o.block + marketOrdersTimeout, "WAIT_TIMEOUT");

        require(t.trader == sender, "NOT_YOUR_ORDER");
        require(t.leverage == 0, "WRONG_MARKET_ORDER_TYPE");

        storageT.unregisterPendingMarketOrder(_order, false);

        (bool success,) = address(this).delegatecall(
            abi.encodeWithSignature("closeTradeMarket(uint256,uint256)", t.pairIndex, t.index)
        );

        if (!success) {
            emit CouldNotCloseTrade(sender, t.pairIndex, t.index);
        }

        emit ChainlinkCallbackTimeout(_order, o);
    }

    // Helpers
    function checkNoPendingTrigger(
        address trader,
        uint256 pairIndex,
        uint256 index,
        StorageInterfaceV5.LimitOrder orderType
    ) private view {
        NftRewardsInterfaceV6_3_1.TriggeredLimitId memory triggeredLimitId =
            NftRewardsInterfaceV6_3_1.TriggeredLimitId(trader, pairIndex, index, orderType);
        require(!nftRewards.triggered(triggeredLimitId) || nftRewards.timedOut(triggeredLimitId), "PENDING_TRIGGER");
    }

    function canExecute(StorageInterfaceV5.LimitOrder orderType, TradingCallbacksV6_3_1.SimplifiedTradeId memory id)
        private
        view
        returns (bool)
    {
        if (orderType == StorageInterfaceV5.LimitOrder.LIQ) {
            return true;
        }

        uint256 b = ChainUtils.getBlockNumber();
        address cb = storageT.callbacks();

        if (orderType == StorageInterfaceV5.LimitOrder.TP) {
            return !cb.isTpInTimeout(id, b);
        }

        if (orderType == StorageInterfaceV5.LimitOrder.SL) {
            return !cb.isSlInTimeout(id, b);
        }

        return !cb.isLimitInTimeout(id, b);
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

abstract contract Delegatable {
    mapping(address => address) public delegations;
    address private senderOverride;

    function setDelegate(address delegate) external {
        // can't set delegate from a contract
        require(tx.origin == msg.sender, "NO_CONTRACT");

        delegations[msg.sender] = delegate;
    }

    function removeDelegate() external {
        delegations[msg.sender] = address(0);
    }

    function delegatedAction(address trader, bytes calldata call_data) external returns (bytes memory) {
        require(delegations[trader] == msg.sender, "DELEGATE_NOT_APPROVED");

        senderOverride = trader;
        (bool success, bytes memory result) = address(this).delegatecall(call_data);
        if (!success) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577 (return the original revert reason)
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }

        senderOverride = address(0);

        return result;
    }

    function _msgSender() public view returns (address) {
        if (senderOverride == address(0)) {
            return msg.sender;
        } else {
            return senderOverride;
        }
    }
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
pragma solidity 0.8.17;

import "../interfaces/StorageInterfaceV5.sol";

library TradeUtils {
    function _getTradeLastUpdated(
        address _callbacks,
        address trader,
        uint256 pairIndex,
        uint256 index,
        TradingCallbacksV6_3_1.TradeType _type
    )
        internal
        view
        returns (
            TradingCallbacksV6_3_1,
            TradingCallbacksV6_3_1.LastUpdated memory,
            TradingCallbacksV6_3_1.SimplifiedTradeId memory
        )
    {
        TradingCallbacksV6_3_1 callbacks = TradingCallbacksV6_3_1(_callbacks);
        TradingCallbacksV6_3_1.LastUpdated memory l = callbacks.tradeLastUpdated(trader, pairIndex, index, _type);

        return (callbacks, l, TradingCallbacksV6_3_1.SimplifiedTradeId(trader, pairIndex, index, _type));
    }

    function getTradeLastUpdated(
        address _callbacks,
        address trader,
        uint256 pairIndex,
        uint256 index,
        TradingCallbacksV6_3_1.TradeType _type
    )
        external
        view
        returns (
            TradingCallbacksV6_3_1,
            TradingCallbacksV6_3_1.LastUpdated memory,
            TradingCallbacksV6_3_1.SimplifiedTradeId memory
        )
    {
        return _getTradeLastUpdated(_callbacks, trader, pairIndex, index, _type);
    }

    function setTradeLastUpdated(
        address _callbacks,
        address trader,
        uint256 pairIndex,
        uint256 index,
        TradingCallbacksV6_3_1.TradeType _type,
        uint256 blockNumber
    ) external {
        uint32 b = uint32(blockNumber);
        TradingCallbacksV6_3_1 callbacks = TradingCallbacksV6_3_1(_callbacks);
        callbacks.setTradeLastUpdated(
            TradingCallbacksV6_3_1.SimplifiedTradeId(trader, pairIndex, index, _type),
            TradingCallbacksV6_3_1.LastUpdated(b, b, b, b)
        );
    }

    function setSlLastUpdated(
        address _callbacks,
        address trader,
        uint256 pairIndex,
        uint256 index,
        TradingCallbacksV6_3_1.TradeType _type,
        uint256 blockNumber
    ) external {
        (
            TradingCallbacksV6_3_1 callbacks,
            TradingCallbacksV6_3_1.LastUpdated memory l,
            TradingCallbacksV6_3_1.SimplifiedTradeId memory id
        ) = _getTradeLastUpdated(_callbacks, trader, pairIndex, index, _type);

        l.sl = uint32(blockNumber);
        callbacks.setTradeLastUpdated(id, l);
    }

    function setTpLastUpdated(
        address _callbacks,
        address trader,
        uint256 pairIndex,
        uint256 index,
        TradingCallbacksV6_3_1.TradeType _type,
        uint256 blockNumber
    ) external {
        (
            TradingCallbacksV6_3_1 callbacks,
            TradingCallbacksV6_3_1.LastUpdated memory l,
            TradingCallbacksV6_3_1.SimplifiedTradeId memory id
        ) = _getTradeLastUpdated(_callbacks, trader, pairIndex, index, _type);

        l.tp = uint32(blockNumber);
        callbacks.setTradeLastUpdated(id, l);
    }

    function setLimitLastUpdated(
        address _callbacks,
        address trader,
        uint256 pairIndex,
        uint256 index,
        TradingCallbacksV6_3_1.TradeType _type,
        uint256 blockNumber
    ) external {
        (
            TradingCallbacksV6_3_1 callbacks,
            TradingCallbacksV6_3_1.LastUpdated memory l,
            TradingCallbacksV6_3_1.SimplifiedTradeId memory id
        ) = _getTradeLastUpdated(_callbacks, trader, pairIndex, index, _type);

        l.limit = uint32(blockNumber);
        callbacks.setTradeLastUpdated(id, l);
    }

    function isTpInTimeout(address _callbacks, TradingCallbacksV6_3_1.SimplifiedTradeId memory id, uint256 currentBlock)
        external
        view
        returns (bool)
    {
        (TradingCallbacksV6_3_1 callbacks, TradingCallbacksV6_3_1.LastUpdated memory l,) =
            _getTradeLastUpdated(_callbacks, id.trader, id.pairIndex, id.index, id.tradeType);

        return currentBlock < uint256(l.tp) + callbacks.canExecuteTimeout();
    }

    function isSlInTimeout(address _callbacks, TradingCallbacksV6_3_1.SimplifiedTradeId memory id, uint256 currentBlock)
        external
        view
        returns (bool)
    {
        (TradingCallbacksV6_3_1 callbacks, TradingCallbacksV6_3_1.LastUpdated memory l,) =
            _getTradeLastUpdated(_callbacks, id.trader, id.pairIndex, id.index, id.tradeType);

        return currentBlock < uint256(l.sl) + callbacks.canExecuteTimeout();
    }

    function isLimitInTimeout(
        address _callbacks,
        TradingCallbacksV6_3_1.SimplifiedTradeId memory id,
        uint256 currentBlock
    ) external view returns (bool) {
        (TradingCallbacksV6_3_1 callbacks, TradingCallbacksV6_3_1.LastUpdated memory l,) =
            _getTradeLastUpdated(_callbacks, id.trader, id.pairIndex, id.index, id.tradeType);

        return currentBlock < uint256(l.limit) + callbacks.canExecuteTimeout();
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
    function getFreeUSDT() external;
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