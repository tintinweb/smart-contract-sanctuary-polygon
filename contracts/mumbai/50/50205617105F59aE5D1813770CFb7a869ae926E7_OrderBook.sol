// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./oracle/IOracle.sol";
import './lib/UniERC20.sol';
import "./interface/IKiloPerp.sol";
import "./KiloPerp.sol";
import "./access/Governable.sol";
import "./perp/IFeeCalculator.sol";
import "hardhat/console.sol";

contract OrderBook is Governable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using UniERC20 for IERC20;
    using Address for address payable;

    struct OpenOrder {
        address account;
        uint256 productId;
        uint256 margin;
        uint256 leverage;
        uint256 tradeFee;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
        uint256 orderTimestamp;
    }
    struct CloseOrder {
        address account;
        uint256 productId;
        uint256 size;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
        uint256 orderTimestamp;
    }

    mapping (address => mapping(uint256 => OpenOrder)) public openOrders; //account => (index => OpenOrder)
    mapping (address => uint256) public openOrdersIndex; //sender所下过的单数，从1开始
    mapping (address => mapping(uint256 => CloseOrder)) public closeOrders;
    mapping (address => uint256) public closeOrdersIndex;
    mapping (address => bool) public isKeeper;

    uint256 public immutable tokenBase;
    address public immutable kiloPerp;
    address public immutable collateralToken;
    uint256 public constant BASE = 1e8;
    uint256 public constant FEE_BASE = 1e4;

    address public owner;
    address public oracle;
    address public feeCalculator;
    uint256 public minExecutionFee;
    uint256 public minTimeExecuteDelay; //现网为0
    uint256 public minTimeCancelDelay; //现网为0
    bool public allowPublicKeeper = false; //现网为false
    bool public isKeeperCall = false;
    
    event CreateOpenOrder(
        address indexed account,
        uint256 orderIndex,
        uint256 productId,
        uint256 margin,
        uint256 leverage,
        uint256 tradeFee,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 orderTimestamp
    );
    event CancelOpenOrder(
        address indexed account,
        uint256 orderIndex,
        uint256 productId,
        uint256 margin,
        uint256 leverage,
        uint256 tradeFee,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 orderTimestamp
    );
    event ExecuteOpenOrder(
        address indexed account,
        uint256 orderIndex,
        uint256 productId,
        uint256 margin,
        uint256 leverage,
        uint256 tradeFee,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 orderTimestamp,
        uint256 executionPrice
    );
    event UpdateOpenOrder(
        address indexed account,
        uint256 orderIndex,
        uint256 productId,
        uint256 margin,
        uint256 leverage,
        uint256 tradeFee,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 orderTimestamp
    );
    event CreateCloseOrder(
        address indexed account,
        uint256 orderIndex,
        uint256 productId,
        uint256 size,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 orderTimestamp
    );
    event CancelCloseOrder(
        address indexed account,
        uint256 orderIndex,
        uint256 productId,
        uint256 size,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 orderTimestamp
    );
    event ExecuteCloseOrder(
        address indexed account,
        uint256 orderIndex,
        uint256 productId,
        uint256 size,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 orderTimestamp,
        uint256 executionPrice
    );
    event UpdateCloseOrder(
        address indexed account,
        uint256 orderIndex,
        uint256 productId,
        uint256 size,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 orderTimestamp
    );
    event ExecuteOpenOrderError(address indexed account, uint256 orderIndex, string executionError);
    event ExecuteCloseOrderError(address indexed account, uint256 orderIndex, string executionError);
    event UpdateMinTimeExecuteDelay(uint256 minTimeExecuteDelay);
    event UpdateMinTimeCancelDelay(uint256 minTimeCancelDelay);
    event UpdateAllowPublicKeeper(bool allowPublicKeeper);
    event UpdateMinExecutionFee(uint256 minExecutionFee);
    event UpdateKeeper(address keeper, bool isAlive);
    event SetOwner(address owner);

    modifier onlyOwner() {
        require(msg.sender == owner, "OrderBook: !owner");
        _;
    }

    modifier onlyKeeper() {
        require(isKeeper[msg.sender], "OrderBook: !keeper");
        _;
    }

    constructor(
        address _kiloPerp,
        address _oracle,
        address _collateralToken,
        uint256 _tokenBase,
        uint256 _minExecutionFee,
        address _feeCalculator
    ) {
        owner = msg.sender;
        kiloPerp = _kiloPerp;
        oracle = _oracle;
        collateralToken = _collateralToken;
        tokenBase = _tokenBase;
        minExecutionFee = _minExecutionFee;
        feeCalculator = _feeCalculator;
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }

    function setFeeCalculator(address _feeCalculator) external onlyOwner {
        feeCalculator = _feeCalculator;
    }

    function setMinExecutionFee(uint256 _minExecutionFee) external onlyOwner {
        minExecutionFee = _minExecutionFee;
        emit UpdateMinExecutionFee(_minExecutionFee);
    }

    function setMinTimeExecuteDelay(uint256 _minTimeExecuteDelay) external onlyOwner {
        minTimeExecuteDelay = _minTimeExecuteDelay;
        emit UpdateMinTimeExecuteDelay(_minTimeExecuteDelay);
    }

    function setMinTimeCancelDelay(uint256 _minTimeCancelDelay) external onlyOwner {
        minTimeCancelDelay = _minTimeCancelDelay;
        emit UpdateMinTimeCancelDelay(_minTimeCancelDelay);
    }

    function setAllowPublicKeeper(bool _allowPublicKeeper) external onlyOwner {
        allowPublicKeeper = _allowPublicKeeper;
        emit UpdateAllowPublicKeeper(_allowPublicKeeper);
    }

    function setKeeper(address _account, bool _isActive) external onlyOwner {
        isKeeper[_account] = _isActive;
        emit UpdateKeeper(_account, _isActive);
    }

    function setOwner(address _owner) external onlyGov {
        owner = _owner;
        emit SetOwner(_owner);
    }

    function executeOrdersWithPrices(
        address[] memory tokens,
        uint256[] memory prices,
        address[] memory _openAddresses,
        uint256[] memory _openOrderIndexes,
        address[] memory _closeAddresses,
        uint256[] memory _closeOrderIndexes,
        address payable _feeReceiver
    ) external onlyKeeper {
        IOracle(oracle).setPrices(tokens, prices);
        executeOrders(_openAddresses, _openOrderIndexes, _closeAddresses, _closeOrderIndexes, _feeReceiver);
    }

    function executeOrders(
        address[] memory _openAddresses,
        uint256[] memory _openOrderIndexes,
        address[] memory _closeAddresses,
        uint256[] memory _closeOrderIndexes,
        address payable _feeReceiver
    ) public {
        require(_openAddresses.length == _openOrderIndexes.length && _closeAddresses.length == _closeOrderIndexes.length, "OrderBook: not same length");
        isKeeperCall = isKeeper[msg.sender];
        for (uint256 i = 0; i < _openAddresses.length; i++) {
            try this.executeOpenOrder(_openAddresses[i], _openOrderIndexes[i], _feeReceiver) {
            } catch Error(string memory executionError) {
                emit ExecuteOpenOrderError(_openAddresses[i], _openOrderIndexes[i], executionError);
            } catch (bytes memory /*lowLevelData*/) {}
        }
        for (uint256 i = 0; i < _closeAddresses.length; i++) {
            try this.executeCloseOrder(_closeAddresses[i], _closeOrderIndexes[i], _feeReceiver) {
            } catch Error(string memory executionError) {
                emit ExecuteCloseOrderError(_closeAddresses[i], _closeOrderIndexes[i], executionError);
            } catch (bytes memory /*lowLevelData*/) {}
        }
        isKeeperCall = false;
    }

    function cancelMultiple(
        uint256[] memory _openOrderIndexes,
        uint256[] memory _closeOrderIndexes
    ) external {
        for (uint256 i = 0; i < _openOrderIndexes.length; i++) {
            cancelOpenOrder(_openOrderIndexes[i]);
        }
        for (uint256 i = 0; i < _closeOrderIndexes.length; i++) {
            cancelCloseOrder(_closeOrderIndexes[i]);
        }
    }

    function validatePositionOrderPrice(
        bool _isLong,
        bool _triggerAboveThreshold,
        uint256 _triggerPrice,
        uint256 _productId
    ) public view returns (uint256 currentPrice) {
        (address productToken,,,,,,,,) = IKiloPerp(kiloPerp).getProduct(_productId);
        currentPrice = _isLong ? IOracle(oracle).getPrice(productToken, true) : IOracle(oracle).getPrice(productToken, false);
        //_triggerAboveThreshold == true 做空仓位止损，当前价必须>=触发价
        //_triggerAboveThreshold == false 做多仓位止损，当前价必须<=触发价
        bool isPriceValid = _triggerAboveThreshold ? currentPrice >= _triggerPrice : currentPrice <= _triggerPrice;
        require(isPriceValid, "OrderBook: invalid price for execution");
        //return (currentPrice, isPriceValid); 优化：这一步 isPriceValid 不可能为false 就多余没用了
    }

    function getCloseOrder(address _account, uint256 _orderIndex) public view returns (
        uint256 productId,
        uint256 size,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 orderTimestamp
    ) {
        CloseOrder memory order = closeOrders[_account][_orderIndex];
        return (
            order.productId,
            order.size,
            order.isLong,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee,
            order.orderTimestamp
        );
    }

    function getOpenOrder(address _account, uint256 _orderIndex) public view returns (
        uint256 productId,
        uint256 margin,
        uint256 leverage,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 orderTimestamp
    ) {
        OpenOrder memory order = openOrders[_account][_orderIndex];
        return (
            order.productId,
            order.margin,
            order.leverage,
            order.isLong,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee,
            order.orderTimestamp
        );
    }

    function createOpenOrder(
        uint256 _productId,
        uint256 _margin,
        uint256 _leverage,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee
    ) external payable nonReentrant {
        require(_executionFee >= minExecutionFee, "OrderBook: insufficient execution fee");

        uint256 tradeFee = getTradeFeeRate(_productId, msg.sender) * _margin * _leverage / (FEE_BASE * BASE);
        if (IERC20(collateralToken).isETH()) {
            IERC20(collateralToken).uniTransferFromSenderToThis((_executionFee + _margin + tradeFee) * tokenBase / BASE);
        } else {
            require(msg.value == _executionFee * 1e18 / BASE, "OrderBook: incorrect execution fee transferred");
            IERC20(collateralToken).uniTransferFromSenderToThis((_margin + tradeFee) * tokenBase / BASE);
        }
        _createOpenOrder(
            msg.sender,
            _productId,
            _margin,
            tradeFee,
            _leverage,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold,
            _executionFee
        );
    }

    function _createOpenOrder(
        address _account,
        uint256 _productId,
        uint256 _margin,
        uint256 _tradeFee,
        uint256 _leverage,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee
    ) private {
        uint256 _orderIndex = openOrdersIndex[msg.sender];
        OpenOrder memory order = OpenOrder(
            _account,
            _productId,
            _margin,
            _leverage,
            _tradeFee,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold,
            _executionFee,
            block.timestamp
        );
        openOrdersIndex[_account] = _orderIndex + 1;
        openOrders[_account][_orderIndex] = order;
        emit CreateOpenOrder(
            _account,
            _orderIndex,
            _productId,
            _margin,
            _leverage,
            _tradeFee,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold,
            _executionFee,
            block.timestamp
        );
    }

    function updateOpenOrder(
        uint256 _orderIndex,
        uint256 _leverage,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external nonReentrant {
        OpenOrder storage order = openOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");
        if (order.leverage != _leverage) {
            uint256 margin = (order.margin + order.tradeFee) * BASE / (BASE + getTradeFeeRate(order.productId, order.account) * _leverage / 10**4);
            uint256 tradeFee = order.tradeFee + order.margin - margin;
            order.margin = margin;
            order.tradeFee = tradeFee;
            order.leverage = _leverage;
        }
        order.triggerPrice = _triggerPrice;
        order.triggerAboveThreshold = _triggerAboveThreshold;
        order.orderTimestamp = block.timestamp;

        emit UpdateOpenOrder(
            msg.sender,
            _orderIndex,
            order.productId,
            order.margin,
            order.leverage,
            order.tradeFee,
            order.isLong,
            _triggerPrice,
            _triggerAboveThreshold,
            block.timestamp
        );
    }

    function cancelOpenOrder(uint256 _orderIndex) public nonReentrant {
        OpenOrder memory order = openOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");
        require(order.orderTimestamp + minTimeCancelDelay < block.timestamp, "OrderBook: min time cancel delay not yet passed");

        delete openOrders[msg.sender][_orderIndex];

        if (IERC20(collateralToken).isETH()) {
            IERC20(collateralToken).uniTransfer(msg.sender, (order.executionFee + order.margin + order.tradeFee) * tokenBase / BASE);
        } else {
            IERC20(collateralToken).uniTransfer(msg.sender, (order.margin + order.tradeFee) * tokenBase / BASE);
            payable(msg.sender).sendValue(order.executionFee * 1e18 / BASE);
        }

        emit CancelOpenOrder(
            order.account,
            _orderIndex,
            order.productId,
            order.margin,
            order.tradeFee,
            order.leverage,
            order.isLong,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee,
            order.orderTimestamp
        );
    }

    function executeOpenOrder(address _address, uint256 _orderIndex, address payable _feeReceiver) public nonReentrant {
        OpenOrder memory order = openOrders[_address][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");
        require(
            (msg.sender == address(this) && isKeeperCall) //1. keeper通过 this.executeOpenOrder 发起的
            || isKeeper[msg.sender]                       //2. 如果是通过this.executeOpenOrder调用 msg.sender==address(this) 而iskeeper里面没有 当前合约地址，所以要用isKeeperCall这个临时变量
            || (allowPublicKeeper && order.orderTimestamp + minTimeExecuteDelay < block.timestamp), //3. 公共keeper要在一定时间之后才可以执行
            "OrderBook: min time execute delay not yet passed"
        );

    uint256 currentPrice = validatePositionOrderPrice(
            order.isLong,
            order.triggerAboveThreshold,
            order.triggerPrice,
            order.productId
        );



    delete openOrders[_address][_orderIndex];

        if (IERC20(collateralToken).isETH()) {
            IKiloPerp(kiloPerp).openPosition{value: (order.margin + order.tradeFee) * tokenBase / BASE }(_address, order.productId, order.margin, order.isLong, order.leverage);
        } else {
            IERC20(collateralToken).safeApprove(kiloPerp, 0);
            IERC20(collateralToken).safeApprove(kiloPerp, (order.margin + order.tradeFee) * tokenBase / BASE);

        IKiloPerp(kiloPerp).openPosition(_address, order.productId, order.margin, order.isLong, order.leverage);
        }


        // pay executor
        _feeReceiver.sendValue(order.executionFee * 1e18 / BASE);

        emit ExecuteOpenOrder(
            order.account,
            _orderIndex,
            order.productId,
            order.margin,
            order.leverage,
            order.tradeFee,
            order.isLong,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee,
            order.orderTimestamp,
            currentPrice
        );
    }

    function createCloseOrder(
        uint256 _productId,
        uint256 _size,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external payable nonReentrant {
        require(msg.value >= minExecutionFee * 1e18 / BASE, "OrderBook: insufficient execution fee");

        _createCloseOrder(
            msg.sender,
            _productId,
            _size,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold
        );
    }

    function _createCloseOrder(
        address _account,
        uint256 _productId,
        uint256 _size,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) private {
        uint256 _orderIndex = closeOrdersIndex[_account];
        CloseOrder memory order = CloseOrder(
            _account,
            _productId,
            _size,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold,
            msg.value * BASE / 1e18,
            block.timestamp
        );
        closeOrdersIndex[_account] = _orderIndex + 1;
        closeOrders[_account][_orderIndex] = order;

        emit CreateCloseOrder(
            _account,
            _orderIndex,
            _productId,
            _size,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold,
            msg.value,
            block.timestamp
        );
    }

    function executeCloseOrder(address _address, uint256 _orderIndex, address payable _feeReceiver) public nonReentrant {
        CloseOrder memory order = closeOrders[_address][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");
        require((msg.sender == address(this) && isKeeperCall) || isKeeper[msg.sender] || (allowPublicKeeper && order.orderTimestamp + minTimeExecuteDelay < block.timestamp),
            "OrderBook: min time execute delay not yet passed");
        (,uint256 leverage,,,,,,,) = IKiloPerp(kiloPerp).getPosition(_address, order.productId, order.isLong);
        uint256 currentPrice = validatePositionOrderPrice(
            !order.isLong,
            order.triggerAboveThreshold,
            order.triggerPrice,
            order.productId
        );

        delete closeOrders[_address][_orderIndex];
        IKiloPerp(kiloPerp).closePosition(_address, order.productId, order.size * BASE / leverage , order.isLong);
        
        // pay executor
        _feeReceiver.sendValue(order.executionFee * 1e18 / BASE);

        emit ExecuteCloseOrder(
            order.account,
            _orderIndex,
            order.productId,
            order.size,
            order.isLong,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee,
            order.orderTimestamp,
            currentPrice
        );
    }

    function cancelCloseOrder(uint256 _orderIndex) public nonReentrant {
        CloseOrder memory order = closeOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");
        require(order.orderTimestamp + minTimeCancelDelay < block.timestamp, "OrderBook: min time cancel delay not yet passed");

        delete closeOrders[msg.sender][_orderIndex];

        payable(msg.sender).sendValue(order.executionFee * 1e18 / BASE);

        emit CancelCloseOrder(
            order.account,
            _orderIndex,
            order.productId,
            order.size,
            order.isLong,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee,
            order.orderTimestamp
        );
    }

    function updateCloseOrder(
        uint256 _orderIndex,
        uint256 _size,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external nonReentrant {
        CloseOrder storage order = closeOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");

        order.size = _size;
        order.triggerPrice = _triggerPrice;
        order.triggerAboveThreshold = _triggerAboveThreshold;
        order.orderTimestamp = block.timestamp;

        emit UpdateCloseOrder(
            msg.sender,
            _orderIndex,
            order.productId,
            _size,
            order.isLong,
            _triggerPrice,
            _triggerAboveThreshold,
            block.timestamp
        );
    }

    function getTradeFeeRate(uint256 _productId, address _account) private view returns(uint256) {
        (address productToken,,uint256 fee,,,,,,) = IKiloPerp(kiloPerp).getProduct(_productId);
        return IFeeCalculator(feeCalculator).getFee(productToken, fee, _account, msg.sender);
    }

    fallback() external payable {}
    receive() external payable {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./oracle/IOracle.sol";
import "./lib/UniERC20.sol";
import "./lib/PerpLib.sol";
import "./interface/IKiloPerp.sol";
import "./interface/IFundingManager.sol";
import "./staking/IVaultReward.sol";
import "hardhat/console.sol";
contract KiloPerp is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using UniERC20 for IERC20;
    // All amounts are stored with 8 decimals

    // Structs

    struct Vault {
        // 32 bytes
        uint128 cap; // Maximum capacity. 16 bytes
        uint128 balance; // 16 bytes
        // 32 bytes
        uint96 staked; // Total staked by users. 12 bytes
        uint96 shares; // Total ownership shares. 12 bytes
        uint64 stakingPeriod; // Time required to lock stake (seconds). 8 bytes
    }

    struct Stake {
        // 32 bytes
        address owner; // 20 bytes
        uint96 amount; // 12 bytes
        // 32 bytes
        uint128 shares; //股权比例 16 bytes
        uint128 timestamp; // 16 bytes
    }

    struct Product {
        // 32 bytes
        address productToken;//token
        uint72 maxLeverage;//最大杠杆
        uint16 fee; // In bps. 0.5% = 50.
        bool isActive;//是否可用
        // 32 bytes
        uint64 openInterestLong;//多仓价值
        uint64 openInterestShort;//空仓价值
        uint32 minPriceChange; //价格最小变动，才能平仓 1.5%, the minimum oracle price up change for trader to close trade with profit
        uint32 weight; //TODO share of the max exposure
        uint64 reserve; //TODO Virtual reserve used to calculate slippage
    }

    struct Position {
        // 32 bytes
        uint64 productId;//币对id
        uint64 leverage;//杠杆
        uint64 price;//成交价格
        uint64 oraclePrice;//成交时oracle 价格
        // 32 bytes
        uint128 margin;//保证金
        int128 funding;//资金费率
        // 32 bytes
        address owner;
        bool isLong;//多空
        bool isNextPrice;
        uint80 timestamp;
    }

    // Variables

    address public owner;
    address public guardian;
    address public gov;
    address private token;
    address public oracle;
    address public protocolRewardDistributor;//协议奖励操作地址 20%
    address public kiloRewardDistributor;//代币奖励操作地址 30%
    address public vaultRewardDistributor;//金库奖励操作地址 50%
    address public vaultTokenReward;//代币金库奖励操作地址
    address public feeCalculator;
    address public fundingManager;
    uint256 private tokenBase;
    uint256 public minMargin;//开仓最小保证金
    uint256 public protocolRewardRatio = 2000;  //协议奖励比例，手续和清算费 20%
    uint256 public kiloRewardRatio = 3000;  //kilo奖励 30%
    uint256 public maxShift = 0.003e8; //TODO max shift (shift is used adjust the price to balance the longs and shorts)
    uint256 public minProfitTime = 6 hours; //TODO 盈利仓位必须持有这么长时间？ the time window where minProfit is effective
    uint256 public totalWeight; // TODO total exposure weights of all product
    uint256 public exposureMultiplier = 10000; //TODO exposure multiplier
    uint256 public utilizationMultiplier = 10000; //金库利用率乘数 TODO exposure multiplier
    uint256 public maxExposureMultiplier = 3; //TODO total open interest of a product should not exceed maxExposureMultiplier * maxExposure
    uint256 private liquidationBounty = 5000; //清算奖励比例 In bps. 5000 = 50%
    uint256 public liquidationThreshold = 8000; //清算门槛 In bps. 8000 = 80%
    uint256 private pendingProtocolReward; //20% protocol reward collected
    uint256 private pendingKiloReward; //30% kilo reward collected
    uint256 private pendingVaultReward; //50% vault reward collected
    uint256 public totalOpenInterest;//总开仓名义价值，平台级别限制
    uint256 public shiftDivider = 3;//TODO
    bool private canUserStake = true;//用户是否可以stake
    bool private allowPublicLiquidator = false;//是否公共清算人操作
    bool private isTradeEnabled = true;//交易是否暂停
    bool private isManagerOnlyForOpen = false;//只允许管理员开仓
    bool private isManagerOnlyForClose = false;//只允许管理员平仓
    Vault private vault;//金库
    uint256 private constant BASE = 10**8;

    mapping(uint256 => Product) private products;//产品信息
    mapping(address => Stake) private stakes;//用户stake信息
    mapping(uint256 => Position) private positions;//用户仓位
    mapping (address => bool) public liquidators;//内部清算人
    mapping (address => bool) public nextPriceManagers;//TODO
    mapping (address => bool) public managers;//管理员
    // Events

    event Staked(
        address indexed user,
        uint256 amount,
        uint256 shares
    );
    event Redeemed(
        address indexed user,
        address indexed receiver,
        uint256 amount,
        uint256 shares,
        uint256 shareBalance,
        bool isFullRedeem
    );
    event NewPosition(
        uint256 indexed positionId,
        address indexed user,
        uint256 indexed productId,
        bool isLong,
        uint256 price,
        uint256 oraclePrice,
        uint256 margin,
        uint256 leverage,
        uint256 fee,
        bool isNextPrice,
        int256 funding
    );

    event AddMargin(
        uint256 indexed positionId,
        address indexed sender,
        address indexed user,
        uint256 margin,
        uint256 newMargin,
        uint256 newLeverage
    );
    event ClosePosition(
        uint256 indexed positionId,
        address indexed user,
        uint256 indexed productId,
        uint256 price,
        uint256 entryPrice,
        uint256 margin,
        uint256 leverage,
        uint256 fee,
        int256 pnl,
        int256 fundingPayment,
        bool wasLiquidated
    );
    event PositionLiquidated(
        uint256 indexed positionId,
        address indexed liquidator,
        uint256 liquidatorReward,
        uint256 remainingReward
    );
    event ProtocolRewardDistributed(
        address to,
        uint256 amount
    );
    event KiloRewardDistributed(
        address to,
        uint256 amount
    );
    event VaultRewardDistributed(
        address to,
        uint256 amount
    );
    event VaultUpdated(
        Vault vault
    );
    event ProductAdded(
        uint256 productId,
        Product product
    );
    event ProductUpdated(
        uint256 productId,
        Product product
    );
    event AddressesSet(
        address oracle,
        address feeCalculator,
        address fundingManager
    );
    event OwnerUpdated(
        address newOwner
    );
    event GuardianUpdated(
        address newGuardian
    );
    event GovUpdated(
        address newGov
    );

    // Constructor

    constructor(address _token, uint256 _tokenBase, address _oracle, address _feeCalculator, address _fundingManager) {
        owner = msg.sender;
        guardian = msg.sender;
        gov = msg.sender;
        token = _token;
        tokenBase = _tokenBase;
        oracle = _oracle;
        feeCalculator = _feeCalculator;
        fundingManager = _fundingManager;
    }

    // Methods
    //stake
    function stake(uint256 amount, address user) external payable nonReentrant {
        //校验用户和状态
        require((canUserStake || msg.sender == owner) && (msg.sender == user || _validateManager(user)), "!stake");
        //更新下当前用户stake奖励
        IVaultReward(vaultRewardDistributor).updateReward(user);

        if (vaultTokenReward != address(0)) {
            //TODO vaultRewardDistributor  vaultTokenReward 区别? updateReward更新2次？
            IVaultReward(vaultTokenReward).updateReward(user);
        }

        //用户资产transfer
        IERC20(token).uniTransferFromSenderToThis(amount * tokenBase / BASE);
        //校验是否超出cap
        require(uint256(vault.staked) + amount <= uint256(vault.cap), "!cap");
        //计算股权份额
        uint256 shares = vault.staked > 0 ? amount * uint256(vault.shares) / uint256(vault.balance) : amount;
        //balance = balance + amount
        vault.balance += uint128(amount);
        //staked = staked + amount
        vault.staked += uint96(amount);
        //shares = shares + shares
        vault.shares += uint96(shares);

        //记录用户stake数据
        if (stakes[user].amount == 0) {
            stakes[user] = Stake({
                owner: user,
                amount: uint96(amount),
                shares: uint128(shares),
                timestamp: uint128(block.timestamp)
            });
        } else {
            stakes[user].amount += uint96(amount);
            stakes[user].shares += uint128(shares);
            if (!_validateManager(user)) {
                stakes[user].timestamp = uint128(block.timestamp);
            }
        }

        emit Staked(
            user,
            amount,
            shares
        );

    }

    //赎回
    function redeem(
        address user,
        uint256 shares,
        address receiver
    ) external {
        //赎回检查
        require(shares <= uint256(vault.shares) && (user == msg.sender || _validateManager(user)), "!redeem");

        //收集reward
        IVaultReward(vaultRewardDistributor).updateReward(user);
        if (vaultTokenReward != address(0)) {
            IVaultReward(vaultTokenReward).updateReward(user);
        }

        //获取用户stake数据
        Stake storage _stake = stakes[user];
        //是否全部redeem
        bool isFullRedeem = shares >= uint256(_stake.shares);
        if (isFullRedeem) {
            shares = uint256(_stake.shares);
        }
        //质押必须超出一定的时间，否则拒绝redeem
        uint256 timeDiff = block.timestamp - uint256(_stake.timestamp);
        require(timeDiff > uint256(vault.stakingPeriod), "!period");

        //计算股权金额
        uint256 shareBalance = shares * uint256(vault.balance) / uint256(vault.shares);
        //计算原始金额
        uint256 amount = shares * _stake.amount / uint256(_stake.shares);

        //vault 动账，减掉redeem部分
        _stake.amount -= uint96(amount);
        _stake.shares -= uint128(shares);
        vault.staked -= uint96(amount);
        vault.shares -= uint96(shares);
        vault.balance -= uint128(shareBalance);
        //检查整体仓位价值是否超出金库价值，如果不超出则不能redeem
        require(totalOpenInterest <= uint256(vault.balance) * utilizationMultiplier / (10**4), "!utilized");

        // 如果全部redeem，清理该用户数据
        if (isFullRedeem) {
            delete stakes[user];
        }
        //redeem to user
        IERC20(token).uniTransfer(receiver, shareBalance * tokenBase / BASE);

        emit Redeemed(
            user,
            receiver,
            amount,
            shares,
            shareBalance,
            isFullRedeem
        );
    }

    function openPosition(
        address user,
        uint256 productId,
        uint256 margin,
        bool isLong,
        uint256 leverage
    ) public payable nonReentrant {
        //校验是否是管理员，或者是否允许非管理员调用
        require(_validateManager(user), "!allowed");
        //是否允许交易
        require(isTradeEnabled, "!enabled");
        // Check params
        //检查margin是否小于最小保证金
        require(margin >= minMargin && margin < type(uint64).max, "!margin");
        //杠杆倍数必须>=1
        require(leverage >= 1 * BASE, "!lev");

        // Check product
        Product storage product = products[productId];
        require(product.isActive, "!active");
        require(leverage <= uint256(product.maxLeverage), "!max-lev");

        //计算交易手续费
        uint256 tradeFee = PerpLib._getTradeFee(margin, leverage, uint256(product.fee), product.productToken, user, msg.sender, feeCalculator);
        IERC20(token).uniTransferFromSenderToThis((margin + tradeFee) * tokenBase / BASE);
        //手续费奖励分成
        _updatePendingRewards(tradeFee);

        //!!!
        uint256 price = _calculatePrice(product.productToken, isLong, product.openInterestLong,
            product.openInterestShort, uint256(vault.balance) * uint256(product.weight) * exposureMultiplier / uint256(totalWeight) / (10**4),
            uint256(product.reserve), margin * leverage / BASE);

        //!!!
        _updateFundingAndOpenInterest(productId, margin * leverage / BASE, isLong, true);
        int256 funding = IFundingManager(fundingManager).getFunding(productId);

        Position storage position = positions[getPositionId(user, productId, isLong)];
        //重新计算仓位价格，资金费率，杠杆和保证金
        if (position.margin > 0) {
            price = (uint256(position.margin) * position.leverage * uint256(position.price) + margin * leverage * price) /
            (uint256(position.margin) * position.leverage + margin * leverage);
            funding = (int256(uint256(position.margin)) * int256(uint256(position.leverage)) * int256(position.funding) + int256(margin * leverage) * funding) /
            (int256(uint256(position.margin)) * int256(uint256(position.leverage)) + int256(margin * leverage));
            leverage = (uint256(position.margin) * uint256(position.leverage) + margin * leverage) / (uint256(position.margin) + margin);
            margin = uint256(position.margin) + margin;
        }
        //save
        positions[getPositionId(user, productId, isLong)] = Position({
            owner: user,
            productId: uint64(productId),
            margin: uint128(margin),
            leverage: uint64(leverage),
            price: uint64(price),
            oraclePrice: uint64(IOracle(oracle).getPrice(product.productToken)),
            timestamp: uint80(block.timestamp),
            isLong: isLong,
            // if no existing position, isNextPrice depends on if sender is a nextPriceManager,
            // else it is false if either existing position's isNextPrice is false or the current new position sender is not a nextPriceManager
            isNextPrice: position.margin == 0 ? nextPriceManagers[msg.sender] : (!position.isNextPrice ? false : nextPriceManagers[msg.sender]),
            funding: int128(funding)
        });
        emit NewPosition(
            getPositionId(user, productId, isLong),
            user,
            productId,
            isLong,
            price,
            IOracle(oracle).getPrice(product.productToken),
            margin,
            leverage,
            tradeFee,
            position.margin == 0 ? nextPriceManagers[msg.sender] : (!position.isNextPrice ? false : nextPriceManagers[msg.sender]),
            funding
        );
    }

    // Add margin to Position with positionId
    function addMargin(uint256 positionId, uint256 margin) external payable nonReentrant {

        IERC20(token).uniTransferFromSenderToThis(margin * tokenBase / BASE);

        // Check params
        require(margin >= minMargin, "!margin");

        // Check position
        Position storage position = positions[positionId];
        require(msg.sender == position.owner, "!allowed");

        // New position params
        uint256 newMargin = uint256(position.margin) + margin;
        uint256 newLeverage = uint256(position.leverage) * uint256(position.margin) / newMargin;
        require(newLeverage >= 1 * BASE, "!low-lev");

        position.margin = uint128(newMargin);
        position.leverage = uint64(newLeverage);

        emit AddMargin(
            positionId,
            msg.sender,
            position.owner,
            margin,
            newMargin,
            newLeverage
        );

    }

    function closePosition(
        address user,
        uint256 productId,
        uint256 margin,
        bool isLong
    ) external {
        return closePositionWithId(getPositionId(user, productId, isLong), margin);
    }

    // Closes position from Position with id = positionId
    function closePositionWithId(
        uint256 positionId,
        uint256 margin
    ) public nonReentrant {
        // Check position
        Position storage position = positions[positionId];
        require(_validateManager(position.owner), "!close");

        // Check product
        Product storage product = products[uint256(position.productId)];

        bool isFullClose;
        if (margin >= uint256(position.margin)) {
            margin = uint256(position.margin);
            isFullClose = true;
        }

        uint256 price = _calculatePrice(product.productToken, !position.isLong, product.openInterestLong, product.openInterestShort,
            getMaxExposure(uint256(product.weight)), uint256(product.reserve), margin * position.leverage / BASE);

        _updateFundingAndOpenInterest(uint256(position.productId), margin * uint256(position.leverage) / BASE, position.isLong, false);
        int256 fundingPayment = PerpLib._getFundingPayment(fundingManager, position.isLong, position.productId, position.leverage, margin, position.funding);
        int256 pnl = PerpLib._getPnl(position.isLong, uint256(position.price), uint256(position.leverage), margin, price) - fundingPayment;
        bool isLiquidatable;
        if (pnl < 0 && uint256(-1 * pnl) >= margin * liquidationThreshold / (10**4)) {
            margin = uint256(position.margin);
            pnl = -1 * int256(uint256(position.margin));
            isLiquidatable = true;
        } else {
            // front running protection: if oracle price up change is smaller than threshold and minProfitTime has not passed
            // and either open or close order is not using next oracle price, the pnl is be set to 0
            if (pnl > 0 && !PerpLib._canTakeProfit(position.isLong,uint256(position.timestamp),uint256(position.oraclePrice),
                IOracle(oracle).getPrice(product.productToken),product.minPriceChange, minProfitTime) && (!position.isNextPrice || !nextPriceManagers[msg.sender])) {
                pnl = 0;
            }
        }

        uint256 totalFee = _updateVaultAndGetFee(pnl, position, margin, uint256(product.fee), product.productToken);

        emit ClosePosition(
            positionId,
            position.owner,
            uint256(position.productId),
            price,
            uint256(position.price),
            margin,
            uint256(position.leverage),
            totalFee,
            pnl,
            fundingPayment,
            isLiquidatable
        );

        if (isFullClose) {
            delete positions[positionId];
        } else {
            position.margin -= uint128(margin);
        }
    }

    function _updateVaultAndGetFee(
        int256 pnl,
        Position memory position,
        uint256 margin,
        uint256 fee,
        address productToken
    ) private returns(uint256) {
        uint256 totalFee = PerpLib._getTradeFee(margin, uint256(position.leverage), fee, productToken, position.owner, msg.sender, feeCalculator);
        int256 remainMargin = int256(margin) + pnl - int256(totalFee);
        if (remainMargin <= 0) { //margin不够亏损，全部贡献给国库了
            vault.balance += uint128(margin);
            return totalFee;
        } else {
            if (pnl >= 0) {
                vault.balance -= uint128(uint256(pnl));
            } else {
                vault.balance += uint128(uint256(-1*pnl));
            }
            IERC20(token).uniTransfer(position.owner, uint256(remainMargin) * tokenBase / BASE);
        }
        _updatePendingRewards(totalFee);
        return totalFee;

//        uint256 totalFee = PerpLib._getTradeFee(margin, uint256(position.leverage), fee, productToken, position.owner, msg.sender, feeCalculator);
//        int256 pnlAfterFee = pnl - int256(totalFee);
//        // Update vault
//        if (pnlAfterFee < 0) {
//            uint256 _pnlAfterFee = uint256(-1 * pnlAfterFee);
//            if (_pnlAfterFee < margin) {
//                IERC20(token).uniTransfer(position.owner, (margin - _pnlAfterFee) * tokenBase / BASE);
//                vault.balance += uint128(_pnlAfterFee);
//            } else {
//                vault.balance += uint128(margin);
//                return totalFee;
//            }
//
//        } else {
//            uint256 _pnlAfterFee = uint256(pnlAfterFee);
//            // Check vault
//            require(uint256(vault.balance) >= _pnlAfterFee, "!bal");
//            vault.balance -= uint128(_pnlAfterFee);
//
//            IERC20(token).uniTransfer(position.owner, (margin + _pnlAfterFee) * tokenBase / BASE);
//        }
//
//        _updatePendingRewards(totalFee);
//        vault.balance -= uint128(totalFee);
//
//        return totalFee;
    }

    // Liquidate positionIds
    function liquidatePositions(uint256[] calldata positionIds) external {
        require(liquidators[msg.sender] || allowPublicLiquidator, "!liquidator");

        uint256 totalLiquidatorReward;
        for (uint256 i = 0; i < positionIds.length; i++) {
            uint256 positionId = positionIds[i];
            uint256 liquidatorReward = liquidatePosition(positionId);
            totalLiquidatorReward = totalLiquidatorReward + liquidatorReward;
        }
        if (totalLiquidatorReward > 0) {
            IERC20(token).uniTransfer(msg.sender, totalLiquidatorReward * tokenBase / BASE);
        }
    }


    function liquidatePosition(
        uint256 positionId
    ) private returns(uint256 liquidatorReward) {
        Position storage position = positions[positionId];
        if (position.productId == 0) {
            return 0;
        }
        Product storage product = products[uint256(position.productId)];
        uint256 price = IOracle(oracle).getPrice(product.productToken); // use oracle price for liquidation

        uint256 remainingReward;
        _updateFundingAndOpenInterest(uint256(position.productId), uint256(position.margin) * uint256(position.leverage) / BASE, position.isLong, false);
        int256 fundingPayment = PerpLib._getFundingPayment(fundingManager, position.isLong, position.productId, position.leverage, position.margin, position.funding);
        int256 pnl = PerpLib._getPnl(position.isLong, position.price, position.leverage, position.margin, price) - fundingPayment;
        if (pnl >= 0 || uint256(-1 * pnl) < uint256(position.margin) * liquidationThreshold / (10**4)) {
            return 0;
        }
        if (uint256(position.margin) > uint256(-1*pnl)) {
            uint256 _pnl = uint256(-1*pnl);
            liquidatorReward = (uint256(position.margin) - _pnl) * liquidationBounty / (10**4);
            remainingReward = uint256(position.margin) - _pnl - liquidatorReward;
            _updatePendingRewards(remainingReward);
            vault.balance += uint128(_pnl);
        } else {
            vault.balance += uint128(position.margin);
        }

        emit ClosePosition(
            positionId,
            position.owner,
            uint256(position.productId),
            price,
            uint256(position.price),
            uint256(position.margin),
            uint256(position.leverage),
            0,
            -1*int256(uint256(position.margin)),
            fundingPayment,
            true
        );

        delete positions[positionId];

        emit PositionLiquidated(
            positionId,
            msg.sender,
            liquidatorReward,
            remainingReward
        );

        return liquidatorReward;
    }
    //!!!
    function _updatePendingRewards(uint256 reward) private {
        //20%
        pendingProtocolReward = pendingProtocolReward + (reward * protocolRewardRatio / (10**4));
        //30%
        pendingKiloReward = pendingKiloReward + (reward * kiloRewardRatio / (10**4));
        //50%
        pendingVaultReward = pendingVaultReward + (reward * (10**4 - protocolRewardRatio - kiloRewardRatio) / (10**4));
    }
    //更新资金费率和仓位价值，校验当前订单是否可以正常执行 检查限制
    function _updateFundingAndOpenInterest(uint256 productId, uint256 amount, bool isLong, bool isIncrease) private {
        IFundingManager(fundingManager).updateFunding(productId);
        Product storage product = products[productId];
        //增加仓位
        if (isIncrease) {
            //总仓位价值增加
            totalOpenInterest = totalOpenInterest + amount;
            //获取风险敞口
            uint256 maxExposure = getMaxExposure(uint256(product.weight));
            //总仓位价值必须小于金库balance
            require(totalOpenInterest <= uint256(vault.balance) * utilizationMultiplier / 10**4 &&
                uint256(product.openInterestLong) + uint256(product.openInterestShort) + amount < maxExposureMultiplier * maxExposure, "!maxOI");
            if (isLong) {
                product.openInterestLong = product.openInterestLong + uint64(amount);
                require(uint256(product.openInterestLong) <= uint256(maxExposure) + uint256(product.openInterestShort), "!exposure-long");
            } else {
                product.openInterestShort = product.openInterestShort + uint64(amount);
                require(uint256(product.openInterestShort) <= uint256(maxExposure) + uint256(product.openInterestLong), "!exposure-short");
            }
        } else {
            //减少仓位
            totalOpenInterest = totalOpenInterest - amount;
            if (isLong) {
                if (uint256(product.openInterestLong) >= amount) {
                    product.openInterestLong -= uint64(amount);
                } else {
                    product.openInterestLong = 0;
                }
            } else {
                if (uint256(product.openInterestShort) >= amount) {
                    product.openInterestShort -= uint64(amount);
                } else {
                    product.openInterestShort = 0;
                }
            }
        }
    }

    function _validateManager(address account) private view returns(bool) {
        return managers[msg.sender];
    }

    function distributeProtocolReward() external returns(uint256) {
        require(msg.sender == protocolRewardDistributor, "!dist");
        uint256 _pendingProtocolReward = pendingProtocolReward * tokenBase / BASE;
        if (pendingProtocolReward > 0) {
            pendingProtocolReward = 0;
            IERC20(token).uniTransfer(protocolRewardDistributor, _pendingProtocolReward);
            emit ProtocolRewardDistributed(protocolRewardDistributor, _pendingProtocolReward);
        }
        return _pendingProtocolReward;
    }

    function distributeKiloReward() external returns(uint256) {
        require(msg.sender == kiloRewardDistributor, "!dist");
        uint256 _pendingKiloReward = pendingKiloReward * tokenBase / BASE;
        if (pendingKiloReward > 0) {
            pendingKiloReward = 0;
            IERC20(token).uniTransfer(kiloRewardDistributor, _pendingKiloReward);
            emit KiloRewardDistributed(kiloRewardDistributor, _pendingKiloReward);
        }
        return _pendingKiloReward;
    }

    function distributeVaultReward() external returns(uint256) {
        require(msg.sender == vaultRewardDistributor, "!dist");
        uint256 _pendingVaultReward = pendingVaultReward * tokenBase / BASE;
        if (pendingVaultReward > 0) {
            pendingVaultReward = 0;
            IERC20(token).uniTransfer(vaultRewardDistributor, _pendingVaultReward);
            emit VaultRewardDistributed(vaultRewardDistributor, _pendingVaultReward);
        }
        return _pendingVaultReward;
    }

    // Getters

    function getPendingKiloReward() external view returns(uint256) {
        return pendingKiloReward * tokenBase / BASE;
    }

    function getPendingProtocolReward() external view returns(uint256) {
        return pendingProtocolReward * tokenBase / BASE;
    }

    function getPendingVaultReward() external view returns(uint256) {
        return pendingVaultReward * tokenBase / BASE;
    }

    function getVault() external view returns(Vault memory) {
        return vault;
    }

    function getProduct(uint256 productId) external view returns (
        address,uint256,uint256,bool,uint256,uint256,uint256,uint256,uint256
    ) {
        Product memory product = products[productId];
        return (
            product.productToken,
            uint256(product.maxLeverage),
            uint256(product.fee),
            product.isActive,
            uint256(product.openInterestLong),
            uint256(product.openInterestShort),
            uint256(product.minPriceChange),
            uint256(product.weight),
            uint256(product.reserve)
        );
    }

    function getPositionId(
        address account,
        uint256 productId,
        bool isLong
    ) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(account, productId, isLong)));
    }

    function getPosition(
        address account,
        uint256 productId,
        bool isLong
    ) external view returns (
        uint256,uint256,uint256,uint256,uint256,address,uint256,bool,int256
    ) {
        Position memory position = positions[getPositionId(account, productId, isLong)];
        return(
            uint256(position.productId),
            uint256(position.leverage),
            uint256(position.price),
            uint256(position.oraclePrice),
            uint256(position.margin),
            position.owner,
            uint256(position.timestamp),
            position.isLong,
            position.funding
        );
    }

    function getPositions(uint256[] calldata positionIds) external view returns(Position[] memory _positions) {
        uint256 length = positionIds.length;
        _positions = new Position[](length);
        for (uint256 i = 0; i < length; i++) {
            _positions[i] = positions[positionIds[i]];
        }
    }

    function getMaxExposure(uint256 productWeight) public view returns(uint256) {
        return uint256(vault.balance) * productWeight * exposureMultiplier / uint256(totalWeight) / (10**4);
    }

    function getTotalShare() external view returns(uint256) {
        return uint256(vault.shares);
    }

    function getShare(address stakeOwner) external view returns(uint256) {
        return uint256(stakes[stakeOwner].shares);
    }

    function getStake(address stakeOwner) external view returns(Stake memory) {
        return stakes[stakeOwner];
    }

    // Private methods
    //TODO
    function _calculatePrice(
        address productToken,
        bool isLong,
        uint256 openInterestLong,
        uint256 openInterestShort,
        uint256 maxExposure,
        uint256 reserve,
        uint256 amount
    ) private view returns(uint256) {
        uint256 oraclePrice = isLong ? IOracle(oracle).getPrice(productToken, true) : IOracle(oracle).getPrice(productToken, false);
        int256 shift = (int256(openInterestLong) - int256(openInterestShort)) * int256(maxShift) / int256(maxExposure);
        if (isLong) {
            uint256 slippage = (reserve * reserve / (reserve - amount) - reserve) * BASE / amount;
            slippage = shift >= 0 ? slippage + uint256(shift) : slippage - (uint256(-1 * shift) / shiftDivider);
            return oraclePrice * slippage / BASE;
        } else {
            uint256 slippage = (reserve - (reserve * reserve) / (reserve + amount)) * BASE / amount;
            slippage = shift >= 0 ? slippage + (uint256(shift) / shiftDivider) : slippage - uint256(-1 * shift);
            return oraclePrice * slippage / BASE;
        }
    }

    // Owner methods

    function updateVault(Vault memory _vault) external onlyOwner {
        require(_vault.cap > 0 && _vault.stakingPeriod > 0 && _vault.stakingPeriod < 30 days, "!allowed");

        vault.cap = _vault.cap;
        vault.stakingPeriod = _vault.stakingPeriod;

        emit VaultUpdated(vault);
    }

    function addProduct(uint256 productId, Product memory _product) external onlyOwner {
        require(productId > 0);
        Product memory product = products[productId];

        require(product.maxLeverage == 0 && _product.maxLeverage > 1 * BASE && _product.productToken != address(0));

        products[productId] = Product({
            productToken: _product.productToken,
            maxLeverage: _product.maxLeverage,
            fee: _product.fee,
            isActive: true,
            openInterestLong: 0,
            openInterestShort: 0,
            minPriceChange: _product.minPriceChange,
            weight: _product.weight,
            reserve: _product.reserve
        });
        totalWeight = totalWeight + _product.weight;

        emit ProductAdded(productId, products[productId]);
    }

    function updateProduct(uint256 productId, Product memory _product) external onlyOwner {
        require(productId > 0);
        Product storage product = products[productId];

        require(product.maxLeverage > 0 && _product.maxLeverage >= 1 * BASE && _product.productToken != address(0));

        product.productToken = _product.productToken;
        product.maxLeverage = _product.maxLeverage;
        product.fee = _product.fee;
        product.isActive = _product.isActive;
        product.minPriceChange = _product.minPriceChange;
        totalWeight = totalWeight - product.weight + _product.weight;
        product.weight = _product.weight;
        product.reserve = _product.reserve;

        emit ProductUpdated(productId, product);

    }

    function setDistributors(
        address _protocolRewardDistributor,
        address _kiloRewardDistributor,
        address _vaultRewardDistributor,
        address _vaultTokenReward
    ) external onlyOwner {
        protocolRewardDistributor = _protocolRewardDistributor;
        kiloRewardDistributor = _kiloRewardDistributor;
        vaultRewardDistributor = _vaultRewardDistributor;
        vaultTokenReward = _vaultTokenReward;
    }

    function setManager(address _manager, bool _isActive) external onlyOwner {
        managers[_manager] = _isActive;
    }

    function setRewardRatio(uint256 _protocolRewardRatio, uint256 _kiloRewardRatio) external onlyOwner {
        require(_protocolRewardRatio + _kiloRewardRatio <= 10000);
        protocolRewardRatio = _protocolRewardRatio;
        kiloRewardRatio = _kiloRewardRatio;
    }

    function setMinMargin(uint256 _minMargin) external onlyOwner {
        minMargin = _minMargin;
    }

    function setTradeEnabled(bool _isTradeEnabled) external {
        require(msg.sender == owner || managers[msg.sender]);
        isTradeEnabled = _isTradeEnabled;
    }

    function setParameters(
        uint256 _maxShift,
        uint256 _minProfitTime,
        bool _canUserStake,
        bool _allowPublicLiquidator,
        bool _isManagerOnlyForOpen,
        bool _isManagerOnlyForClose,
        uint256 _exposureMultiplier,
        uint256 _utilizationMultiplier,
        uint256 _maxExposureMultiplier,
        uint256 _liquidationBounty,
        uint256 _liquidationThreshold,
        uint256 _shiftDivider
    ) external onlyOwner {
        require(_maxShift <= 0.01e8 && _minProfitTime <= 24 hours && _shiftDivider > 0 && _liquidationThreshold > 5000 && _maxExposureMultiplier > 0);
        maxShift = _maxShift;
        minProfitTime = _minProfitTime;
        canUserStake = _canUserStake;
        allowPublicLiquidator = _allowPublicLiquidator;
        isManagerOnlyForOpen = _isManagerOnlyForOpen;
        isManagerOnlyForClose = _isManagerOnlyForClose;
        exposureMultiplier = _exposureMultiplier;
        utilizationMultiplier = _utilizationMultiplier;
        maxExposureMultiplier = _maxExposureMultiplier;
        liquidationBounty = _liquidationBounty;
        liquidationThreshold = _liquidationThreshold;
        shiftDivider = _shiftDivider;
    }

    function setAddresses(address _oracle, address _feeCalculator, address _fundingManager) external onlyOwner {
        oracle = _oracle;
        feeCalculator = _feeCalculator;
        fundingManager = _fundingManager;
        emit AddressesSet(_oracle, _feeCalculator, _fundingManager);
    }

    function setLiquidator(address _liquidator, bool _isActive) external onlyOwner {
        liquidators[_liquidator] = _isActive;
    }

    function setNextPriceManager(address _nextPriceManager, bool _isActive) external onlyOwner {
        nextPriceManagers[_nextPriceManager] = _isActive;
    }

    function setOwner(address _owner) external onlyGov {
        owner = _owner;
        emit OwnerUpdated(_owner);
    }

    function setGuardian(address _guardian) external onlyGov {
        guardian = _guardian;
        emit GuardianUpdated(_guardian);
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
        emit GovUpdated(_gov);
    }

    function pauseTrading() external {
        require(msg.sender == guardian, "!guard");
        isTradeEnabled = false;
        canUserStake = false;
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "!owner");
    }

    modifier onlyGov() {
        _onlyGov();
        _;
    }

    function _onlyGov() private view {
        require(msg.sender == gov, "!gov");
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    function getPrice(address feed) external view returns (uint256);
    function getPrice(address token, bool isMax) external view returns (uint256);
    function getLastNPrices(address token, uint256 n) external view returns(uint256[] memory);
    function setPrices(address[] memory tokens, uint256[] memory prices) external;
}

// SPDX-License-Identifier: MIT

// Originally: https://github.com/CryptoManiacsZone/mooniswap/blob/master/contracts/libraries/UniERC20.sol

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library UniERC20 {
    using SafeERC20 for IERC20;

    function isETH(IERC20 token) internal pure returns (bool) {
        return (address(token) == address(0));
    }

    function uniBalanceOf(IERC20 token, address account) internal view returns (uint256) {
        if (isETH(token)) {
            return account.balance;
        } else {
            return token.balanceOf(account);
        }
    }

    function uniTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (isETH(token)) {
                (bool success, ) = payable(to).call{value: amount}("");
                require(success, "Transfer failed");
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    function uniTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                require(msg.value >= amount, "UniERC20: not enough value");
                if (msg.value > amount) {
                    // Return remainder if exist
                    uint256 refundAmount = msg.value - amount;
                    (bool success, ) = from.call{value: refundAmount}("");
                    require(success, "Transfer failed");
                }
            } else {
                token.safeTransferFrom(from, to, amount);
            }
        }
    }

//    function uniTransferFromSenderToThis(IERC20 token, uint256 amount) internal {
//        uniTransferFrom(token, msg.sender, address(this), amount);
//    }

    function uniTransferFromSenderToThis(IERC20 token, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                require(msg.value >= amount, "UniERC20: not enough value");
                if (msg.value > amount) {
                    // Return remainder if exist
                    uint256 refundAmount = msg.value - amount;
                    (bool success, ) = msg.sender.call{value: refundAmount}("");
                    require(success, "Transfer failed");
                }
            } else {
                token.safeTransferFrom(msg.sender, address(this), amount);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFeeCalculator {
    function getFee(address token, uint256 productFee, address user, address sender) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Governable {
    address public gov;

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IKiloPerp {
    function getTotalShare() external view returns(uint256);
    function getShare(address stakeOwner) external view returns(uint256);
    function distributeProtocolReward() external returns(uint256);
    function distributeKiloReward() external returns(uint256);
    function distributeVaultReward() external returns(uint256);
    function getPendingKiloReward() external view returns(uint256);
    function getPendingProtocolReward() external view returns(uint256);
    function getPendingVaultReward() external view returns(uint256);
    function stake(uint256 amount, address user) external payable;
    function redeem(uint256 shares) external;
    function openPosition(
        address user,
        uint256 productId,
        uint256 margin,
        bool isLong,
        uint256 leverage
    ) external payable;
    function closePositionWithId(
        uint256 positionId,
        uint256 margin
    ) external;
    function closePosition(
        address user,
        uint256 productId,
        uint256 margin,
        bool isLong
    ) external;
    function liquidatePositions(uint256[] calldata positionIds) external;
    function getProduct(uint256 productId) external view returns (
        address,uint256,uint256,bool,uint256,uint256,uint256,uint256,uint256);
    function getPosition(
        address account,
        uint256 productId,
        bool isLong
    ) external view returns (uint256,uint256,uint256,uint256,uint256,address,uint256,bool,int256);
    function getMaxExposure(uint256 productWeight) external view returns(uint256);
    function getCumulativeFunding(uint256 _productId) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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

interface IVaultReward {
    function updateReward(address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../oracle/IOracle.sol";
import "../perp/IFeeCalculator.sol";
import "../interface/IFundingManager.sol";

library PerpLib {
    uint256 private constant BASE = 10**8;
    uint256 private constant FUNDING_BASE = 10**12;

    function _canTakeProfit(
        bool isLong,
        uint256 positionTimestamp,
        uint256 positionOraclePrice,
        uint256 oraclePrice,
        uint256 minPriceChange,
        uint256 minProfitTime
    ) internal view returns(bool) {
        if (block.timestamp > positionTimestamp + minProfitTime) {
            return true;
        } else if (isLong && oraclePrice > positionOraclePrice * (10**4 + minPriceChange) / (10**4)) {
            return true;
        } else if (!isLong && oraclePrice < positionOraclePrice * (10**4 - minPriceChange) / (10**4)) {
            return true;
        }
        return false;
    }

    function _getPnl(
        bool isLong,
        uint256 positionPrice,
        uint256 positionLeverage,
        uint256 margin,
        uint256 price
    ) internal pure returns(int256 _pnl) {
        bool pnlIsNegative;
        uint256 pnl;
        if (isLong) {
            if (price >= positionPrice) {
                pnl = margin * positionLeverage * (price - positionPrice) / positionPrice / BASE;
            } else {
                pnl = margin * positionLeverage * (positionPrice - price) / positionPrice / BASE;
                pnlIsNegative = true;
            }
        } else {
            if (price > positionPrice) {
                pnl = margin * positionLeverage * (price - positionPrice) / positionPrice / BASE;
                pnlIsNegative = true;
            } else {
                pnl = margin * positionLeverage * (positionPrice - price) / positionPrice / BASE;
            }
        }

        if (pnlIsNegative) {
            _pnl = -1 * int256(pnl);
        } else {
            _pnl = int256(pnl);
        }

        return _pnl;
    }

    function _getFundingPayment(
        address fundingManager,
        bool isLong,
        uint256 productId,
        uint256 positionLeverage,
        uint256 margin,
        int256 funding
    ) internal view returns(int256) {
        uint256 notional = margin * positionLeverage;
        int256 fundingChanged = IFundingManager(fundingManager).getFunding(productId) - funding;
        if (isLong) {
            return int256(notional) * fundingChanged / int256(BASE * FUNDING_BASE);
        } else {
            return -1 * int256(notional) * fundingChanged / int256(BASE * FUNDING_BASE);
        }
        // return isLong ? int256(notional) * fundingChanged / int256(BASE * FUNDING_BASE) :
        //     -1 * int256(notional) * fundingChanged / int256(BASE * FUNDING_BASE);
    } 

    function _getTradeFee(
        uint256 margin,
        uint256 leverage,
        uint256 productFee,
        address productToken,
        address user,
        address sender,
        address feeCalculator
    ) internal view returns(uint256) {
        uint256 fee = IFeeCalculator(feeCalculator).getFee(productToken, productFee, user, sender);
        return margin * leverage / BASE * fee / 10**4;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFundingManager {
    function updateFunding(uint256) external;
    function getFunding(uint256) external view returns(int256);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}