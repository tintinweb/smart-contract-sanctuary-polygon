/**
 *Submitted for verification at polygonscan.com on 2022-03-10
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.7;

interface IIndexPrice {
    function indexPrice()
        external
        view
        returns (
            uint256 price,
            uint256 slideUpPrice,
            uint256 SlideDownPrice,
            uint256 decimal
        );

    function decimals() external returns (uint256);
}

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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
}

pragma solidity >=0.8.7;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }
}

pragma solidity >=0.8.7;

contract HedgexERC20 is IERC20 {
    string public constant override name = "HedgexSingle";
    string public constant override symbol = "HEXS";
    uint8 public immutable override decimals;
    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    mapping(address => uint256) public nonces;

    bytes32 public immutable DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    constructor(uint8 _decimals) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
        decimals = _decimals;
    }

    function _mint(address to, uint256 value) internal {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= value;
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "Hedgex: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "Hedgex: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }
}

pragma solidity >=0.8.7;

contract Ownable {
    address public owner;
    address internal newOwner;

    //transfer the owner
    function transferOwner(address _owner) external {
        require(msg.sender == owner, "forbidden");
        newOwner = _owner;
    }

    //accept the owner
    function acceptSetter() external {
        require(msg.sender == newOwner, "forbidden");
        owner = newOwner;
        newOwner = address(0);
    }
}

pragma solidity >=0.8.7;

/// @title Single pair hedge pool contract
contract HedgexSingle is HedgexERC20, Ownable {
    address public feeTo;

    bool public canAddLiquidity = true;
    bool public canOpen = true;

    //smart contract status, 1：normal，2：pool is being liquidated
    uint8 public poolState;

    //the pool's liquidation price, when pool explosiving, it will be record
    uint256 public poolExplosivePrice;

    //during pool liquidation, if the pool net value is below this ratio for minPool, then this ratio is used to calculate the liquidation price
    uint24 public constant poolLeftAmountRate = 50000;

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "locked");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Hedgex Trade: EXPIRED");
        _;
    }

    struct Trader {
        //the trader's margin, it is the amount of token0, it's decimal is same as token0
        int256 margin;
        //the amount of long position
        uint256 longAmount;
        //the average price of the long position
        uint256 longPrice;
        //the amount of short position
        uint256 shortAmount;
        //the average price of the short position
        uint256 shortPrice;
        //the timestamp of interest detection is available, the number of days since timestamp 0
        uint32 interestDay;
    }

    //divisor constant when calculating various rates
    uint24 public constant divConst = 1000000;

    //the minimum amount for the pool to enable the trading pair to start working, it's decimal is same as token0
    uint256 public immutable minPool;

    //if the hedging contract is started
    bool public isStart;

    //leverage ratio
    uint8 public immutable leverage;

    //amount limit of a single open-position trade, the ratio of the net of pool, 3%
    uint16 public constant singleOpenLimitRate = 30000;

    //amount limit of a single close-position trade, the ratio of the net of pool, 10%
    uint24 public constant singleCloseLimitRate = 100000;

    //net position rate of the pool, the limit boundary value when open a position
    int24 public poolNetAmountRateLimitOpen = 400000;

    //net position rate of the pool, the price shift boundary when open or close a position
    int24 public poolNetAmountRateLimitPrice = 300000;

    struct NetPositionRate {
        int256 initR;
        uint256 number;
        int8 deltaR;
    }
    NetPositionRate public R0;
    NetPositionRate public R1;
    NetPositionRate public R2;
    int24 public deltaR0Limit = 50000;
    int24 public deltaR2Limit = 100000;
    uint24 public deltaRSlidePriceRate = 10000;

    //keep margin scale to explosive
    uint8 public keepMarginScale = 30;

    //if trading fee is reward to dev team
    bool public feeOn;

    //trading fee rate, 0.06%
    uint16 public feeRate = 600;

    //the fee ratio for the dev team, 25%
    uint24 public constant feeDivide = 250000;

    //the total amount of the fee for the dev team
    uint256 public sumFee;

    //daily funding rate, 0.1%
    uint16 public constant dailyInterestRateBase = 1000;

    //funding rate share ratio to the caller, 10%
    uint24 public constant interestRewardRate = 100000;

    //the contract address, it will be used as margin when open-position
    address public immutable token0;

    //token0's decimal, in power of 10
    uint256 public immutable token0Decimal;

    //amount of token0 in the pool, could be negative
    int256 public totalPool;

    //the decimal of one position. It is the minimum open amount. for example, one position of btc/usdt pair is 0.001btc, then the value is -3.
    int8 public immutable amountDecimal;

    //the amount of pool's long and short position. for example, 1 is as 10^amountDecimal eth
    uint256 public poolLongAmount;
    uint256 public poolShortAmount;
    //the average price of pool's long and short positioin. it means amount of token0 for per (10^amountDecimal)
    uint256 public poolLongPrice;
    uint256 public poolShortPrice;

    //all of the traders
    mapping(address => Trader) public traders;

    //contract address which provide the index price feed oracle, it is show on chainlink
    IIndexPrice public feedPrice;

    //the contract events
    //add liquidity
    event Mint(address indexed sender, uint256 amount);
    //remove liquidity
    event Burn(address indexed sender, uint256 amount);
    //rechange margin to trader
    event Recharge(address indexed sender, uint256 amount);
    //withdraw margin from trader
    event Withdraw(address indexed sender, uint256 amount); //提取保证金
    //user's trade, direction: 1, -1, -2, 2 mean open-long, open-short, close-long, close-short
    event Trade(
        address indexed sender,
        int8 direction,
        uint256 amount,
        uint256 price
    );
    //user's explosive, direction: -2 is explosive long, and 2 is explosive short
    event Explosive(
        address indexed user,
        int8 direction,
        uint256 amount,
        uint256 price
    );
    //take interest, direction 1 is long>short, amount is the interest, the price is the index price at that moment
    event TakeInterest(
        address indexed user,
        int8 direction,
        uint256 amount,
        uint256 price
    );
    //the pool's explosive event. total:totalPool, la:poolLongAmount, lp:poolLongPrice, sa:poolShortAmount, sa:poolShortPrice, ep:poolExplosivePrice
    event ExplosivePool(
        int256 total,
        uint256 la,
        uint256 lp,
        uint256 sa,
        uint256 sp,
        uint256 ep
    );
    //force close the user's position
    event ForceClose(
        address indexed account,
        uint256 long,
        uint256 short,
        uint256 price
    );

    // _token0, margin token contract's address
    // _feedPrice, chainlink price feed address
    // _feedPriceDecimal，the decimal of price, 8 for usd
    // _minStartPool，the minimum amount of starting value
    // _amountDecimal，for example : -2 is 0.01 per position
    constructor(
        address _token0,
        address _feedPrice,
        uint256 _minStartPool,
        uint8 _leverage,
        int8 _amountDecimal,
        uint8 _keepMarginScale,
        int24 _ROpen,
        int24 _RPrice
    ) HedgexERC20(IERC20(_token0).decimals()) {
        poolState = 1;
        feedPrice = IIndexPrice(_feedPrice);
        token0 = _token0;
        token0Decimal = 10**(IERC20(_token0).decimals());
        minPool = _minStartPool;
        leverage = _leverage;
        isStart = false;
        feeOn = true;
        amountDecimal = _amountDecimal;
        keepMarginScale = _keepMarginScale;
        poolNetAmountRateLimitOpen = _ROpen;
        poolNetAmountRateLimitPrice = _RPrice;

        owner = msg.sender;
    }

    //add token0 liquidity to the pool
    //amount, the amount of token0 that will be transfer to the contract
    //to, the user's address, lp token which the contract create will send to this address
    function addLiquidity(uint256 amount, address to) external {
        require(poolState == 1, "state isn't 1");
        require(canAddLiquidity, "forbidden");
        //send token0 to this contract for amount. user must approve to the contract address before.
        TransferHelper.safeTransferFrom(
            token0,
            msg.sender,
            address(this),
            amount
        );

        //liquidity is equal to amount when isStart is false
        uint256 liquidity = amount;
        if (isStart) {
            //when the contract is running, liquidity = M0 * amount / net, ensure the pool's net must > 0
            int256 net = getPoolNet();
            liquidity = (totalSupply * amount) / uint256(net);
        }

        //add the pool's amount of token0
        totalPool += int256(amount);
        if (totalPool >= int256(minPool)) {
            isStart = true;
        }

        //mint new lp token and send it to user
        _mint(to, liquidity);
        emit Mint(msg.sender, liquidity);
    }

    //remove token0 from pool
    //liquidity, the amount of lp token that send to this contract
    //to, user's address that can receive token0
    function removeLiquidity(uint256 liquidity, address to) external {
        require(poolState == 1, "state isn't 1");
        uint256 amount = liquidity;
        if (isStart) {
            (uint256 price, , ) = getLatestPrice();
            int256 net = getPoolNet(price);
            //the net position amount, it is positive
            uint256 netAmount = poolLongAmount > poolShortAmount
                ? (poolLongAmount - poolShortAmount)
                : (poolShortAmount - poolLongAmount);
            uint256 totalAmount = (poolLongAmount + poolShortAmount) / 3;
            if (netAmount < totalAmount) {
                netAmount = totalAmount;
            }
            uint256 usedMargin = ((netAmount * price) * divConst) /
                uint24(poolNetAmountRateLimitOpen);

            require(net > int256(usedMargin), "net must > usedMargin/R");

            //canWithdraw is the max amount that the pool's allowed
            uint256 canWithdraw = uint256(net) - usedMargin;
            amount = (uint256(net) * liquidity) / totalSupply;
            require(amount <= canWithdraw, "withdraw amount too many");
        }
        totalPool -= int256(amount);
        _burn(msg.sender, liquidity); //burn the lp token
        TransferHelper.safeTransfer(token0, to, amount); //send token0 to user
        emit Burn(msg.sender, liquidity);
    }

    //add user's margin; the amount of token0
    function rechargeMargin(uint256 amount) public {
        TransferHelper.safeTransferFrom(
            token0,
            msg.sender,
            address(this),
            amount
        );
        traders[msg.sender].margin += int256(amount);
        emit Recharge(msg.sender, amount);
    }

    //withdraw user's margin
    function withdrawMargin(uint256 amount) external {
        require(poolState == 1, "state isn't 1");
        Trader memory t = traders[msg.sender];

        //the current index price
        (uint256 price, , ) = getLatestPrice();

        //the current used margin
        uint256 usedMargin = (t.longAmount *
            t.longPrice +
            t.shortAmount *
            t.shortPrice) / leverage;

        //use's current net
        int256 net = t.margin +
            int256(t.longAmount * price + t.shortAmount * t.shortPrice) -
            int256(t.longAmount * t.longPrice + t.shortAmount * price);

        int256 canWithdrawMargin = net - int256(usedMargin);
        require(canWithdrawMargin > 0, "can withdraw is negative");
        uint256 maxAmount = amount;
        if (int256(amount) > canWithdrawMargin) {
            maxAmount = uint256(canWithdrawMargin);
        }
        traders[msg.sender].margin = t.margin - int256(maxAmount);
        TransferHelper.safeTransfer(token0, msg.sender, maxAmount);
        emit Withdraw(msg.sender, maxAmount);
    }

    //open long position. priceExp is the expected price that the deal price cann't higher than it.
    function openLong(
        uint256 priceExp,
        uint256 amount,
        uint256 deadline
    ) external lock ensure(deadline) {
        require(poolState == 1, "state isn't 1");
        require(isStart, "contract is not start");
        require(canOpen, "forbidden");
        (uint256 indexPrice, , uint256 deltaDownPrice) = getLatestPrice();

        //get pool's net and abs(long-short) / net as R
        (int256 R, int256 net, uint256 offsetRPrice) = poolLimitTrade(
            1,
            indexPrice
        );
        require(
            amount <=
                ((uint256(net) * singleOpenLimitRate) / divConst) / indexPrice,
            "single amount over net * rate"
        );
        require(
            R < poolNetAmountRateLimitOpen,
            "pool net amount must small than param"
        );

        //open price add the slide price
        uint256 openPrice = indexPrice +
            offsetRPrice +
            deltaDownPrice +
            slideTradePrice(indexPrice, R);
        require(
            openPrice <= priceExp || priceExp == 0,
            "open long price is too high"
        );

        //the open money is amount * price
        uint256 money = amount * openPrice;
        (uint256 fee, Trader memory t) = judegOpen(indexPrice, money);

        traders[msg.sender].longAmount = t.longAmount + amount;
        traders[msg.sender].longPrice =
            (t.longAmount * t.longPrice + money) /
            (t.longAmount + amount);
        traders[msg.sender].margin = t.margin - int256(fee);

        uint256 _amount = poolShortAmount;
        poolShortAmount = _amount + amount;
        poolShortPrice =
            (_amount * poolShortPrice + money) /
            (_amount + amount);

        feeCharge(fee);
        emit Trade(msg.sender, 1, amount, openPrice);
    }

    //open short position. priceExp is the expected price that the deal price cann't lower than it.
    function openShort(
        uint256 priceExp,
        uint256 amount,
        uint256 deadline
    ) external lock ensure(deadline) {
        require(poolState == 1, "state isn't 1");
        require(isStart, "contract is not start");
        require(canOpen, "forbidden");
        (uint256 indexPrice, uint256 deltaUpPrice, ) = getLatestPrice();

        //get pool's net and abs(long-short) / net as R
        (int256 R, int256 net, uint256 offsetRPrice) = poolLimitTrade(
            -1,
            indexPrice
        );
        require(
            amount <=
                ((uint256(net) * singleOpenLimitRate) / divConst) / indexPrice,
            "single amount over net * rate"
        );
        require(
            R < poolNetAmountRateLimitOpen,
            "pool net amount must small than param"
        );

        //open price sub the slide price
        uint256 openPrice = indexPrice -
            offsetRPrice -
            deltaUpPrice -
            slideTradePrice(indexPrice, R);
        require(openPrice >= priceExp, "open short price is too low");

        uint256 money = amount * openPrice;
        (uint256 fee, Trader memory t) = judegOpen(indexPrice, money);

        traders[msg.sender].shortAmount = t.shortAmount + amount;
        traders[msg.sender].shortPrice =
            (t.shortAmount * t.shortPrice + money) /
            (t.shortAmount + amount);
        traders[msg.sender].margin = t.margin - int256(fee);

        uint256 _amount = poolLongAmount;
        poolLongAmount = _amount + amount;
        poolLongPrice = (_amount * poolLongPrice + money) / (_amount + amount);

        feeCharge(fee);
        emit Trade(msg.sender, -1, amount, openPrice);
    }

    //close long position
    function closeLong(
        uint256 priceExp,
        uint256 amount,
        uint256 deadline
    ) external lock ensure(deadline) {
        require(poolState == 1, "state isn't 1");
        (uint256 indexPrice, uint256 deltaUpPrice, ) = getLatestPrice();

        (int256 R, int256 net, uint256 offsetRPrice) = poolLimitTrade(
            -1,
            indexPrice
        );
        require(
            amount <=
                ((uint256(net) * singleCloseLimitRate) / divConst) / indexPrice,
            "single amount over net * rate"
        );

        uint256 closePrice = indexPrice -
            offsetRPrice -
            deltaUpPrice -
            slideTradePrice(indexPrice, R);
        require(closePrice >= priceExp, "close long price is too low");

        Trader memory t = traders[msg.sender];
        require(t.longAmount >= amount, "close amount require >= longAmount");
        uint256 fee = (amount * closePrice * feeRate) / divConst;

        int256 profit = int256(amount) *
            (int256(closePrice) - int256(t.longPrice));
        traders[msg.sender].longAmount = t.longAmount - amount;
        traders[msg.sender].margin = t.margin + profit - int256(fee);
        if (t.longAmount == amount) {
            traders[msg.sender].longPrice = 0;
        }
        poolShortAmount -= amount;

        feeCharge(fee, profit);
        emit Trade(msg.sender, -2, amount, closePrice);
    }

    //close short position
    function closeShort(
        uint256 priceExp,
        uint256 amount,
        uint256 deadline
    ) external lock ensure(deadline) {
        require(poolState == 1, "state isn't 1");
        (uint256 indexPrice, , uint256 deltaDownPrice) = getLatestPrice();

        (int256 R, int256 net, uint256 offsetRPrice) = poolLimitTrade(
            1,
            indexPrice
        );
        require(
            amount <=
                ((uint256(net) * singleCloseLimitRate) / divConst) / indexPrice,
            "single amount over net * rate"
        );

        uint256 closePrice = indexPrice +
            offsetRPrice +
            deltaDownPrice +
            slideTradePrice(indexPrice, R);
        require(
            closePrice <= priceExp || priceExp == 0,
            "close short price is too high"
        );

        Trader memory t = traders[msg.sender];
        require(t.shortAmount >= amount, "close amount require >= shortAmount");
        uint256 fee = (amount * closePrice * feeRate) / divConst;

        int256 profit = int256(amount) *
            (int256(t.shortPrice) - int256(closePrice));
        traders[msg.sender].shortAmount = t.shortAmount - amount;
        traders[msg.sender].margin = t.margin + profit - int256(fee);
        if (t.shortAmount == amount) {
            traders[msg.sender].shortPrice = 0;
        }
        poolLongAmount -= amount;

        feeCharge(fee, profit);
        emit Trade(msg.sender, 2, amount, closePrice);
    }

    //explosive the user
    function explosive(address account, address to) external lock {
        require(poolState == 1, "state isn't 1");
        Trader memory t = traders[account];

        //caculate the keep margin of trader
        uint256 keepMargin = (t.longAmount *
            t.longPrice +
            t.shortAmount *
            t.shortPrice) / keepMarginScale;
        (uint256 price, , ) = getLatestPrice();
        int256 net = getAccountNet(t, price);
        require(net <= int256(keepMargin), "not match");

        int256 profit = 0;
        //the pool sub the explosive amount  and caculate the profit
        if (t.longAmount > 0) {
            poolShortAmount -= t.longAmount;
            profit =
                int256(t.longAmount) *
                (int256(price) - int256(t.longPrice));
        }
        if (t.shortAmount > 0) {
            poolLongAmount -= t.shortAmount;
            profit +=
                int256(t.shortAmount) *
                (int256(t.shortPrice) - int256(price));
        }

        //flag the explosive direction
        int8 direction = -2;
        if (t.longAmount < t.shortAmount) {
            direction = 2;
        }

        //set trader to zero
        traders[account].margin = 0;
        traders[account].longAmount = 0;
        traders[account].longPrice = 0;
        traders[account].shortAmount = 0;
        traders[account].shortPrice = 0;

        if (net > 0) {
            TransferHelper.safeTransfer(token0, to, uint256(net / 5));
            totalPool += (net * 4) / 5 - profit;
        } else {
            totalPool += net - profit;
        }
        emit Explosive(account, direction, t.longAmount + t.shortAmount, price);
    }

    //take interest when trader has different position direction with pool
    function detectSlide(address account, address to) external lock {
        require(poolState == 1, "state isn't 1");
        uint32 dayCount = uint32(block.timestamp / 86400);
        require( //must 00:00~00:05 everyday
            block.timestamp - uint256(dayCount * 86400) <= 300,
            "time disable"
        );
        Trader storage t = traders[account];
        require(dayCount > t.interestDay, "has been take interest");
        require(t.longAmount != t.shortAmount, "long equal short");

        uint256 _shortPosition = poolShortAmount;
        uint256 _longPosition = poolLongAmount;
        uint256 interest = 0;
        int8 direction = 1;
        uint256 price = 0;
        if (t.longAmount > t.shortAmount) {
            require(_shortPosition > _longPosition, "have no interest");
            (price, , ) = getLatestPrice();
            interest =
                (price *
                    t.longAmount *
                    dailyInterestRateBase *
                    (_shortPosition - _longPosition)) /
                divConst /
                _shortPosition;
        } else {
            require(_longPosition > _shortPosition, "have no interest");
            (price, , ) = getLatestPrice();
            direction = -1;
            interest =
                (price *
                    t.shortAmount *
                    dailyInterestRateBase *
                    (_longPosition - _shortPosition)) /
                divConst /
                _longPosition;
        }
        uint256 reward = (interest * interestRewardRate) / divConst;
        t.interestDay = dayCount;
        t.margin -= int256(interest);
        feeCharge(interest - reward);
        TransferHelper.safeTransfer(token0, to, reward);

        emit TakeInterest(account, direction, interest, price);
    }

    //explosive pool, there is no reward
    function explosivePool() external lock {
        require(poolState == 1, "pool is explosiving");
        (uint256 indexPrice, , ) = getLatestPrice();
        int256 poolNet = getPoolNet(indexPrice);
        //caculate the keep margin of pool
        uint256 keepMargin = poolLongAmount > poolShortAmount
            ? ((poolLongAmount - poolShortAmount) * indexPrice) / 5
            : ((poolShortAmount - poolLongAmount) * indexPrice) / 5;
        require(poolNet <= int256(keepMargin), "pool cann't be explosived");

        //set poolState to 2
        poolState = 2;

        //caculate the explosive price
        int256 leftAmount = int256(keepMargin / 4);
        if (poolNet < leftAmount) {
            //caculate the ePrice to ensure the leftAmount = keepMargin / 4
            int256 ePrice = (totalPool -
                int256(poolLongAmount * poolLongPrice) +
                int256(poolShortAmount * poolShortPrice) -
                leftAmount) /
                (int256(poolShortAmount) - int256(poolLongAmount));
            require(ePrice > 0, "eprice > 0");
            poolExplosivePrice = uint256(ePrice);
            totalPool = leftAmount;
        } else {
            //set ePrice to current index price
            totalPool = poolNet;
            poolExplosivePrice = indexPrice;
        }
        poolLongPrice = poolShortPrice = 0;
    }

    //force close user's position with poolExplosivePrice when the poolState is 2
    function forceCloseAccount(address account, address to) external lock {
        require(poolState == 2, "poolState is not 2");
        Trader memory t = traders[account];
        uint256 _poolExplosivePrice = poolExplosivePrice;
        int256 net = getAccountNet(t, _poolExplosivePrice);

        uint256 fee = ((t.longAmount *
            _poolExplosivePrice +
            t.shortAmount *
            _poolExplosivePrice) * feeRate) / divConst;

        //the pool's position sub the amount
        if (t.longAmount > 0) {
            poolShortAmount -= t.longAmount;
        }
        if (t.shortAmount > 0) {
            poolLongAmount -= t.shortAmount;
        }

        //set the poolState to 1 when all traders' position is zero
        if (poolLongAmount <= 0 && poolShortAmount <= 0) {
            poolState = 1;
        }

        //trader's margin and position set to zero
        if (net > int256(fee)) {
            traders[account].margin = net - int256(fee);
            totalPool += int256(fee);
        } else {
            traders[account].margin = 0;
            totalPool += net;
        }
        traders[account].longAmount = 0;
        traders[account].longPrice = 0;
        traders[account].shortAmount = 0;
        traders[account].shortPrice = 0;

        uint256 reward = token0Decimal / 10;

        totalPool -= int256(reward);
        TransferHelper.safeTransfer(token0, to, reward);

        emit ForceClose(
            account,
            t.longAmount,
            t.shortAmount,
            _poolExplosivePrice
        );
    }

    //get current net of pool, require net > 0
    function getPoolNet() public view returns (int256) {
        (uint256 price, , ) = getLatestPrice();
        int256 net = totalPool +
            int256(poolLongAmount * price + poolShortAmount * poolShortPrice) -
            int256(poolLongAmount * poolLongPrice + poolShortAmount * price);
        require(net > 0, "net<=0");
        return net;
    }

    //get the net of pool, using price to caculate, require net > 0
    function getPoolNet(uint256 price) internal view returns (int256) {
        int256 net = totalPool +
            int256(poolLongAmount * price + poolShortAmount * poolShortPrice) -
            int256(poolLongAmount * poolLongPrice + poolShortAmount * price);
        require(net > 0, "net<=0");
        return net;
    }

    function getDeltaPriceByR(int256 R) internal returns (int8) {
        if (block.number != R0.number) {
            //move R0->R1,R1->R2
            R2 = R1;
            R1 = R0;
            R0.number = block.number;
            R0.initR = R;
            R0.deltaR = 0;
            if (R1.number != (block.number - 1)) {
                R2 = R1;
                R1 = R0;
                R1.number = block.number - 1;
            }
            if (R2.number != (block.number - 2)) {
                R2 = R1;
                R2.number = block.number - 2;
            }
        }
        int256 deltaR1 = R - R0.initR;
        int256 deltaR2 = R - R2.initR;
        if ((deltaR1 > deltaR0Limit) || (deltaR2 > deltaR2Limit)) {
            R0.deltaR = 1;
            return 1; // buy price +
        } else if ((deltaR1 < -deltaR0Limit) || (deltaR2 < -deltaR2Limit)) {
            R0.deltaR = -1;
            return -1; // sell price -
        }
        return R1.deltaR;
    }

    //return the net position ratio of the liquidity pool and net of pool
    //d is the direction when make a trade, +1 means buy(open-long, close-short)，-1 means sell(open-short, close-long)
    //inP is the index price
    function poolLimitTrade(int8 d, uint256 inP)
        internal
        returns (
            int256,
            int256,
            uint256
        )
    {
        int256 net = getPoolNet(inP);
        int256 R = (d *
            (int256(poolShortAmount) - int256(poolLongAmount)) *
            int256(inP) *
            int24(divConst)) / net;
        uint256 slidePrice = 0;
        if (getDeltaPriceByR(R) == d) {
            slidePrice = (inP * deltaRSlidePriceRate) / divConst;
        }
        return (R, net, slidePrice);
    }

    //caculate the slide price of trade
    function slideTradePrice(uint256 inP, int256 R)
        internal
        view
        returns (uint256)
    {
        uint256 slideRate = 0;
        if (R >= (poolNetAmountRateLimitPrice * 3) / 2) {
            slideRate = uint256(
                poolNetAmountRateLimitPrice /
                    10 +
                    (2 * R - 3 * poolNetAmountRateLimitPrice) /
                    5
            );
        } else if (R >= poolNetAmountRateLimitPrice) {
            slideRate = uint256(R - poolNetAmountRateLimitPrice) / 5;
        }
        return (inP * slideRate) / divConst;
    }

    //caculate the open margin, and transfer token0 from user's wallet
    function judegOpen(uint256 indexPrice, uint256 money)
        internal
        returns (uint256, Trader memory)
    {
        Trader memory t = traders[msg.sender];
        //caculate trader's net
        int256 net = t.margin +
            int256(t.longAmount * indexPrice + t.shortAmount * t.shortPrice) -
            int256(t.longAmount * t.longPrice + t.shortAmount * indexPrice);
        //caculate trader's used margin
        uint256 usedMargin = (t.longAmount *
            t.longPrice +
            t.shortAmount *
            t.shortPrice) / leverage;
        //need margin for the open position
        uint256 needMargin = money / leverage;
        //need fee for the open position
        uint256 fee = (money * feeRate) / divConst;
        //need addtional margin for the open position, transfer from trader's wallet
        int256 needRechargeMargin = int256(usedMargin + needMargin + fee) - net;
        if (needRechargeMargin > 0) {
            rechargeMargin(uint256(needRechargeMargin));
            t = traders[msg.sender];
        }
        return (fee, t);
    }

    //pool charge fee
    function feeCharge(uint256 fee) internal {
        if (feeOn) {
            uint256 platFee = (fee * feeDivide) / divConst;
            sumFee += platFee;
            totalPool += int256(fee) - int256(platFee);
        } else {
            totalPool += int256(fee);
        }
    }

    //pool charge fee and profit
    function feeCharge(uint256 fee, int256 profit) internal {
        if (feeOn) {
            uint256 platFee = (fee * feeDivide) / divConst;
            sumFee += platFee;
            totalPool += int256(fee) - int256(platFee) - profit;
        } else {
            totalPool += int256(fee) - profit;
        }
    }

    function getAccountNet(Trader memory t) internal view returns (int256) {
        (uint256 price, , ) = getLatestPrice();
        return
            t.margin +
            int256(t.longAmount * price + t.shortAmount * t.shortPrice) -
            int256(t.longAmount * t.longPrice + t.shortAmount * price);
    }

    function getAccountNet(Trader memory t, uint256 price)
        internal
        pure
        returns (int256)
    {
        return
            t.margin +
            int256(t.longAmount * price + t.shortAmount * t.shortPrice) -
            int256(t.longAmount * t.longPrice + t.shortAmount * price);
    }

    function getPoolPosition()
        external
        view
        returns (
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint8
        )
    {
        return (
            totalPool,
            poolLongAmount,
            poolLongPrice,
            poolShortAmount,
            poolShortPrice,
            poolState
        );
    }

    //get the index price, the token0's amount for per position
    function getLatestPrice()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 price,
            uint256 priceSlideUp,
            uint256 priceSlideDown,
            uint256 feedPriceDecimal
        ) = feedPrice.indexPrice();
        require(price > 0, "the pair standard price must be positive");
        if (amountDecimal >= 0) {
            return (
                (price * token0Decimal * 10**uint8(amountDecimal)) /
                    feedPriceDecimal,
                (priceSlideUp * token0Decimal * 10**uint8(amountDecimal)) /
                    feedPriceDecimal,
                (priceSlideDown * token0Decimal * 10**uint8(amountDecimal)) /
                    feedPriceDecimal
            );
        }
        return (
            (price * token0Decimal) /
                10**uint8(-amountDecimal) /
                feedPriceDecimal,
            (priceSlideUp * token0Decimal) /
                (10**uint8(-amountDecimal)) /
                feedPriceDecimal,
            (priceSlideDown * token0Decimal) /
                (10**uint8(-amountDecimal)) /
                feedPriceDecimal
        );
    }

    //set the address for the index price to get
    function setFeedPrice(address _feedPrice) external {
        require(msg.sender == owner, "forbidden");
        feedPrice = IIndexPrice(_feedPrice);
    }

    function setPoolNetAmountRateLimitOpen(int24 value) external {
        require(msg.sender == owner, "forbidden");
        poolNetAmountRateLimitOpen = value;
    }

    function setPoolNetAmountRateLimitPrice(int24 value) external {
        require(msg.sender == owner, "forbidden");
        poolNetAmountRateLimitPrice = value;
    }

    function setDeltaR0Limit(int24 value) external {
        require(msg.sender == owner, "forbidden");
        deltaR0Limit = value;
    }

    function setDeltaR2Limit(int24 value) external {
        require(msg.sender == owner, "forbidden");
        deltaR2Limit = value;
    }

    function setDeltaRSlidePriceRate(uint24 value) external {
        require(msg.sender == owner, "forbidden");
        deltaRSlidePriceRate = value;
    }

    function setKeepMarginScale(uint8 value) external {
        require(msg.sender == owner, "forbidden");
        keepMarginScale = value;
    }

    function setCanAddLiquidity(bool b) external {
        require(msg.sender == owner, "forbidden");
        canAddLiquidity = b;
    }

    function setCanOpen(bool b) external {
        require(msg.sender == owner, "forbidden");
        canOpen = b;
    }

    //withdraw the fee to dev team
    function withdrawFee() external {
        require(msg.sender == feeTo, "forbidden");
        uint256 _sumFee = sumFee;
        sumFee = 0;
        TransferHelper.safeTransfer(token0, feeTo, _sumFee);
    }

    //set the fee on or off
    function setFeeOn(bool b) external {
        require(msg.sender == owner, "forbidden");
        feeOn = b;
    }

    function setFeeRate(uint16 value) external {
        require(msg.sender == owner, "frobidden");
        feeRate = value;
    }

    //set the address that the fee send to
    function setFeeTo(address _feeTo) external {
        require(msg.sender == owner, "forbidden");
        feeTo = _feeTo;
    }
}