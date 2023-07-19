// SPDX-License-Identifier: MIT
// optimizer: true
// disable-for-now: revert-strings
pragma solidity >=0.4.22 <0.9.0;

// decentraliz universal laboratory
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ITreasurySale.sol";
import "./CallerPermission.sol";
import "./ReEntrancyGuard.sol";
import "./InvestSystem.sol";
import "./Ticker.sol";

contract SwapFactory is Ownable, CallerPermission, ReEntrancyGuard, Ticker {
    using SafeMath for uint256;

    // A very large multiplier means you can support many decimals
    uint256 public constant MULTIPLIER = 1e6;

    InvestSystem public oldContract;

    IERC20 public token0; // du
    IERC20 public token1; // usdt

    // wallet of developer
    address public developer;
    address public fund;
    address public dev;
    address public marketing;
    address public expenses;
    address public feeAllocation;

    uint256 public fundPercent = 350;
    uint256 public devPercent = 250;
    uint256 public marketingPercent = 240;
    uint256 public expensesPercent = 160;

    uint256 public DirectCommission = 60; // 6%

    uint256 public totalBuy = 0; // in usd
    uint256 public totalSell = 0; // in usd

    uint256 public rate;

    struct userModel {
        uint256 id;
        uint256 join_time;
        uint256 total_buy;
        uint256 total_sell;
        address upline;
        uint256 bonus;
        uint256 structures;
    }
    mapping(address => userModel) public investers;
    uint256 investerId = 1000000000;
    struct userIndexModel {
        uint256 id;
        address wallet;
    }
    userIndexModel[] public users;
    bool public isActiveBuy = true;
    bool public isActiveSell = true;

    ITreasurySale public treasurySale;

    // events: buy,sell
    event evBuy(uint256 amount, address account);
    event evSell(uint256 amount, address account);

    // manually state
    bool public isManualy = true;
    bool public isEtherBase = false;
    uint256 public token1Balance = 500000000;

    constructor(
        IERC20 _token,
        IERC20 _usdt,
        ITreasurySale _treasurySale,
        address _developer,
        address _fund,
        address _dev,
        address _marketing,
        address _expenses,
        address _feeAllocation
    ) {
        token0 = _token;
        token1 = _usdt;
        treasurySale = _treasurySale;

        developer = _developer;
        fund = _fund;
        dev = _dev;
        marketing = _marketing;
        expenses = _expenses;
        feeAllocation = _feeAllocation;

        // add developer wallet
        investers[developer].id = investerId;
        investers[developer].join_time = block.timestamp;

        // add to index
        userIndexModel memory idx = userIndexModel(
            investers[developer].id,
            developer
        );
        users.push(idx);

        addTick(block.timestamp, 0, 0);

        isActiveBuy = true;
        isActiveSell = true;
    }

    function addInvester(
        address investerAddress,
        uint256 id,
        uint256 join_time,
        uint256 total_deposit,
        uint256 total_withdraw,
        address upline,
        uint256 bonuse,
        uint256 structures
    ) public onlyOwner {
        if (investers[investerAddress].id > 0) {
            return;
        }

        investers[investerAddress] = userModel(
            id,
            join_time,
            total_deposit,
            total_withdraw,
            upline,
            bonuse,
            structures
        );
        // add to index
        userIndexModel memory idx = userIndexModel(id, msg.sender);

        users.push(idx);
    }

    function currentRate() public view returns (uint256) {
        (uint reserv0, uint reserv1) = getReserve();

        return MULTIPLIER.mul(reserv1).div(reserv0);
    }

    /**
     * @dev Returns the amount of `POOL Tokens` held by the contract
     */
    function getReserve() public view returns (uint, uint) {
        uint token0Reserve = IERC20(token0).balanceOf(address(this));
        uint token1Reserve = IERC20(token1).balanceOf(address(this));

        if (isEtherBase) {
            token1Reserve = address(this).balance;
        }

        // limited time
        if (isManualy) {
            // token1Reserve += !isEtherBase ? token1Balance * 10**6 : token1Balance * 10**18 ;
            token1Reserve += token1Balance; // * 10**6 : token1Balance * 10**18 ;
        }
        return (token0Reserve, token1Reserve);
    }

    function beforSwap(address sender, uint side) internal {}

    function afterSwap(uint256 amount, uint side) internal {
        treasurySale.saleCall(amount, side);
    }

    /*function buy(
        uint256 amount,
        uint256 upline,
        uint256 minToken0
    ) public noReentrant returns (uint256) {
        require(isActiveBuy, "SwapFactory: active buy is disable");

        beforSwap(msg.sender, 0);

        uint256 paidFee = 0;
        uint256 _rate = currentRate();

        (uint reserv0, uint reserve1) = getReserve();

        address _up;
        if (investers[msg.sender].join_time > 0) {
            _up = investers[msg.sender].upline;
        } else {
            _up = getUserAddress(upline);
        }

        require(_up != address(0), "SwapFactory: upline not exist");

        // check balance of USDT A from sender
        require(
            token1.balanceOf(msg.sender) >= amount,
            "SwapFactory: USD balance is low"
        );

        // check allowance
        require(
            token1.allowance(msg.sender, address(this)) >= amount,
            "SwapFactory: token1 allowance not correct"
        );
        token1.transferFrom(msg.sender, address(this), amount);

        // calculation
        uint256 amountOfToken = getAmountOfTokens(
            amount,
            reserve1.sub(amount),
            reserv0,
            true
        ); // token

        require(
            amountOfToken >= minToken0,
            "SwapFactory: insufficient output amount"
        );

        // balance of contract must be higher of required with current rate
        require(
            token0.balanceOf(address(this)) >= amountOfToken,
            "SwapFactory: contract balance is low"
        );
        require(
            reserv0.sub(amountOfToken) > 100,
            "SwapFactory: pool balance is low"
        );

        // transfer token
        token0.transfer(msg.sender, amountOfToken);

        // 6% send to upline
        uint256 directAmount = amount.mul(DirectCommission).div(1000);
        uint256 partfeeAmount = amount.mul(5).div(1000);
        if (investers[_up].join_time > 0) {
            investers[_up].bonus += directAmount;
            if (_up != address(0)) {
                paidFee += directAmount;
                token1.transfer(_up, directAmount);
            }
        }

        // 0.5% send to developer
        token1.transfer(developer, partfeeAmount);
        paidFee += partfeeAmount;

        // 2.5% send to feeAllocation
        token1.transfer(feeAllocation, partfeeAmount.mul(5));
        paidFee += partfeeAmount.mul(5);

        // transfer fund
        uint256 remainAmount = amount.sub(paidFee);

        // splite to action fund
        // 35% fund
        // token1.transfer(fund, remainAmount.mul(fundPercent).div(1000));
        // 25% development
        token1.transfer(dev, remainAmount.mul(devPercent).div(1000));
        // 24% Marketing
        token1.transfer(
            marketing,
            remainAmount.mul(marketingPercent).div(1000)
        );
        // 16% expenses
        token1.transfer(expenses, remainAmount.mul(expensesPercent).div(1000));

        // 8. update invester ( deposit_amount , deposit_time)
        if (investers[msg.sender].join_time == 0) {
            investers[msg.sender].upline = _up;
            investers[msg.sender].id = generateUniqueId();
            investers[msg.sender].join_time = block.timestamp;

            investers[_up].structures++;

            // add to index
            userIndexModel memory idx = userIndexModel(
                investers[msg.sender].id,
                msg.sender
            );

            users.push(idx);
        }

        investers[msg.sender].total_buy += (amount).sub(partfeeAmount.mul(6));

        totalBuy += amountOfToken;

        // buy event
        emit evBuy(amountOfToken, msg.sender);

        addTick(block.timestamp, _rate, amountOfToken);

        afterSwap(amountOfToken, 0);

        return amountOfToken;
    }*/
    function buyWithETH(
        uint256 upline,
        uint256 minToken0
    ) public payable noReentrant returns (uint256) {
        uint256 amount = msg.value;
        require(isActiveBuy, "SwapFactory: active buy is disable");

        beforSwap(msg.sender, 0);

        uint256 paidFee = 0;
        uint256 _rate = currentRate();

        (uint reserv0, uint reserve1) = getReserve();

        address _up;
        if (investers[msg.sender].join_time > 0) {
            _up = investers[msg.sender].upline;
        } else {
            _up = getUserAddress(upline);
        }

        require(_up != address(0), "SwapFactory: upline not exist");

        amount = amount.div(10 ** 18);
        amount = amount.mul(10 ** 6);

        // calculation
        uint256 amountOfToken = getAmountOfTokens(
            amount,
            reserve1.sub(amount),
            reserv0,
            true
        ); // token

    /*    require(
            amountOfToken >= minToken0,
            "SwapFactory: insufficient output amount"
        );*/

        // balance of contract must be higher of required with current rate
        require(
            token0.balanceOf(address(this)) >= amountOfToken,
            "SwapFactory: contract balance is low"
        );
        require(
            reserv0.sub(amountOfToken) > 100,
            "SwapFactory: pool balance is low"
        );

        // transfer token
        token0.transfer(msg.sender, amountOfToken);

        // 6% send to upline
        uint256 directAmount = amount.mul(DirectCommission).div(1000);
        uint256 partfeeAmount = amount.mul(5).div(1000);
        if (investers[_up].join_time > 0) {
            investers[_up].bonus += directAmount;
            if (_up != address(0)) {
                paidFee += directAmount;
                token1.transfer(_up, directAmount);
            }
        }

        // 0.5% send to developer
        payable(developer).transfer(partfeeAmount);
        paidFee += partfeeAmount;

        // 2.5% send to feeAllocation
        payable(feeAllocation).transfer(partfeeAmount.mul(5));
        paidFee += partfeeAmount.mul(5);

        // transfer fund
        uint256 remainAmount = amount.sub(paidFee);

        // splite to action fund
        // 35% fund
        // payable(fund).transfer(remainAmount.mul(fundPercent).div(1000));
        // 25% development
        payable(dev).transfer(remainAmount.mul(devPercent).div(1000));
        // 24% Marketing
        payable(marketing).transfer(
            remainAmount.mul(marketingPercent).div(1000)
        );
        // 16% expenses
        payable(expenses).transfer(remainAmount.mul(expensesPercent).div(1000));

        // 8. update invester ( deposit_amount , deposit_time)
        if (investers[msg.sender].join_time == 0) {
            investers[msg.sender].upline = _up;
            investers[msg.sender].id = generateUniqueId();
            investers[msg.sender].join_time = block.timestamp;

            investers[_up].structures++;

            // add to index
            userIndexModel memory idx = userIndexModel(
                investers[msg.sender].id,
                msg.sender
            );

            users.push(idx);
        }

        investers[msg.sender].total_buy += (amount).sub(partfeeAmount.mul(6));

        totalBuy += amountOfToken;

        // buy event
        emit evBuy(amountOfToken, msg.sender);

        addTick(block.timestamp, _rate, amountOfToken);

        afterSwap(amountOfToken, 0);

        return amountOfToken;
    }

    //  @notice Explain to an end user what this does
    //  @dev Explain to a developer any extra details
    //  @param amount of token sender like pay
    //  @return amount of USDT transfered to sender
    // function sell(
    //     uint256 amount,
    //     uint256 minUSD
    // ) public noReentrant returns (uint256) {
    //     require(isActiveSell, "SwapFactory: active sell is disable");

    //     address invester = msg.sender;
    //     address beneficiary = address(this);
    //     uint256 _rate = currentRate();

    //     (uint reserv0, uint reserv1) = getReserve();

    //     address _up;
    //     if (investers[msg.sender].join_time > 0) {
    //         _up = investers[msg.sender].upline;
    //     }

    //     // calculation
    //     uint256 amountOfToken = getAmountOfTokens(
    //         amount,
    //         reserv0.sub(amount),
    //         reserv1,
    //         false
    //     ); // token
    //     require(
    //         amountOfToken >= minUSD,
    //         "SwapFactory: insufficient output amount"
    //     );
    //     // balance of contract must be lower of required with current rate
    //     require(
    //         token1.balanceOf(beneficiary) >= amountOfToken,
    //         "SwapFactory: contract balance is low"
    //     );
    //     require(
    //         reserv1.sub(amountOfToken) > 100,
    //         "SwapFactory: pool balance is low"
    //     );

    //     // transfer token
    //     token1.transfer(invester, amountOfToken);

    //     // check balance of token0 from sender
    //     require(
    //         token0.balanceOf(invester) >= amount,
    //         "SwapFactory: token0 balance is low"
    //     );
    //     // check allowance
    //     require(
    //         token0.allowance(invester, beneficiary) >= amount,
    //         "SwapFactory: token0 allowance not correct"
    //     );
    //     token0.transferFrom(invester, beneficiary, amount);

    //     // 0.5% send to developer
    //     uint256 partfeeAmount = amount.mul(5).div(1000);
    //     token0.transfer(developer, partfeeAmount);

    //     totalSell += amount;

    //     if (investers[invester].join_time > 0) {
    //         investers[invester].total_sell += (amount).sub(
    //             partfeeAmount.mul(6 * 2)
    //         );
    //     }

    //     emit evSell(amountOfToken, invester);

    //     addTick(block.timestamp, _rate, amountOfToken);

    //     afterSwap(amountOfToken, 1);

    //     return amountOfToken;
    // }

    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve,
        bool side
    ) public pure returns (uint256) {
        // We are charging a fee of `3%`
        // Input amount with fee = (input amount - (1*(input amount)/100)) = ((input amount)*99)/100
        uint256 i = 97;
        if (!side) {
            i = 94;
        }
        uint256 inputAmountWithFee = inputAmount * i;

        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;
        return numerator / denominator;
    }

    function investor(
        address _addr
    )
        external
        view
        returns (uint256, uint256, uint256, uint256, address, uint256)
    {
        return (
            investers[_addr].id,
            investers[_addr].join_time,
            investers[_addr].total_buy,
            investers[_addr].structures,
            investers[_addr].upline,
            investers[_addr].bonus
        );
    }

    function getUserAddress(uint256 _id) internal view returns (address) {
        address res = address(0);
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].id == _id) {
                res = users[i].wallet;
                break;
            }
        }
        return res;
    }

    function getUser(uint256 _id) external view returns (address) {
        address res = address(0);
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].id == _id) {
                res = users[i].wallet;
                break;
            }
        }
        return res;
    }

    function generateUniqueId() public returns (uint256) {
        investerId++;
        uint256 timestamp = block.timestamp;
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(timestamp, investerId))
        );
        uint256 id = (randomNumber % 10000000000);
        // Check if the ID already exists in the users array
        bool idExists = false;
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].id == id) {
                idExists = true;
                break;
            }
        }
        if (idExists) {
            // If the ID already exists, generate a new ID
            id = generateUniqueId();
        }
        return id;
    }

    function info()
        external
        view
        returns (
            uint256 total_Buy,
            uint256 total_Sell,
            uint256 totalInvesters,
            uint256 balanceToken0,
            uint256 balanceToken1,
            uint256 current_Rate
        )
    {
        (uint reserv0, uint reserve1) = getReserve();
        total_Buy = totalBuy;
        total_Sell = totalSell;
        totalInvesters = investerId;
        balanceToken0 = reserv0;
        balanceToken1 = reserve1;
        current_Rate = currentRate();
        return (
            total_Buy,
            total_Sell,
            totalInvesters,
            balanceToken0,
            balanceToken1,
            current_Rate
        );
    }

    // set buy,sell,etherbase state
    function Setup(
        bool newBuyState,
        bool newSellState,
        bool newIsEtherBase,
        bool newIsManualy,
        address newToken0,
        address newToken1,
        address newTreasurySale,
        uint256 newToken1Balance
    ) public onlyOwner returns (bool) {
        isActiveBuy = newBuyState;
        isActiveSell = newSellState;
        isEtherBase = newIsEtherBase;
        isManualy = newIsManualy;
        token0 = IERC20(newToken0);
        token1 = IERC20(newToken1);
        treasurySale = ITreasurySale(newTreasurySale);
        token1Balance = newToken1Balance;
        return true;
    }

    function claim(address _token) public onlyOwner {
        uint256 b = address(this).balance;
        if (b > 0) {
            payable(msg.sender).transfer(b);
        }
        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(_token).approve(address(this), balance);
            IERC20(_token).transfer(msg.sender, balance);
        }
    }

    function claimToken(address _token, address reciever) external onlyCaller {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(_token).approve(address(this), balance);
            IERC20(_token).transfer(reciever, balance);
        }
    }

    function claimTokenCall(
        address _token,
        address reciever,
        uint256 _amount
    ) external onlyCaller {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (balance < _amount) {
            return;
        }
        if (balance > 0) {
            IERC20(_token).approve(address(this), _amount);
            IERC20(_token).transfer(reciever, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
contract Ticker {
    struct priceTick {
        uint256 time;
        uint256 rate;
        uint256 amount;
    }
    priceTick[] public tickers;
    uint256 totalTicks = 0;

    constructor() {}

    function getTickers() public view returns (priceTick[] memory) {
        priceTick[] memory ticks = new priceTick[](totalTicks);

        for (uint i = 0; i < totalTicks; i++) {
            priceTick storage tick = tickers[i];
            ticks[i] = tick;
        }
        return ticks;
    }

    function addTick(uint256 _time, uint256 _rate, uint256 _amount) internal {
        priceTick memory tick = priceTick(_time, _rate, _amount);
        tickers.push(tick);
        totalTicks++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract ReEntrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
// decentraliz universal laboratory
import "./IERC20.sol";
import "./SafeMath.sol";

pragma experimental ABIEncoderV2;

contract InvestSystem {
    using SafeMath for uint256;

    IERC20 public token;
    uint256 decimal;

    // wallet of developer
    address public developer;

    address public fund;
    address public dev;
    address public marketing;
    address public expenses;
    address public btcInvest;

    uint256 public fundPercent = 350;
    uint256 public devPercent = 250;
    uint256 public marketingPercent = 240;
    uint256 public expensesPercent = 160;

    uint256 public DirectCommission = 115; // 10%
    uint256 public minDeposit = 1000000; // in usd
    uint256 public total_deposit = 0; // in usd
    uint256 public deposit_fee = 30; // in %3

    struct userModel {
        uint256 id;
        uint256 join_time;
        uint256 total_deposit;
        uint256 total_withdraw;
        address upline;
        uint256 bonuse;
        uint256 balance;
        uint256 lock_time;
        uint256 structures;
    }
    mapping(address => userModel) public investers;
    uint256 investerId = 1000;

    struct userIndexModel {
        uint256 id;
        address wallet;
    }
    userIndexModel[] public users;

    event depositEvent(address account, uint256 amount);

    constructor(
        address _developer,
        address _fund,
        address _dev,
        address _marketing,
        address _expenses,
        address _btcInvest,
        IERC20 _token
    )  {
        developer = _developer;
        token = _token;

        // add developer wallet
        investers[developer].id = investerId++;
        investers[developer].join_time = block.timestamp;

        // add to index
        userIndexModel memory idx = userIndexModel(
            investers[developer].id,
            developer
        );

        fund = _fund;
        dev = _dev;
        marketing = _marketing;
        expenses = _expenses;
        btcInvest = _btcInvest;

        users.push(idx);
    }

    function deposit(uint256 amount, uint256 upline) external {
        address invester = msg.sender;
        address _up;

        if (investers[invester].join_time > 0) {
            // for stop repeate one wallet
            _up = investers[invester].upline;            
        }else {
            _up = getUserAddress(upline);
        }      

        require(investers[_up].join_time > 0, "upline not found");

        // 1. check balance of token
        uint256 balance = token.balanceOf(invester);

        // 2. balance
        require(balance >= amount, "your balance is low");        

        // 3. transfer incoming
        token.transferFrom(invester, address(this), amount);

        // 0.5% send to developer
        uint256 partfeeAmount = amount.mul(deposit_fee.div(6)).div(1000);

        uint256 directAmount = amount.mul(DirectCommission).div(1000);

        // 4. bonuse : directsale get bonuse 10% USDC.e
        if (investers[_up].join_time > 0) {
            // for stop repeate one wallet
            investers[_up].bonuse += directAmount;
            // pay 10% direct
            if (_up != address(0)) {
                token.transfer(_up, directAmount);
            }
        }

        // 5. transfer developer fee : 0.5%
        token.transfer(developer, partfeeAmount);

        // 6. transfer btcinvest fee : 1%
        token.transfer(btcInvest, partfeeAmount.mul(2));

        uint256 remainAmount = token.balanceOf(address(this));

        // splite to action fund
        token.transfer(fund, remainAmount.mul(fundPercent).div(1000));
        token.transfer(dev, remainAmount.mul(devPercent).div(1000));
        token.transfer(marketing, remainAmount.mul(marketingPercent).div(1000));
        token.transfer(expenses, remainAmount.mul(expensesPercent).div(1000));

        // 8. update invester ( deposit_amount , deposit_time)
        if (investers[invester].join_time == 0) {
            investers[invester].upline = _up;
            investers[invester].id = investerId++;
            investers[invester].join_time = block.timestamp;
            investers[_up].structures++;

            // add to index
            userIndexModel memory idx = userIndexModel(
                investers[invester].id,
                invester
            );

            users.push(idx);
        }

        investers[invester].lock_time = block.timestamp;
        investers[invester].total_deposit += (amount).sub(partfeeAmount.mul(6));

        total_deposit += amount;

        emit depositEvent(invester, amount);
    }

    function investor(
        address _addr
    )
        external
        view
        returns (uint256, uint256, uint256, uint256, address, uint256, uint256)
    {
        return (
            investers[_addr].id,
            investers[_addr].join_time,
            investers[_addr].total_deposit,
            investers[_addr].structures,
            investers[_addr].upline,
            investers[_addr].bonuse,
            investers[_addr].balance
        );
    }

    function getUserAddress(uint256 _id) internal view returns (address) {
        address res = address(0);
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].id == _id) {
                res = users[i].wallet;
                break;
            }
        }
        return res;
    }

    function getUser(uint256 _id) external view returns (address) {
        address res = address(0);
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].id == _id) {
                res = users[i].wallet;
                break;
            }
        }
        return res;
    }

    function info()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256, // refundCounter
            address
        )
    {
        return (
            total_deposit,
            investerId,
            token.balanceOf(address(this)),
            0,
            address(0)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface ITreasurySale {
    function addCaller(
        address _address,
        uint256 _percent
    ) external returns (bool);

    function saleCall(uint256 _amount, uint side) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./Ownable.sol";

contract CallerPermission is Ownable {
    struct callerModel {
        address addr;
        uint256 percentIn;
        uint256 percentOut;
    }
    callerModel[] callers;

    constructor() {}

    function addCaller(
        address _address,
        uint256 _percentIn,
        uint256 _percentOut
    ) external onlyOwner returns (bool) {
        if (isCaller(_address)) return false;
        callerModel memory caller = callerModel(
            _address,
            _percentIn,
            _percentOut
        );
        callers.push(caller);
        return true;
    }

    function removeCaller(address _address) external onlyOwner returns (bool) {
        callerModel memory caller = getCaller(_address);

        if (caller.addr == address(0)) return false;
        for (uint i = 0; i < callers.length; i++) {
            if (callers[i].addr == _address) {
               delete callers[i];
               return true;
            }
        }
        return false;
    }

    function isCaller(address _caller) internal view returns (bool) {
        for (uint i = 0; i < callers.length; i++) {
            if (callers[i].addr == _caller) {
                return true;
            }
        }
        return false;
    }

    function getCaller(
        address _caller
    ) internal view returns (callerModel memory) {
        callerModel memory caller;
        for (uint i = 0; i < callers.length; i++) {
            if (callers[i].addr == _caller) {
                caller = callers[i];
                break;
            }
        }
        return caller;
    }

    function getCallerView(
        address _caller
    ) external view returns (callerModel memory) {
        callerModel memory caller;
        for (uint i = 0; i < callers.length; i++) {
            if (callers[i].addr == _caller) {
                caller = callers[i];
                break;
            }
        }
        return caller;
    }

    modifier onlyCaller() {
        require(
            isCaller(msg.sender),
            "CallerPermission: caller is not the valid"
        );
        _;
    }
}