/**
 *Submitted for verification at polygonscan.com on 2022-02-14
*/

// File: contracts\interfaces\UniswapRouterInterfaceV5.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface UniswapRouterInterfaceV5{
	function swapExactTokensForTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function swapTokensForExactTokens(
		uint amountOut,
		uint amountInMax,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);
}

// File: contracts\interfaces\TokenInterfaceV5.sol

pragma solidity 0.8.11;

interface TokenInterfaceV5{
    function burn(address, uint256) external;
    function mint(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns(bool);
    function balanceOf(address) external view returns(uint256);
    function hasRole(bytes32, address) external view returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

// File: contracts\interfaces\NftInterfaceV5.sol

pragma solidity 0.8.11;

interface NftInterfaceV5{
    function balanceOf(address) external view returns (uint);
    function ownerOf(uint) external view returns (address);
    function transferFrom(address, address, uint) external;
    function tokenOfOwnerByIndex(address, uint) external view returns(uint);
}

// File: contracts\interfaces\VaultInterfaceV5.sol

pragma solidity 0.8.11;

interface VaultInterfaceV5{
	function sendDaiToTrader(address, uint) external;
	function receiveDaiFromTrader(address, uint, uint) external;
	function currentBalanceDai() external view returns(uint);
	function distributeRewardDai(uint) external;
}

// File: contracts\interfaces\PairsStorageInterfaceV6.sol

pragma solidity 0.8.11;

interface PairsStorageInterfaceV6{
    enum FeedCalculation { DEFAULT, INVERT, COMBINE }    // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)
    struct Feed{ address feed1; address feed2; FeedCalculation feedCalculation; uint maxDeviationP; } // PRECISION (%)
    function incrementCurrentOrderId() external returns(uint);
    function updateGroupCollateral(uint, uint, bool, bool) external;
    function pairJob(uint) external returns(string memory, string memory, bytes32, uint);
    function pairFeed(uint) external view returns(Feed memory);
    function pairSpreadP(uint) external view returns(uint);
    function pairMinLeverage(uint) external view returns(uint);
    function pairMaxLeverage(uint) external view returns(uint);
    function groupMaxCollateral(uint) external view returns(uint);
    function groupCollateral(uint, bool) external view returns(uint);
    function guaranteedSlEnabled(uint) external view returns(bool);
    function pairOpenFeeP(uint) external view returns(uint);
    function pairCloseFeeP(uint) external view returns(uint);
    function pairOracleFeeP(uint) external view returns(uint);
    function pairNftLimitOrderFeeP(uint) external view returns(uint);
    function pairReferralFeeP(uint) external view returns(uint);
    function pairMinLevPosDai(uint) external view returns(uint);
}

// File: contracts\interfaces\StorageInterfaceV5.sol






pragma solidity 0.8.11;

interface StorageInterfaceV5{
    enum LimitOrder { TP, SL, LIQ, OPEN }
    struct Trader{
        uint leverageUnlocked;
        address referral;
        uint referralRewardsTotal;  // 1e18
    }
    struct Trade{
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosToken;       // 1e18
        uint positionSizeDai;       // 1e18
        uint openPrice;             // PRECISION
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION
        uint sl;                    // PRECISION
    }
    struct TradeInfo{
        uint tokenId;
        uint tokenPriceDai;         // PRECISION
        uint openInterestDai;       // 1e18
        uint tpLastUpdated;
        uint slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder{
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize;          // 1e18 (DAI or GFARM2)
        uint spreadReductionP;
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION (%)
        uint sl;                    // PRECISION (%)
        uint minPrice;              // PRECISION
        uint maxPrice;              // PRECISION
        uint block;
        uint tokenId;               // index in supportedTokens
    }
    struct PendingMarketOrder{
        Trade trade;
        uint block;
        uint wantedPrice;           // PRECISION
        uint slippageP;             // PRECISION (%)
        uint spreadReductionP;
        uint tokenId;               // index in supportedTokens
    }
    struct PendingNftOrder{
        address nftHolder;
        uint nftId;
        address trader;
        uint pairIndex;
        uint index;
        LimitOrder orderType;
    }
    function PRECISION() external pure returns(uint);
    function gov() external view returns(address);
    function dev() external view returns(address);
    function dai() external view returns(TokenInterfaceV5);
    function token() external view returns(TokenInterfaceV5);
    function linkErc677() external view returns(TokenInterfaceV5);
    function tokenDaiRouter() external view returns(UniswapRouterInterfaceV5);
    function priceAggregator() external view returns(AggregatorInterfaceV6);
    function vault() external view returns(VaultInterfaceV5);
    function trading() external view returns(address);
    function callbacks() external view returns(address);
    function handleTokens(address,uint,bool) external;
    function transferDai(address, address, uint) external;
    function transferLinkToAggregator(address, uint, uint) external;
    function unregisterTrade(address, uint, uint) external;
    function unregisterPendingMarketOrder(uint, bool) external;
    function unregisterOpenLimitOrder(address, uint, uint) external;
    function hasOpenLimitOrder(address, uint, uint) external view returns(bool);
    function storePendingMarketOrder(PendingMarketOrder memory, uint, bool) external;
    function storeReferral(address, address) external;
    function openTrades(address, uint, uint) external view returns(Trade memory);
    function openTradesInfo(address, uint, uint) external view returns(TradeInfo memory);
    function updateSl(address, uint, uint, uint) external;
    function updateTp(address, uint, uint, uint) external;
    function getOpenLimitOrder(address, uint, uint) external view returns(OpenLimitOrder memory);
    function spreadReductionsP(uint) external view returns(uint);
    function positionSizeTokenDynamic(uint,uint) external view returns(uint);
    function maxSlP() external view returns(uint);
    function storeOpenLimitOrder(OpenLimitOrder memory) external;
    function reqID_pendingMarketOrder(uint) external view returns(PendingMarketOrder memory);
    function storePendingNftOrder(PendingNftOrder memory, uint) external;
    function updateOpenLimitOrder(OpenLimitOrder calldata) external;
    function firstEmptyTradeIndex(address, uint) external view returns(uint);
    function firstEmptyOpenLimitIndex(address, uint) external view returns(uint);
    function increaseNftRewards(uint, uint) external;
    function nftSuccessTimelock() external view returns(uint);
    function currentPercentProfit(uint,uint,bool,uint) external view returns(int);
    function reqID_pendingNftOrder(uint) external view returns(PendingNftOrder memory);
    function setNftLastSuccess(uint) external;
    function updateTrade(Trade memory) external;
    function nftLastSuccess(uint) external view returns(uint);
    function unregisterPendingNftOrder(uint) external;
    function handleDevGovFees(uint, uint, bool, bool) external returns(uint);
    function distributeLpRewards(uint) external;
    function getReferral(address) external view returns(address);
    function increaseReferralRewards(address, uint) external;
    function storeTrade(Trade memory, TradeInfo memory) external;
    function setLeverageUnlocked(address, uint) external;
    function getLeverageUnlocked(address) external view returns(uint);
    function openLimitOrdersCount(address, uint) external view returns(uint);
    function maxOpenLimitOrdersPerPair() external view returns(uint);
    function openTradesCount(address, uint) external view returns(uint);
    function pendingMarketOpenCount(address, uint) external view returns(uint);
    function pendingMarketCloseCount(address, uint) external view returns(uint);
    function maxTradesPerPair() external view returns(uint);
    function maxTradesPerBlock() external view returns(uint);
    function tradesPerBlock(uint) external view returns(uint);
    function pendingOrderIdsCount(address) external view returns(uint);
    function maxPendingMarketOrders() external view returns(uint);
    function maxGainP() external view returns(uint);
    function defaultLeverageUnlocked() external view returns(uint);
    function openInterestDai(uint, uint) external view returns(uint);
    function getPendingOrderIds(address) external view returns(uint[] memory);
    function traders(address) external view returns(Trader memory);
    function nfts(uint) external view returns(NftInterfaceV5);
}

interface AggregatorInterfaceV6{
    enum OrderType { MARKET_OPEN, MARKET_CLOSE, LIMIT_OPEN, LIMIT_CLOSE, UPDATE_SL }
    function pairsStorage() external view returns(PairsStorageInterfaceV6);
    function nftRewards() external view returns(NftRewardsInterfaceV6);
    function getPrice(uint,OrderType,uint) external returns(uint);
    function tokenPriceDai() external view returns(uint);
    function linkFee(uint,uint) external view returns(uint);
    function tokenDaiReservesLp() external view returns(uint, uint);
    function pendingSlOrders(uint) external view returns(PendingSl memory);
    function storePendingSlOrder(uint orderId, PendingSl calldata p) external;
    function unregisterPendingSlOrder(uint orderId) external;
    struct PendingSl{address trader; uint pairIndex; uint index; uint openPrice; bool buy; uint newSl; }
}

interface NftRewardsInterfaceV6{
    struct TriggeredLimitId{ address trader; uint pairIndex; uint index; StorageInterfaceV5.LimitOrder order; }
    enum OpenLimitOrderType{ LEGACY, REVERSAL, MOMENTUM }
    function storeFirstToTrigger(TriggeredLimitId calldata, address) external;
    function storeTriggerSameBlock(TriggeredLimitId calldata, address) external;
    function unregisterTrigger(TriggeredLimitId calldata) external;
    function distributeNftReward(TriggeredLimitId calldata, uint) external;
    function openLimitOrderTypes(address, uint, uint) external view returns(OpenLimitOrderType);
    function setOpenLimitOrderType(address, uint, uint, OpenLimitOrderType) external;
    function triggered(TriggeredLimitId calldata) external view returns(bool);
    function timedOut(TriggeredLimitId calldata) external view returns(bool);
}

// File: contracts\GNSTradingV6.sol


pragma solidity 0.8.11;

contract GNSTradingV6{

    // Contracts (constant)
    StorageInterfaceV5 constant storageT = StorageInterfaceV5(0xaee4d11a16B2bc65EDD6416Fb626EB404a6D65BD);

    // Params (constant)
    uint constant PRECISION = 1e10;
    uint constant MAX_SL_P = 75;            // -75% PNL

    // Params (adjustable)
    uint public maxPosDai = 75000 * 1e18;   // 1e18 ($)

    uint public limitOrdersTimelock = 30;   // block
    uint public marketOrdersTimeout = 30;   // block

    // State
    bool public isPaused;   // Prevent opening new trades
    bool public isDone;     // Prevent any interaction with the contract

    // Events
    event Done(bool done);
    event Paused(bool paused);

    event NumberUpdated(string name, uint value);
    event AddressUpdated(string name, address a);

    event MarketOrderInitiated(address trader, uint pairIndex, bool open, uint orderId);

    event NftOrderInitiated(address nftHolder, address trader, uint pairIndex, uint orderId);
    event NftOrderSameBlock(address nftHolder, address trader, uint pairIndex);

    event OpenLimitPlaced(address trader, uint pairIndex, uint index);
    event OpenLimitUpdated(address trader, uint pairIndex, uint index, uint newPrice, uint newTp, uint newSl);
    event OpenLimitCanceled(address trader, uint pairIndex, uint index);

    event TpUpdated(address trader, uint pairIndex, uint index, uint newTp);
    event SlUpdated(address trader, uint pairIndex, uint index, uint newSl);
    event SlUpdateInitiated(address trader, uint pairIndex, uint index, uint newSl, uint orderId);

    event ChainlinkCallbackTimeout(uint orderId, StorageInterfaceV5.PendingMarketOrder order);
    event CouldNotCloseTrade(address trader, uint pairIndex, uint index);

    constructor() { }

    // Modifiers
    modifier onlyGov(){ require(msg.sender == storageT.gov(), "GOV_ONLY"); _; }
    modifier notContract(){ require(tx.origin == msg.sender); _; }
    modifier notDone(){ require(!isDone, "DONE"); _; }

    // Manage params
    function setMaxPosDai(uint _max) external onlyGov{
        require(_max > 0, "VALUE_0");
        maxPosDai = _max;
        emit NumberUpdated("maxPosDai", _max);
    }
    function setLimitOrdersTimelock(uint _blocks) external onlyGov{
        require(_blocks > 0, "VALUE_0");
        limitOrdersTimelock = _blocks;
        emit NumberUpdated("limitOrdersTimelock", _blocks);
    }
    function setMarketOrdersTimeout(uint _marketOrdersTimeout) external onlyGov{
        require(_marketOrdersTimeout > 0, "VALUE_0");
        marketOrdersTimeout = _marketOrdersTimeout;
        emit NumberUpdated("marketOrdersTimeout", _marketOrdersTimeout);
    }

    // Manage state
    function pause() external onlyGov{ isPaused = !isPaused; emit Paused(isPaused); }
    function done() external onlyGov{ isDone = !isDone; emit Done(isDone); }

    // Open new trade (MARKET/LIMIT)
    function openTrade(
        StorageInterfaceV5.Trade memory t,
        NftRewardsInterfaceV6.OpenLimitOrderType _type,
        uint _spreadReductionId,
        uint _slippageP,            // for market orders
        address _referral
    ) external notContract notDone{

        require(!isPaused, "PAUSED");

        AggregatorInterfaceV6 aggregator = storageT.priceAggregator();
        PairsStorageInterfaceV6 pairsStored = aggregator.pairsStorage();

        uint spreadReductionP = _spreadReductionId > 0 ? storageT.spreadReductionsP(_spreadReductionId-1) : 0;

        require(storageT.openTradesCount(msg.sender, t.pairIndex) + storageT.pendingMarketOpenCount(msg.sender, t.pairIndex) 
            + storageT.openLimitOrdersCount(msg.sender, t.pairIndex) < storageT.maxTradesPerPair(), 
            "MAX_TRADES_PER_PAIR");

        require(storageT.pendingOrderIdsCount(msg.sender) < storageT.maxPendingMarketOrders(), 
            "MAX_PENDING_ORDERS");

        require(t.positionSizeDai <= maxPosDai, "ABOVE_MAX_POS");
        require(t.positionSizeDai * t.leverage >= pairsStored.pairMinLevPosDai(t.pairIndex), "BELOW_MIN_POS");

        require(t.leverage > 0 && t.leverage >= pairsStored.pairMinLeverage(t.pairIndex) 
            && t.leverage <= pairsStored.pairMaxLeverage(t.pairIndex), 
            "LEVERAGE_INCORRECT");

        require(_spreadReductionId == 0 || storageT.nfts(_spreadReductionId-1).balanceOf(msg.sender) > 0,
            "NO_CORRESPONDING_NFT_SPREAD_REDUCTION");

        require(t.tp == 0 || (t.buy ? t.tp > t.openPrice : t.tp < t.openPrice), "WRONG_TP");
        require(t.sl == 0 || (t.buy ? t.sl < t.openPrice : t.sl > t.openPrice), "WRONG_SL");

        storageT.transferDai(msg.sender, address(storageT), t.positionSizeDai);

        if(_type != NftRewardsInterfaceV6.OpenLimitOrderType.LEGACY){
            uint index = storageT.firstEmptyOpenLimitIndex(msg.sender, t.pairIndex);

            storageT.storeOpenLimitOrder(
                StorageInterfaceV5.OpenLimitOrder(
                    msg.sender,
                    t.pairIndex,
                    index,
                    t.positionSizeDai,
                    spreadReductionP,
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

            aggregator.nftRewards().setOpenLimitOrderType(msg.sender, t.pairIndex, index, _type);

            emit OpenLimitPlaced(msg.sender, t.pairIndex, index);

        }else{
            uint orderId = aggregator.getPrice(
                t.pairIndex, 
                AggregatorInterfaceV6.OrderType.MARKET_OPEN, 
                t.positionSizeDai * t.leverage
            );

            storageT.storePendingMarketOrder(
                StorageInterfaceV5.PendingMarketOrder(
                    StorageInterfaceV5.Trade(
                        msg.sender,
                        t.pairIndex,
                        0, 0,
                        t.positionSizeDai,
                        0, 
                        t.buy,
                        t.leverage,
                        t.tp,
                        t.sl
                    ),
                    0,
                    t.openPrice,
                    _slippageP,
                    spreadReductionP,
                    0
                ), orderId, true
            );

            emit MarketOrderInitiated(msg.sender, t.pairIndex, true, orderId);
        }

        storageT.storeReferral(msg.sender, _referral);
    }

    // Close trade (MARKET)
    function closeTradeMarket(uint _pairIndex, uint _index) external notContract notDone{
        
        StorageInterfaceV5.Trade memory t = storageT.openTrades(msg.sender, _pairIndex, _index);
        StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(msg.sender, _pairIndex, _index);

        require(storageT.pendingOrderIdsCount(msg.sender) < storageT.maxPendingMarketOrders(), 
            "MAX_PENDING_ORDERS");
        require(!i.beingMarketClosed, "ALREADY_BEING_CLOSED");
        require(t.leverage > 0, "NO_TRADE");

        uint orderId = storageT.priceAggregator().getPrice(
            _pairIndex, 
            AggregatorInterfaceV6.OrderType.MARKET_CLOSE, 
            t.initialPosToken * t.leverage * i.tokenPriceDai / PRECISION
        );

        storageT.storePendingMarketOrder(
            StorageInterfaceV5.PendingMarketOrder(
                StorageInterfaceV5.Trade(msg.sender, _pairIndex, _index, 0, 0, 0, false, 0, 0, 0),
                0, 0, 0, 0, 0
            ), orderId, false
        );

        emit MarketOrderInitiated(msg.sender, _pairIndex, false, orderId);
    }

    // Manage limit order (OPEN)
    function updateOpenLimitOrder(
        uint _pairIndex, 
        uint _index, 
        uint _price,        // PRECISION
        uint _tp,
        uint _sl
    ) external notContract notDone{

        require(storageT.hasOpenLimitOrder(msg.sender, _pairIndex, _index), "NO_LIMIT");

        StorageInterfaceV5.OpenLimitOrder memory o = storageT.getOpenLimitOrder(msg.sender, _pairIndex, _index);
        require(block.number - o.block >= limitOrdersTimelock, "LIMIT_TIMELOCK");

        require(_tp == 0 || (o.buy ? _price < _tp : _price > _tp), "WRONG_TP");
        require(_sl == 0 || (o.buy ? _price > _sl : _price < _sl), "WRONG_SL");

        o.minPrice = _price;
        o.maxPrice = _price;

        o.tp = _tp;
        o.sl = _sl;

        storageT.updateOpenLimitOrder(o);

        emit OpenLimitUpdated(msg.sender, _pairIndex, _index, _price, _tp, _sl);
    }
    function cancelOpenLimitOrder(uint _pairIndex, uint _index) external notContract notDone{

        require(storageT.hasOpenLimitOrder(msg.sender, _pairIndex, _index), "NO_LIMIT");

        StorageInterfaceV5.OpenLimitOrder memory o = storageT.getOpenLimitOrder(msg.sender, _pairIndex, _index);
        require(block.number - o.block >= limitOrdersTimelock, "LIMIT_TIMELOCK");

        storageT.transferDai(address(storageT), msg.sender, o.positionSize);
        storageT.unregisterOpenLimitOrder(msg.sender, _pairIndex, _index);

        emit OpenLimitCanceled(msg.sender, _pairIndex, _index);
    }

    // Manage limit order (TP/SL)
    function updateTp(uint _pairIndex, uint _index, uint _newTp) external notContract notDone{

        StorageInterfaceV5.Trade memory t = storageT.openTrades(msg.sender, _pairIndex, _index);
        StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(msg.sender, _pairIndex, _index);

        require(t.leverage > 0, "NO_TRADE");
        require(block.number - i.tpLastUpdated >= limitOrdersTimelock, "LIMIT_TIMELOCK");

        storageT.updateTp(msg.sender, _pairIndex, _index, _newTp);

        emit TpUpdated(msg.sender, _pairIndex, _index, _newTp);
    }
    function updateSl(uint _pairIndex, uint _index, uint _newSl) external notContract notDone{

        StorageInterfaceV5.Trade memory t = storageT.openTrades(msg.sender, _pairIndex, _index);
        StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(msg.sender, _pairIndex, _index);

        require(t.leverage > 0, "NO_TRADE");

        uint maxSlDist = t.openPrice * MAX_SL_P / 100 / t.leverage;
        require(_newSl == 0 || (t.buy ? _newSl >= t.openPrice - maxSlDist : _newSl <= t.openPrice + maxSlDist), 
            "SL_TOO_BIG");
        
        require(block.number - i.slLastUpdated >= limitOrdersTimelock, "LIMIT_TIMELOCK");

        AggregatorInterfaceV6 aggregator = storageT.priceAggregator();

        if(_newSl == 0 || !aggregator.pairsStorage().guaranteedSlEnabled(_pairIndex)){

            storageT.updateSl(msg.sender, _pairIndex, _index, _newSl);
            emit SlUpdated(msg.sender, _pairIndex, _index, _newSl);

        }else{
            uint levPosDai = t.initialPosToken * i.tokenPriceDai * t.leverage;

            t.initialPosToken -= storageT.handleDevGovFees(
                t.pairIndex, 
                levPosDai / aggregator.tokenPriceDai(),
                false,
                false
            );

            storageT.updateTrade(t);

            uint orderId = aggregator.getPrice(
                _pairIndex,
                AggregatorInterfaceV6.OrderType.UPDATE_SL, 
                levPosDai / PRECISION
            );

            aggregator.storePendingSlOrder(
                orderId, 
                AggregatorInterfaceV6.PendingSl(msg.sender, _pairIndex, _index, t.openPrice, t.buy, _newSl)
            );
            
            emit SlUpdateInitiated(msg.sender, _pairIndex, _index, _newSl, orderId);
        }
    }

    // Execute limit order
    function executeNftOrder(
        StorageInterfaceV5.LimitOrder _orderType, 
        address _trader, 
        uint _pairIndex, 
        uint _index,
        uint _nftId, 
        uint _nftType
    ) external notContract notDone{

        StorageInterfaceV5.Trade memory t = storageT.openTrades(_trader, _pairIndex, _index);

        require(_nftType >= 1 && _nftType <= 5, "WRONG_NFT_TYPE");
        require(storageT.nfts(_nftType-1).ownerOf(_nftId) == msg.sender, "NO_NFT");
        require(block.number >= storageT.nftLastSuccess(_nftId) + storageT.nftSuccessTimelock(),
            "SUCCESS_TIMELOCK");
        
        require(_orderType == StorageInterfaceV5.LimitOrder.OPEN ? storageT.hasOpenLimitOrder(_trader, _pairIndex, _index)
            : t.leverage > 0, "NO_TRADE");
        require(_orderType != StorageInterfaceV5.LimitOrder.SL || t.sl > 0, "NO_SL");
        require(_orderType != StorageInterfaceV5.LimitOrder.LIQ || t.sl == 0, "HAS_SL");

        AggregatorInterfaceV6 aggregator = storageT.priceAggregator();
        NftRewardsInterfaceV6 nftIncentives = aggregator.nftRewards();

        NftRewardsInterfaceV6.TriggeredLimitId memory triggeredLimitId = NftRewardsInterfaceV6.TriggeredLimitId(
            _trader, _pairIndex, _index, _orderType
        );

        if(!nftIncentives.triggered(triggeredLimitId) || nftIncentives.timedOut(triggeredLimitId)){
            
            uint leveragedPosDai;

            if(_orderType == StorageInterfaceV5.LimitOrder.OPEN){
                StorageInterfaceV5.OpenLimitOrder memory l = storageT.getOpenLimitOrder(_trader, _pairIndex, _index);
                leveragedPosDai = l.positionSize * l.leverage;
            }else{
                StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(_trader, _pairIndex, _index);
                leveragedPosDai = t.initialPosToken * i.tokenPriceDai * t.leverage / PRECISION;
            }

            storageT.transferLinkToAggregator(msg.sender, _pairIndex, leveragedPosDai);

            uint orderId = aggregator.getPrice(
                _pairIndex, 
                _orderType == StorageInterfaceV5.LimitOrder.OPEN ? 
                    AggregatorInterfaceV6.OrderType.LIMIT_OPEN : 
                    AggregatorInterfaceV6.OrderType.LIMIT_CLOSE,
                leveragedPosDai
            );

            storageT.storePendingNftOrder(
                StorageInterfaceV5.PendingNftOrder(
                    msg.sender,
                    _nftId,
                    _trader,
                    _pairIndex,
                    _index,
                    _orderType
                ), orderId
            );

            nftIncentives.storeFirstToTrigger(triggeredLimitId, msg.sender);
            emit NftOrderInitiated(msg.sender, _trader, _pairIndex, orderId);

        }else{
            nftIncentives.storeTriggerSameBlock(triggeredLimitId, msg.sender);
            emit NftOrderSameBlock(msg.sender, _trader, _pairIndex);
        }
    }

    // Market timeout
    function openTradeMarketTimeout(uint _order) external notContract notDone{

        StorageInterfaceV5.PendingMarketOrder memory o = storageT.reqID_pendingMarketOrder(_order);
        StorageInterfaceV5.Trade memory t = o.trade;

        require(o.block > 0 && block.number >= o.block + marketOrdersTimeout, 
            "WAIT_TIMEOUT");
        require(t.trader == msg.sender, "NOT_YOUR_ORDER");
        require(t.leverage > 0, "WRONG_MARKET_ORDER_TYPE");

        storageT.transferDai(address(storageT), msg.sender, t.positionSizeDai);
        storageT.unregisterPendingMarketOrder(_order, true);

        emit ChainlinkCallbackTimeout(_order, o);
    }
    function closeTradeMarketTimeout(uint _order) external notContract notDone{

        StorageInterfaceV5.PendingMarketOrder memory o = storageT.reqID_pendingMarketOrder(_order);
        StorageInterfaceV5.Trade memory t = o.trade;

        require(o.block > 0 && block.number >= o.block + marketOrdersTimeout, 
            "WAIT_TIMEOUT");
        require(t.trader == msg.sender, "NOT_YOUR_ORDER");
        require(t.leverage == 0, "WRONG_MARKET_ORDER_TYPE");

        storageT.unregisterPendingMarketOrder(_order, false);

        (bool success, ) = address(this).delegatecall(
            abi.encodeWithSignature(
                "closeTradeMarket(uint256,uint256)",
                t.pairIndex,
                t.index
            )
        );

        if(!success){
            emit CouldNotCloseTrade(msg.sender, t.pairIndex, t.index);
        }

        emit ChainlinkCallbackTimeout(_order, o);
    }
}