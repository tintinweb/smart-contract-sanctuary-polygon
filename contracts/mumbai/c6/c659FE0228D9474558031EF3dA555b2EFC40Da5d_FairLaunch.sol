// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _manager;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _manager = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function manager() internal view virtual returns (address) {
        return _manager;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyManager() {
        require(manager() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IPancakeRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address sender, 
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
} 

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);

    function claim(address _recipient) external;
}

interface ITreasury {
    function mintFairLaunch(uint256 _amount) external;

    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (bool);

    function valueOf(address _token, uint256 _amount) external view returns (uint256 value_);
}

contract FairLaunch is Ownable {
    using SafeMath for uint256;

    // ==== STRUCTS ====

    struct UserInfo {
        uint256 purchased; // XOD
        uint256 bonus; // XOD
        uint256 depositAmount;  // DAI
        uint256 vesting; // time left to be vested
        uint256 lastTime;
    }

    // ==== CONSTANTS ====

    uint256 private constant MAX_PER_ADDR = 1000e18; // max 1k DAI

    uint256 private constant MIN_PER_ADDR = 250e18; // max 250 DAI

    uint256 public constant MAX_FOR_SALE = 500000e18; // 500k DAI

    uint256 private constant VESTING_TERM = 15 days;

    uint256 private constant EXCHANGE_RATE_1 = 7; // 7 assets -> 1 XOD
    uint256 private constant EXCHANGE_RATE_2 = 10; // 10 assets -> 1 XOD

    uint256 private constant MARKET_PRICE = 14; // 1 XOD: $14

    // ==== STORAGES ====

    uint256 public startVesting;

    IERC20 public tokenDeposit;
    IERC20 public XOD;

    uint256 private constant TOKEN_DEPOSIT_THRESHOLD_1 = 25000e18;   // 25k
    uint256 private constant BONUS_RATE_1 = 150;   // 15%
    
    uint256 private constant TOKEN_DEPOSIT_THRESHOLD_2 = 50000e18;   // 50k
    uint256 private constant BONUS_RATE_2 = 125;   // 12.5%
    
    uint256 private constant TOKEN_DEPOSIT_THRESHOLD_3 = 100000e18;   // 100k
    uint256 private constant BONUS_RATE_3 = 100;   // 10%
    
    uint256 private constant TOKEN_DEPOSIT_THRESHOLD_4 = 200000e18;   // 200k
    uint256 private constant BONUS_RATE_4 = 75;   // 7.5%
    
    uint256 private constant TOKEN_DEPOSIT_THRESHOLD_5 = 300000e18;   // 300k
    uint256 private constant BONUS_RATE_5 = 50;   // 5%

    uint256 public currentExchangeRate;

    uint256 public currentBonusRate;


    // staking contract
    address public staking;

    // treasury contract
    address public treasury;

    // router address
    address public router;

    // factory address
    address public factory;

    // finalized status
    bool public finalized;

    // total asset purchased;
    uint256 public totalPurchased;

    // total XOD saled
    uint256 public totalXODSaled;

    // white list for private sale
    mapping(address => bool) public isWhitelist;
    mapping(address => bool) public newWhitelist;
    mapping(address => UserInfo) public userInfo;

    // ==== EVENTS ====

    event Deposited(address indexed depositor, uint256 indexed amount);
    event Redeemed(address indexed recipient, uint256 payout, uint256 remaining);
    event WhitelistUpdated(address indexed depositor, bool indexed value);

    // ==== CONSTRUCTOR ====

    constructor(IERC20 _tokenDeposit, uint256 _startVesting) {
        tokenDeposit = _tokenDeposit;
        startVesting = _startVesting;
    }

    // ==== VIEW FUNCTIONS ====

    function availableFor(address _depositor) public view returns (uint256 amount_) {
        amount_ = 0;

        UserInfo memory user = userInfo[_depositor];
        uint256 totalAvailable = MAX_FOR_SALE.sub(totalPurchased);
        // uint256 assetPurchased = user.purchased.mul(currentExchangeRate).mul(1e9);
        uint256 depositorAvailable = MAX_PER_ADDR.sub(user.depositAmount);
        amount_ = totalAvailable > depositorAvailable ? depositorAvailable : totalAvailable;
    }

    function payFor(uint256 _amount) public view returns (uint256 XODAmount_) {
        // XOD decimals: 9
        // asset decimals: 18
        XODAmount_ = _amount.mul(1e9).div(currentExchangeRate).div(1e18);
    }

    function percentVestedFor(address _depositor) public view returns (uint256 percentVested_) {
        UserInfo memory user = userInfo[_depositor];

        if (block.timestamp < user.lastTime) return 0;

        uint256 timeSinceLast = block.timestamp.sub(user.lastTime);
        uint256 vesting = user.vesting;

        if (vesting > 0) {
            percentVested_ = timeSinceLast.mul(10000).div(vesting);
        } else {
            percentVested_ = 0;
        }
    }

    function pendingPayoutFor(address _depositor) external view returns (uint256 pendingPayout_) {
        uint256 percentVested = percentVestedFor(_depositor);
        uint256 payoutAll = userInfo[_depositor].purchased + userInfo[_depositor].bonus;

        if (percentVested >= 10000) {
            pendingPayout_ = payoutAll;
        } else {
            pendingPayout_ = payoutAll.mul(percentVested).div(10000);
        }
    }

    function getCurrentStateValue(uint256 _totalPurchased) internal  {
        if (_totalPurchased <= TOKEN_DEPOSIT_THRESHOLD_1) {
            currentExchangeRate = EXCHANGE_RATE_1;
            currentBonusRate = BONUS_RATE_1;
        } else if(_totalPurchased <= TOKEN_DEPOSIT_THRESHOLD_2) {
            currentExchangeRate = EXCHANGE_RATE_1;
            currentBonusRate = BONUS_RATE_2;
        } else if(_totalPurchased <= TOKEN_DEPOSIT_THRESHOLD_3) {
            currentExchangeRate = EXCHANGE_RATE_1;
            currentBonusRate = BONUS_RATE_3;
        } else if(_totalPurchased <= TOKEN_DEPOSIT_THRESHOLD_4) { // 200k
            currentExchangeRate = EXCHANGE_RATE_2;
            currentBonusRate = BONUS_RATE_1;
        } else if(_totalPurchased <= TOKEN_DEPOSIT_THRESHOLD_5) {
            currentExchangeRate = EXCHANGE_RATE_2;
            currentBonusRate = BONUS_RATE_1;
        } else {
            currentExchangeRate = EXCHANGE_RATE_2;
            currentBonusRate = 0;
        }
    }
    // ==== EXTERNAL FUNCTIONS ====

    function deposit(address _depositor, uint256 _amount) external {
        require(!finalized, "already finalized");

        UserInfo storage user = userInfo[_depositor];
        if (user.depositAmount < MIN_PER_ADDR) {
            require(_amount >= MIN_PER_ADDR, "You should invest at least $250");
        }
        
        getCurrentStateValue(totalPurchased.add(_amount));

        uint256 available = availableFor(_depositor);
        require(_amount <= available, "exceed limit");

        totalPurchased = totalPurchased.add(_amount);

        uint256 XODAmount = payFor(_amount);
        uint256 bonusAmound = XODAmount.mul(currentBonusRate).div(1000);
        totalXODSaled = totalXODSaled.add(XODAmount).add(bonusAmound);

        user.purchased = user.purchased.add(XODAmount);
        user.bonus = user.bonus.add(bonusAmound);
        user.depositAmount = user.depositAmount.add(_amount);
        user.vesting = VESTING_TERM;
        user.lastTime = startVesting;

        tokenDeposit.transferFrom(msg.sender, address(this), _amount);

        emit Deposited(_depositor, _amount);
    }

    function redeem(address _recipient, bool _stake) external {
        require(finalized, "not finalized yet");

        UserInfo memory user = userInfo[_recipient];

        uint256 percentVested = percentVestedFor(_recipient);
        if (block.timestamp < user.lastTime) return;

        if (percentVested >= 10000 || isWhitelist[_recipient]) {
            // if fully vested
            delete userInfo[_recipient]; // delete user info
            emit Redeemed(_recipient, user.purchased, 0); // emit bond data

            _stakeOrSend(_recipient, _stake, user.purchased + user.bonus); // pay user everything due
        } else {
            // if unfinished
            // calculate payout vested
            uint256 payout = user.purchased.mul(percentVested).div(10000);        
            uint256 bonusOut = user.bonus.mul(percentVested).div(10000);

            // store updated deposit info
            userInfo[_recipient] = UserInfo({
                purchased: user.purchased.sub(payout),
                bonus: user.bonus.sub(bonusOut),
                depositAmount: user.depositAmount,
                vesting: user.vesting.sub(block.timestamp.sub(user.lastTime)),
                lastTime: block.timestamp
            });

            emit Redeemed(_recipient, payout + bonusOut, userInfo[_recipient].purchased + userInfo[_recipient].bonus);

            _stakeOrSend(_recipient, _stake, payout + bonusOut);
        }
    }

    // ==== INTERNAL FUNCTIONS ====

    function _stakeOrSend(
        address _recipient,
        bool _stake,
        uint256 _amount
    ) internal {
        if (!_stake) {
            // if user does not want to stake
            XOD.transfer(_recipient, _amount); // send payout
        } else {
            // if user wants to stake
            XOD.approve(staking, _amount);
            IStaking(staking).stake(_amount, _recipient);
            IStaking(staking).claim(_recipient);
        }
    }

    // ==== RESTRICT FUNCTIONS ====

    function setNewWhiteList(address[] memory _depositors, bool _value) external onlyOwner
    {
        for (uint256 i=0; i<_depositors.length; i++)
         {
              isWhitelist[_depositors[i]] = _value;
             emit WhitelistUpdated(_depositors[i], _value);
         }

    }

     function setWhitelist(address _depositor, bool _value) external onlyOwner {
        isWhitelist[_depositor] = _value;
        emit WhitelistUpdated(_depositor, _value);
    }

    function toggleWhitelist(address[] memory _depositors) external onlyOwner {
        for (uint256 i = 0; i < _depositors.length; i++) {
            isWhitelist[_depositors[i]] = !isWhitelist[_depositors[i]];
            emit WhitelistUpdated(_depositors[i], isWhitelist[_depositors[i]]);
        }
    }

    function emergencyWithdraw(address _token, uint256 _amount) external onlyManager {
        if (_token == address(0)) {
            payable(owner()).transfer(address(this).balance);
        } else {
            IERC20(_token).transfer(owner(), _amount);
        }
    }

    function setupContracts(
        IERC20 _XOD,
        address _staking,
        address _treasury,
        address _router,
        address _factory
    ) external onlyOwner {
        XOD = _XOD;
        staking = _staking;
        treasury = _treasury;
        router = _router;
        factory = _factory;
    }

    // finalize the sale, init liquidity and deposit treasury
    // 100% public goes to LP pool and goes to treasury as liquidity asset
    // 100% private goes to treasury as stable asset
    function finalize() external onlyOwner {
        require(!finalized, "already finalized");
        require(address(XOD) != address(0), "0 addr: XOD");
        require(address(router) != address(0), "0 addr: router");
        require(address(factory) != address(0), "0 addr: factory");
        require(address(treasury) != address(0), "0 addr: treasury");
        require(address(staking) != address(0), "0 addr: staking");

        uint16 liquidityPercent = 300; // 30%

        uint256 liquidityAmount = totalPurchased.mul(liquidityPercent).div(1000);
        uint256 reserveAmount = totalPurchased.sub(liquidityAmount);

        uint256 mintForFairLaunch = totalXODSaled;
        uint256 mintForLiquidity = liquidityAmount.div(MARKET_PRICE).div(1e9);
        ITreasury(treasury).mintFairLaunch(mintForFairLaunch.add(mintForLiquidity));

        tokenDeposit.approve(treasury, 0);
        tokenDeposit.approve(treasury, reserveAmount);
        uint256 profit = ITreasury(treasury).valueOf(address(tokenDeposit), reserveAmount);
        ITreasury(treasury).deposit(reserveAmount, address(tokenDeposit), profit);

        // add liquidity
        tokenDeposit.approve(router, 0);
        tokenDeposit.approve(router, liquidityAmount);
        XOD.approve((router), 0);
        XOD.approve((router), mintForLiquidity);
        IPancakeRouter(router).addLiquidity(
            address(tokenDeposit),
            address(XOD),
            liquidityAmount,
            mintForLiquidity,
            0,
            0,
            address(this),
            block.timestamp
        );

        // give treasury 100% LP, mint 50% XOD
        // FAIR DEAL !!!!
        // address liquidityPair = IPancakeFactory(factory).getPair(address(DAI), address(XOD));
        // uint256 lpProfit = ITreasury(treasury).valueOf(liquidityPair, IERC20(liquidityPair).balanceOf(address(this)));

        // IERC20(liquidityPair).approve(treasury, 0);
        // IERC20(liquidityPair).approve(treasury, IERC20(liquidityPair).balanceOf(address(this)));
        // ITreasury(treasury).deposit(IERC20(liquidityPair).balanceOf(address(this)), liquidityPair, lpProfit);

        finalized = true;
    }
}