pragma solidity 0.8.11;

import {StorageInterfaceV5} from "@interfaces/StorageInterfaceV5.sol";

contract GNSPairsStorageV6 {
    // Contracts (constant)
    StorageInterfaceV5 immutable storageT;

    // Params (constant)
    uint256 constant MIN_LEVERAGE = 2;
    uint256 constant MAX_LEVERAGE = 1000;

    // Custom data types
    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE
    }

    struct Feed {
        address feed1;
        address feed2;
        FeedCalculation feedCalculation;
        uint256 maxDeviationP; // deviation from feed
    } // PRECISION (%)

    struct Pair {
        string from;
        string to;
        Feed feed;
        uint256 spreadP; // PRECISION
        uint256 groupIndex;
        uint256 feeIndex;
    }

    struct Group {
        string name;
        bytes32 job;
        uint256 minLeverage;
        uint256 maxLeverage;
        uint256 maxCollateralP; // % (of DAI vault current balance)
    }

    struct Fee {
        string name;
        uint256 openFeeP; // PRECISION (% of leveraged pos)
        uint256 closeFeeP; // PRECISION (% of leveraged pos)
        uint256 oracleFeeP; // PRECISION (% of leveraged pos)
        uint256 nftLimitOrderFeeP; // PRECISION (% of leveraged pos)
        uint256 referralFeeP; // PRECISION (% of leveraged pos)
        uint256 minLevPosDai; // 1e18 (collateral x leverage, useful for min fee)
    }

    // State
    uint256 public currentOrderId;

    uint256 public pairsCount;
    uint256 public groupsCount;
    uint256 public feesCount;

    mapping(uint256 => Pair) public pairs;
    mapping(uint256 => Group) public groups;
    mapping(uint256 => Fee) public fees;

    mapping(string => mapping(string => bool)) public isPairListed;

    mapping(uint256 => uint256[2]) public groupsCollaterals; // (long, short)

    // Events
    event PairAdded(uint256 index, string from, string to);
    event PairUpdated(uint256 index);

    event GroupAdded(uint256 index, string name);
    event GroupUpdated(uint256 index);

    event FeeAdded(uint256 index, string name);
    event FeeUpdated(uint256 index);

    constructor(StorageInterfaceV5 _storageT, uint256 _currentOrderId) {
        require(_currentOrderId > 0, "ORDER_ID_0");
        storageT = _storageT;
        currentOrderId = _currentOrderId;
    }

    // Modifiers
    modifier onlyGov() {
        require(msg.sender == storageT.gov(), "GOV_ONLY");
        _;
    }

    modifier groupListed(uint256 _groupIndex) {
        require(groups[_groupIndex].minLeverage > 0, "GROUP_NOT_LISTED");
        _;
    }

    modifier feeListed(uint256 _feeIndex) {
        require(fees[_feeIndex].openFeeP > 0, "FEE_NOT_LISTED");
        _;
    }

    modifier feedOk(Feed calldata _feed) {
        require(_feed.maxDeviationP > 0 && _feed.feed1 != address(0), "WRONG_FEED");
        require(_feed.feedCalculation != FeedCalculation.COMBINE || _feed.feed2 != address(0), "FEED_2_MISSING");
        _;
    }

    modifier groupOk(Group calldata _group) {
        require(_group.job != bytes32(0), "JOB_EMPTY");
        require(
            _group.minLeverage >= MIN_LEVERAGE && _group.maxLeverage <= MAX_LEVERAGE
                && _group.minLeverage < _group.maxLeverage,
            "WRONG_LEVERAGES"
        );
        _;
    }

    modifier feeOk(Fee calldata _fee) {
        require(
            _fee.openFeeP > 0 && _fee.closeFeeP > 0 && _fee.oracleFeeP > 0 && _fee.nftLimitOrderFeeP > 0
                && _fee.referralFeeP > 0 && _fee.minLevPosDai > 0,
            "WRONG_FEES"
        );
        _;
    }

    // Manage pairs
    function addPair(Pair calldata _pair)
        public
        onlyGov
        feedOk(_pair.feed)
        groupListed(_pair.groupIndex)
        feeListed(_pair.feeIndex)
    {
        require(!isPairListed[_pair.from][_pair.to], "PAIR_ALREADY_LISTED");

        pairs[pairsCount] = _pair;
        isPairListed[_pair.from][_pair.to] = true;

        emit PairAdded(pairsCount++, _pair.from, _pair.to);
    }

    function addPairs(Pair[] calldata _pairs) external {
        for (uint256 i = 0; i < _pairs.length; i++) {
            addPair(_pairs[i]);
        }
    }

    function updatePair(uint256 _pairIndex, Pair calldata _pair)
        external
        onlyGov
        feedOk(_pair.feed)
        feeListed(_pair.feeIndex)
    {
        Pair storage p = pairs[_pairIndex];
        require(isPairListed[p.from][p.to], "PAIR_NOT_LISTED");

        p.feed = _pair.feed;
        p.spreadP = _pair.spreadP;
        p.feeIndex = _pair.feeIndex;

        emit PairUpdated(_pairIndex);
    }

    // Manage groups
    function addGroup(Group calldata _group) external onlyGov groupOk(_group) {
        groups[groupsCount] = _group;
        emit GroupAdded(groupsCount++, _group.name);
    }

    function updateGroup(uint256 _id, Group calldata _group) external onlyGov groupListed(_id) groupOk(_group) {
        groups[_id] = _group;
        emit GroupUpdated(_id);
    }

    // Manage fees
    function addFee(Fee calldata _fee) external onlyGov feeOk(_fee) {
        fees[feesCount] = _fee;
        emit FeeAdded(feesCount++, _fee.name);
    }

    function updateFee(uint256 _id, Fee calldata _fee) external onlyGov feeListed(_id) feeOk(_fee) {
        fees[_id] = _fee;
        emit FeeUpdated(_id);
    }

    // Update collateral open exposure for a group (callbacks)
    function updateGroupCollateral(uint256 _pairIndex, uint256 _amount, bool _long, bool _increase) external {
        require(msg.sender == storageT.callbacks(), "CALLBACKS_ONLY");

        uint256[2] storage collateralOpen = groupsCollaterals[pairs[_pairIndex].groupIndex];
        uint256 index = _long ? 0 : 1;

        if (_increase) {
            collateralOpen[index] += _amount;
        } else {
            collateralOpen[index] = collateralOpen[index] > _amount ? collateralOpen[index] - _amount : 0;
        }
    }

    // Fetch relevant info for order (aggregator)
    function pairJob(uint256 _pairIndex) external returns (string memory, string memory, bytes32, uint256) {
        require(msg.sender == address(storageT.priceAggregator()), "AGGREGATOR_ONLY");

        Pair memory p = pairs[_pairIndex];
        require(isPairListed[p.from][p.to], "PAIR_NOT_LISTED");

        return (p.from, p.to, groups[p.groupIndex].job, currentOrderId++);
    }

    // Getters (pairs & groups)
    function pairFeed(uint256 _pairIndex) external view returns (Feed memory) {
        return pairs[_pairIndex].feed;
    }

    function pairSpreadP(uint256 _pairIndex) external view returns (uint256) {
        return pairs[_pairIndex].spreadP;
    }

    function pairMinLeverage(uint256 _pairIndex) external view returns (uint256) {
        return groups[pairs[_pairIndex].groupIndex].minLeverage;
    }

    function pairMaxLeverage(uint256 _pairIndex) external view returns (uint256) {
        return groups[pairs[_pairIndex].groupIndex].maxLeverage;
    }

    function groupMaxCollateral(uint256 _pairIndex) external view returns (uint256) {
        return groups[pairs[_pairIndex].groupIndex].maxCollateralP * storageT.vault().currentBalanceDai() / 100;
    }

    function groupCollateral(uint256 _pairIndex, bool _long) external view returns (uint256) {
        return groupsCollaterals[pairs[_pairIndex].groupIndex][_long ? 0 : 1];
    }

    function guaranteedSlEnabled(uint256 _pairIndex) external view returns (bool) {
        return pairs[_pairIndex].groupIndex == 0; // crypto only
    }

    // Getters (fees)
    function pairOpenFeeP(uint256 _pairIndex) external view returns (uint256) {
        return fees[pairs[_pairIndex].feeIndex].openFeeP;
    }

    function pairCloseFeeP(uint256 _pairIndex) external view returns (uint256) {
        return fees[pairs[_pairIndex].feeIndex].closeFeeP;
    }

    function pairOracleFeeP(uint256 _pairIndex) external view returns (uint256) {
        return fees[pairs[_pairIndex].feeIndex].oracleFeeP;
    }

    function pairNftLimitOrderFeeP(uint256 _pairIndex) external view returns (uint256) {
        return fees[pairs[_pairIndex].feeIndex].nftLimitOrderFeeP;
    }

    function pairReferralFeeP(uint256 _pairIndex) external view returns (uint256) {
        return fees[pairs[_pairIndex].feeIndex].referralFeeP;
    }

    function pairMinLevPosDai(uint256 _pairIndex) external view returns (uint256) {
        return fees[pairs[_pairIndex].feeIndex].minLevPosDai;
    }

    // Getters (backend)
    function pairsBackend(uint256 _index) external view returns (Pair memory, Group memory, Fee memory) {
        Pair memory p = pairs[_index];
        return (p, groups[p.groupIndex], fees[p.feeIndex]);
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