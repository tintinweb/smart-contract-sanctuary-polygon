// SPDX-License-Identifier: MIT

import "@interfaces/StorageInterfaceV5.sol";
import "@openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

pragma solidity 0.8.17;

contract GNSNftRewardsV6_3_1 is Initializable {
    // Contracts (constant)
    StorageInterfaceV5 public storageT;

    // Params (constant)
    uint256 constant ROUND_LENGTH = 50;
    uint256 constant MIN_TRIGGER_TIMEOUT = 1;
    uint256 constant MIN_SAME_BLOCK_LIMIT = 5;
    uint256 constant MAX_SAME_BLOCK_LIMIT = 50;
    uint256 constant PRECISION = 1e10; // 10 decimals

    // Params (adjustable)
    uint256 public triggerTimeout; // blocks
    uint256 public sameBlockLimit; // bots

    // Custom data types
    struct TriggeredLimit {
        address first;
        address[] sameBlock;
        uint256 block;
        uint240 linkFee;
        uint16 sameBlockLimit;
    }

    struct TriggeredLimitId {
        address trader;
        uint256 pairIndex;
        uint256 index;
        StorageInterfaceV5.LimitOrder order;
    }

    struct RoundDetails {
        uint240 tokens;
        uint16 totalEntries;
    }

    enum OpenLimitOrderType {
        LEGACY,
        REVERSAL,
        MOMENTUM
    }

    // State
    uint256 public currentOrder; // current order in round
    uint256 public currentRound; // current round (1 round = 50 orders)

    mapping(uint256 => RoundDetails) public roundTokens; // total token rewards and entries for a round
    mapping(address => mapping(uint256 => uint256)) public roundOrdersToClaim; // orders to claim from a round (out of 50)

    mapping(address => uint256) public tokensToClaim; // rewards other than pool (first & same block)

    mapping(address => mapping(uint256 => mapping(uint256 => mapping(StorageInterfaceV5.LimitOrder => TriggeredLimit))))
        public triggeredLimits; // limits being triggered

    mapping(address => mapping(uint256 => mapping(uint256 => OpenLimitOrderType))) public openLimitOrderTypes;
    bool public stateCopied;

    // Tracker to prevent multiple triggers from same address or same nft
    mapping(bytes32 => bool) public botInUse;

    // Statistics
    mapping(address => uint256) public tokensClaimed; // 1e18
    uint256 public tokensClaimedTotal; // 1e18

    // Events
    event NumberUpdated(string name, uint256 value);

    event TriggeredFirst(TriggeredLimitId id, address bot, uint256 linkFee);
    event TriggeredSameBlock(TriggeredLimitId id, address bot, uint256 linkContribution);
    event TriggerUnregistered(TriggeredLimitId id);
    event TriggerRewarded(
        TriggeredLimitId id, address first, uint256 sameBlockCount, uint256 sameBlockLimit, uint256 reward
    );

    event PoolTokensClaimed(address bot, uint256 fromRound, uint256 toRound, uint256 tokens);
    event TokensClaimed(address bot, uint256 tokens);

    function initialize(StorageInterfaceV5 _storageT, uint256 _triggerTimeout, uint256 _sameBlockLimit)
        external
        initializer
    {
        require(
            address(_storageT) != address(0) && _triggerTimeout >= MIN_TRIGGER_TIMEOUT
                && _sameBlockLimit >= MIN_SAME_BLOCK_LIMIT && _sameBlockLimit <= MAX_SAME_BLOCK_LIMIT,
            "WRONG_PARAMS"
        );

        storageT = _storageT;

        triggerTimeout = _triggerTimeout;
        sameBlockLimit = _sameBlockLimit;

        currentOrder = 1;
    }

    // Modifiers
    modifier onlyGov() {
        require(msg.sender == storageT.gov(), "GOV_ONLY");
        _;
    }

    modifier onlyTrading() {
        require(msg.sender == storageT.trading(), "TRADING_ONLY");
        _;
    }

    modifier onlyCallbacks() {
        require(msg.sender == storageT.callbacks(), "CALLBACKS_ONLY");
        _;
    }

    function copyOldLimitTypes(uint256 start, uint256 end) external onlyGov {
        require(!stateCopied, "COPY_DONE");
        require(start <= end, "START_AFTER_END");

        NftRewardsInterfaceV6_3_1 old;

        if (block.chainid == 137) {
            // Polygon Mainnet
            old = NftRewardsInterfaceV6_3_1(0x3470756E5B490a974Bc25FeEeEb24c11102f5268);
        } else if (block.chainid == 80001) {
            // Mumbai
            old = NftRewardsInterfaceV6_3_1(0x3982E3de77DAd60373C0c2c539fCb93Bd288D2f5);
        } else if (block.chainid == 42161) {
            // Arbitrum
            old = NftRewardsInterfaceV6_3_1(0xc2d107e870927E3fb1127E6c1a33De5C863505b8);
        } else {
            revert("UNKNOWN_CHAIN");
        }

        StorageInterfaceV5.OpenLimitOrder[] memory openLimitOrders =
            IStateCopyUtils(address(storageT)).getOpenLimitOrders();
        require(start < openLimitOrders.length, "START_TOO_BIG");

        if (end >= openLimitOrders.length) {
            end = openLimitOrders.length - 1;
        }

        for (uint256 i = start; i <= end;) {
            StorageInterfaceV5.OpenLimitOrder memory o = openLimitOrders[i];
            openLimitOrderTypes[o.trader][o.pairIndex][o.index] =
                OpenLimitOrderType(uint256(old.openLimitOrderTypes(o.trader, o.pairIndex, o.index)));
            ++i;
        }
    }

    function setStateCopyAsDone() external onlyGov {
        stateCopied = true;
    }

    // Manage params
    function updateTriggerTimeout(uint256 _triggerTimeout) external onlyGov {
        require(_triggerTimeout >= MIN_TRIGGER_TIMEOUT, "BELOW_MIN");
        triggerTimeout = _triggerTimeout;
        emit NumberUpdated("triggerTimeout", _triggerTimeout);
    }

    function updateSameBlockLimit(uint256 _sameBlockLimit) external onlyGov {
        require(_sameBlockLimit >= MIN_SAME_BLOCK_LIMIT, "BELOW_MIN");
        require(_sameBlockLimit <= MAX_SAME_BLOCK_LIMIT, "ABOVE_MAX");

        sameBlockLimit = _sameBlockLimit;

        emit NumberUpdated("sameBlockLimit", _sameBlockLimit);
    }

    // Triggers
    function storeFirstToTrigger(TriggeredLimitId calldata _id, address _bot, uint256 _linkFee) external onlyTrading {
        TriggeredLimit storage t = triggeredLimits[_id.trader][_id.pairIndex][_id.index][_id.order];

        t.first = _bot;
        t.linkFee = uint240(_linkFee);
        t.sameBlockLimit = uint16(sameBlockLimit);

        delete t.sameBlock;
        t.block = block.number;
        t.sameBlock.push(_bot);

        emit TriggeredFirst(_id, _bot, _linkFee);
    }

    function storeTriggerSameBlock(TriggeredLimitId calldata _id, address _bot) external onlyTrading {
        TriggeredLimit storage t = triggeredLimits[_id.trader][_id.pairIndex][_id.index][_id.order];

        require(t.block == block.number, "TOO_LATE");
        require(t.sameBlock.length < t.sameBlockLimit, "SAME_BLOCK_LIMIT");

        uint256 linkContribution = t.linkFee / t.sameBlockLimit;

        // transfer 1/N th of the trigger link cost in exchange for an equal share of reward
        storageT.linkErc677().transferFrom(_bot, t.first, linkContribution);

        t.sameBlock.push(_bot);

        emit TriggeredSameBlock(_id, _bot, linkContribution);
    }

    function unregisterTrigger(TriggeredLimitId calldata _id) external onlyCallbacks {
        delete triggeredLimits[_id.trader][_id.pairIndex][_id.index][_id.order];
        emit TriggerUnregistered(_id);
    }

    // Distribute rewards
    function distributeNftReward(TriggeredLimitId calldata _id, uint256 _reward, uint256 _tokenPriceDai)
        external
        onlyCallbacks
    {
        TriggeredLimit memory t = triggeredLimits[_id.trader][_id.pairIndex][_id.index][_id.order];

        require(t.block > 0, "NOT_TRIGGERED");

        uint256 nextRound = currentRound + 1;
        uint256 linkEquivalentRewards = linkToTokenRewards(t.linkFee, _tokenPriceDai); // amount of link spent in gns

        // if we've somehow ended up with an odd rate revert to using full rewards
        if (linkEquivalentRewards > _reward) {
            linkEquivalentRewards = _reward;
        }

        // rewards per trigger
        uint256 sameBlockReward = linkEquivalentRewards / t.sameBlockLimit;

        for (uint256 i = 0; i < t.sameBlock.length; i++) {
            address bot = t.sameBlock[i];

            tokensToClaim[bot] += sameBlockReward; // link refund
            roundOrdersToClaim[bot][nextRound]++; // next round pool entry
        }

        uint256 missingSameBlocks = t.sameBlockLimit - t.sameBlock.length;
        if (missingSameBlocks > 0) {
            // reward first trigger equivalent amount of missed link refunds in gns, but no extra entries into the pool
            tokensToClaim[t.first] += sameBlockReward * missingSameBlocks;
        }

        // REWARD POOLS ARE BLIND
        // when you trigger orders you earn entries for next round
        // next round tokens can't be predicted
        // rewards are added to current round and claimable by previous round (currentRound - 1) entrants

        roundTokens[currentRound].tokens += uint240(_reward - linkEquivalentRewards);
        roundTokens[nextRound].totalEntries += uint16(t.sameBlock.length);

        storageT.handleTokens(address(this), currentRound > 0 ? _reward : linkEquivalentRewards, true);

        if (currentOrder == ROUND_LENGTH) {
            currentOrder = 1;
            currentRound++;
        } else {
            currentOrder++;
        }

        emit TriggerRewarded(_id, t.first, t.sameBlock.length, t.sameBlockLimit, _reward);
    }

    // Claim rewards
    function claimPoolTokens(uint256 _fromRound, uint256 _toRound) external {
        require(_toRound >= _fromRound, "TO_BEFORE_FROM");
        require(_toRound < currentRound, "TOO_EARLY");

        uint256 tokens;

        // due to blind rewards round 0 will have 0 entries; r[0] rewards are effectively burned/never minted
        for (uint256 i = _fromRound; i <= _toRound; i++) {
            uint256 roundEntries = roundOrdersToClaim[msg.sender][i];

            if (roundEntries > 0) {
                RoundDetails memory roundDetails = roundTokens[i];
                tokens += roundEntries * roundDetails.tokens / roundDetails.totalEntries;
                roundOrdersToClaim[msg.sender][i] = 0;
            }
        }

        require(tokens > 0, "NOTHING_TO_CLAIM");
        storageT.token().transfer(msg.sender, tokens);

        tokensClaimed[msg.sender] += tokens;
        tokensClaimedTotal += tokens;

        emit PoolTokensClaimed(msg.sender, _fromRound, _toRound, tokens);
    }

    function claimTokens() external {
        uint256 tokens = tokensToClaim[msg.sender];
        require(tokens > 0, "NOTHING_TO_CLAIM");

        tokensToClaim[msg.sender] = 0;
        storageT.token().transfer(msg.sender, tokens);

        tokensClaimed[msg.sender] += tokens;
        tokensClaimedTotal += tokens;

        emit TokensClaimed(msg.sender, tokens);
    }

    // Manage open limit order types
    function setOpenLimitOrderType(address _trader, uint256 _pairIndex, uint256 _index, OpenLimitOrderType _type)
        external
        onlyTrading
    {
        openLimitOrderTypes[_trader][_pairIndex][_index] = _type;
    }

    // Set bot address and NFT in use so it cannot be used in the same order twice
    function setNftBotInUse(bytes32 nftHash, bytes32 botHash) external onlyTrading {
        botInUse[nftHash] = true;
        botInUse[botHash] = true;
    }

    // Getters
    function triggered(TriggeredLimitId calldata _id) external view returns (bool) {
        TriggeredLimit memory t = triggeredLimits[_id.trader][_id.pairIndex][_id.index][_id.order];
        return t.block > 0;
    }

    function timedOut(TriggeredLimitId calldata _id) external view returns (bool) {
        TriggeredLimit memory t = triggeredLimits[_id.trader][_id.pairIndex][_id.index][_id.order];
        return t.block > 0 && block.number - t.block >= triggerTimeout;
    }

    function sameBlockTriggers(TriggeredLimitId calldata _id) external view returns (address[] memory) {
        return triggeredLimits[_id.trader][_id.pairIndex][_id.index][_id.order].sameBlock;
    }

    function getNftBotHashes(
        uint256 triggerBlock,
        address bot,
        uint256 nftId,
        address trader,
        uint256 pairIndex,
        uint256 index
    ) external pure returns (bytes32, bytes32) {
        return (
            keccak256(abi.encodePacked("N", triggerBlock, nftId, trader, pairIndex, index)),
            keccak256(abi.encodePacked("B", triggerBlock, bot, trader, pairIndex, index))
        );
    }

    function nftBotInUse(bytes32 nftHash, bytes32 botHash) external view returns (bool) {
        return botInUse[nftHash] || botInUse[botHash];
    }

    function linkToTokenRewards(uint256 linkFee, uint256 tokenPrice) public view returns (uint256) {
        (, int256 linkPriceUsd,,,) =
            AggregatorInterfaceV6_3_1(address(storageT.priceAggregator())).linkPriceFeed().latestRoundData();
        return linkFee * uint256(linkPriceUsd) * PRECISION / tokenPrice / 1e8;
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