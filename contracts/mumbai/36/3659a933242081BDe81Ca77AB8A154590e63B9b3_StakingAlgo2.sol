// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface TOKEN {
    function decimals() external view returns(uint8);
    function balanceOf(address account) external view returns(uint256);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);

    // only for OMHERC20 token
    function isExcludedFromBurn(address user) external view returns(bool);
}

contract StakingAlgo2 is ReentrancyGuard {
    struct UserInfo {
        uint256 depositedAmount; // total deposited amount for this user
        uint256 lockedTime; // locked period for claim of this user
        uint256 rewardPayouts;
        // ALA is the abbreviation for At the time of the Latest Action
        uint256 totalRewardALA; // total reward amount at the time of the latest action like deposit, claim
        int256 depositorFeePayouts;
    }

    AggregatorV3Interface internal priceFeed;

    uint256 public startDate;
    uint256 public totalDeposit; // total deposited amount (user deposit)
    uint256 public totalReward; // total reward amount (admin)
    uint256 public latestReward;
    uint256 public totalDepositFee; // total deposit fee, only for algo2
    // TODO: need to set rewardpercent (vip1RewardPercent, ) logic again
    uint256 public vip1MinAmount = 100000; // $100000
    uint256 public vip1LockingPeriod = 60 * 60 * 24 * 365; // 1 year
    uint256 public vip1RewardPercent = 85; // 85% of totalReward
    uint256 public vip2MinAmount = 1000000; // $1000000
    uint256 public vip2LockingPeriod = 60 * 60 * 24 * 365 * 3; // 3 year
    uint256 public vip2RewardPercent = 100; // 100% of totalReward
    uint256 public rewardPercent = 70; // 70% of totalReward

    // TODO: check
    uint256 public minDepositAmount = 100; // $100

    uint256 public depositAdminFeePc = 50; // 5%
    uint256 public depositorFeePc = 50; // 5%

    uint256 public rewardCycle = 7; // 7 days
    uint256 public constant APYDENOMINATOR = 100 * 10**6;
    uint256 public constant DENOMINATOR = 1000;
    uint256 public constant MAGNITUDE = 2**64;
    uint256 private constant USD = 10**8; // usd decimals is 8

    uint256 internal profitPerShare;

    bool public pause = false;

    address public admin;

    TOKEN public depositToken;
    TOKEN public rewardToken; // OMH token

    mapping(address => UserInfo) private userInfo;

    event Deposit(
        address indexed caller,
        uint256 depositedAmount,
        uint256 adminFee,
        uint256 depositorFee,
        uint256 createdAt
    );

    event Withdraw(
        address indexed caller,
        uint256 withdrawAmount,
        uint256 depositorFee,
        uint256 rewardAmount,
        uint256 createdAt
    );

    event Claim(
        address indexed caller,
        uint256 depositorFee,
        uint256 rewardAmount,
        uint256 createdAt
    );

    modifier onlyAdmin() {
        require(msg.sender == admin, "caller is not admin");
        _;
    }

    modifier checkActive() {
        require(block.timestamp >= startDate && !pause, "can not do now");
        _;
    }

    constructor(
        uint256 _startDate,
        address _depositToken,
        address _rewardToken,
        address _priceFeedAddr // Chainlink Aggregator : _depositToken/USD
    ) {
        require(
            _depositToken != address(0) && _rewardToken != address(0) && _priceFeedAddr != address(0),
            "invalid address"
        );
        admin = msg.sender;
        startDate = _startDate;
        depositToken = TOKEN(_depositToken);
        rewardToken = TOKEN(_rewardToken); // OMH token
        priceFeed = AggregatorV3Interface(_priceFeedAddr);
    }

    /** only admin functions */
    function changeAdmin(address _new) external onlyAdmin {
        require(_new != address(0), "invalid address");
        admin = _new;
    }

    function changeDepositToken(address _newToken) external onlyAdmin {
        depositToken = TOKEN(_newToken);
    }

    function changeRewardToken(address _newToken) external onlyAdmin {
        rewardToken = TOKEN(_newToken);
    }

    function changeAggregator(address _newAddr) external onlyAdmin {
        priceFeed = AggregatorV3Interface(_newAddr);
    }

    function changeStartDate(uint256 _newDate) external onlyAdmin {
        startDate = _newDate;
    }

    function changeDepositFeePc(
        uint256 _adminFeePercent,
        uint256 _depositorFeePercent
    ) external onlyAdmin {
        depositAdminFeePc = _adminFeePercent;
        depositorFeePc = _depositorFeePercent;
    }

    function changeVip1(uint256 _minAmount, uint256 _lockingPeriod)
        external
        onlyAdmin
    {
        vip1MinAmount = _minAmount;
        vip1LockingPeriod = _lockingPeriod;
    }

    function changeVip2(uint256 _minAmount, uint256 _lockingPeriod)
        external
        onlyAdmin
    {
        vip2MinAmount = _minAmount;
        vip2LockingPeriod = _lockingPeriod;
    }

    function changeMinDepositAmount(uint256 _newAmount) external onlyAdmin {
        minDepositAmount = _newAmount;
    }

    function changeRewardCycle(uint256 _days) external onlyAdmin {
        require(_days > 0);
        rewardCycle = _days;
    }

    function setRewardPercent(
        uint256 _regularPercent,
        uint256 _vip1Percent,
        uint256 _vip2Percent
    ) external onlyAdmin {
        rewardPercent = _regularPercent;
        vip1RewardPercent = _vip1Percent;
        vip2RewardPercent = _vip2Percent;
    }

    function setPause(bool _status) external onlyAdmin {
        pause = _status;
    }

    function allTokenWithdraw() external onlyAdmin {
        pause = true;
        totalDeposit = 0;
        totalReward = 0;
        uint256 _depositTokenAmount = depositToken.balanceOf(address(this));
        depositToken.transfer(admin, _depositTokenAmount);
        uint256 _rewardTokenAmount = rewardToken.balanceOf(address(this));
        rewardToken.transfer(admin, _rewardTokenAmount);
    }

    /** external funtions */
    function addReward(uint256 _amount) external {
        rewardToken.transferFrom(msg.sender, address(this), _amount);
        uint256 _burnAmount = 0;
        bool _isExcludedAddress = rewardToken.isExcludedFromBurn(msg.sender);
        if (msg.sender.code.length == 0 && !_isExcludedAddress) {
           _burnAmount = (_amount * 2) / 100; // OMH 2% burn
        }
        uint256 _newAmount = _amount - _burnAmount;
        totalReward += _newAmount;
        latestReward = _newAmount;
    }

    function deposit(uint256 _amount) external nonReentrant checkActive {
        uint256 _usdPrice = uint256(getLatestPrice());
        uint256 _decimals = uint256(depositTokenDecimals());
        uint256 _usdAmount = _amount * _usdPrice / (10**_decimals) / USD;
        require(_usdAmount >= minDepositAmount, "amount is less than min deposit amount");

        depositToken.transferFrom(msg.sender, address(this), _amount);

        uint256 _vip1MinAmount = vip1MinAmount;

        // deposit fee
        uint256 _adminFee = 0;
        uint256 _depositorFee = 0;
        uint256 _dividends = 0;
        uint256 _actualAmount = _amount;
        if (_usdAmount < _vip1MinAmount) {
            _adminFee = (_amount * depositAdminFeePc) / DENOMINATOR;
            depositToken.transfer(admin, _adminFee);
            _depositorFee = (_amount * depositorFeePc) / DENOMINATOR;
            _dividends = _depositorFee * MAGNITUDE;
            _actualAmount = _actualAmount - _adminFee - _depositorFee;
            uint256 _totalDeposit = totalDeposit;
            if (_totalDeposit > 0) {
                _totalDeposit += _actualAmount;
                profitPerShare += _dividends / _totalDeposit;
                _dividends = _dividends * _actualAmount / _totalDeposit;
            }
        }

        userInfo[msg.sender].rewardPayouts = getRewardAmount(msg.sender);
        userInfo[msg.sender].totalRewardALA = totalReward;
        totalDeposit += _actualAmount;

        int256 _updatedPayouts = (int256)(profitPerShare * _actualAmount) - int256(_dividends);
        userInfo[msg.sender].depositorFeePayouts += _updatedPayouts;

        uint256 _newDepositedAmount = userInfo[msg.sender].depositedAmount + _actualAmount;
        userInfo[msg.sender].depositedAmount = _newDepositedAmount;

        _usdAmount = _newDepositedAmount * _usdPrice / (10**_decimals) / USD;
        if (_usdAmount >= vip2MinAmount) {
            userInfo[msg.sender].lockedTime = block.timestamp + vip2LockingPeriod;
        } else if (_usdAmount >= _vip1MinAmount) {
            userInfo[msg.sender].lockedTime = block.timestamp + vip1LockingPeriod;
        }

        emit Deposit(msg.sender, _actualAmount, _adminFee, _depositorFee, block.timestamp);
    }

    function withdraw() external nonReentrant checkActive {
        uint256 _withdrawAmount = userInfo[msg.sender].depositedAmount;
        require(_withdrawAmount > 0, "not depositor");
        require(block.timestamp > userInfo[msg.sender].lockedTime, "locked");

        uint256 _depositorFee = getDepositorFeeAmount(msg.sender);
        uint256 _reward = getRewardAmount(msg.sender);

        totalDeposit -= _withdrawAmount;
        userInfo[msg.sender] = UserInfo({
            depositedAmount: 0,
            lockedTime: 0,
            rewardPayouts: 0,
            totalRewardALA: 0,
            depositorFeePayouts: 0
        });

        depositToken.transfer(msg.sender, _withdrawAmount + _depositorFee);
        rewardToken.transfer(msg.sender, _reward);

        emit Withdraw(msg.sender, _withdrawAmount, _depositorFee, _reward, block.timestamp);
    }

    function claim() external nonReentrant checkActive {
        uint256 _depositorFee = getDepositorFeeAmount(msg.sender);
        uint256 _reward = getRewardAmount(msg.sender);
        require(_reward > 0 || _depositorFee > 0, "no reward");

        userInfo[msg.sender].depositorFeePayouts += (int256)(_depositorFee * MAGNITUDE);

        userInfo[msg.sender].rewardPayouts = 0;
        userInfo[msg.sender].totalRewardALA = totalReward;

        depositToken.transfer(msg.sender, _depositorFee);
        rewardToken.transfer(msg.sender, _reward);

        emit Claim(msg.sender, _depositorFee, _reward, block.timestamp);
    }

    /** view functions */
    function getWithdrawAmount(address _user) external view returns (uint256) {
        return userInfo[_user].depositedAmount;
    }

    function getRewardAmount(address _user) public view returns (uint256) {
        require(_user != address(0), "invalid address");

        uint256 _newReward = totalReward - userInfo[_user].totalRewardALA;
        uint256 _rewardAmount = userInfo[_user].rewardPayouts;

        if (_newReward > 0) {
            uint8 _userStatus = getUserStatus(_user);
            uint256 _rewardPercent = _userStatus == 3
                ? vip2RewardPercent
                : _userStatus == 2
                ? vip1RewardPercent
                : rewardPercent;

            _rewardAmount +=
                (_newReward * _rewardPercent * userInfo[_user].depositedAmount)/ totalDeposit / 100;
        }

        return _rewardAmount;
    }

    function getDepositorFeeAmount(address _user) public view returns (uint256) {
        return
            (uint256)(
                (int256)(profitPerShare * userInfo[_user].depositedAmount) - userInfo[_user].depositorFeePayouts
            ) / MAGNITUDE;
    }

    function apyNotVip() external view returns (uint256) {
        /**
         * totalDeposit - total deposited amount
         * APYDENOMINATOR - decimal places, default is 6: 100000000
         * 365 - days of 1 year
         * rewardPercent - user(not vip)'s reward percent, default is 70% of totalReward
         * latestReward - latest reward amount set by the admin
         * rewardCycle - cycle of reward, default is 7 days
         * 100 - denominator (% of rewardPercent)
         */
        uint256 apy = 0;
        if (totalDeposit > 0) {
            apy = (latestReward * APYDENOMINATOR * 365 * rewardPercent) / totalDeposit / rewardCycle / 100;
        }

        return apy;
    }

    function apyOfVip1() external view returns (uint256) {
        /**
         * same as apyNotVip
         * vip1RewardPercent - vip1 user's reward percent, default is 85% of totalReward
         */
        uint256 apy = 0;
        if (totalDeposit > 0) {
            apy = (latestReward * APYDENOMINATOR * 365 * vip1RewardPercent) / totalDeposit / rewardCycle / 100;
        }

        return apy;
    }

    function apyOfVip2() external view returns (uint256) {
        /**
         * same as apyNotVip
         * vip2RewardPercent - vip2 user's reward percent, default is 100% of totalReward
         */
        uint256 apy = 0;
        if (totalDeposit > 0) {
            apy = (latestReward * APYDENOMINATOR * 365 * vip2RewardPercent) / totalDeposit / rewardCycle / 100;
        }

        return apy;
    }

    function getUserInfo(address _user) external view returns (uint256, uint256) {
        return (userInfo[_user].depositedAmount, userInfo[_user].lockedTime);
    }

    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        return price;
    }

    function getUserStatus(address _user) public view returns (uint8) {
        require(_user != address(0), "invalid address");

        uint256 _usdPrice = uint256(getLatestPrice());
        uint256 _decimals = depositTokenDecimals();

        uint256 _usdAmountOfUser = userInfo[_user].depositedAmount * _usdPrice / (10**_decimals) / USD;
        if (_usdAmountOfUser >= vip2MinAmount) {
            // this user is a vip2
            return 3;
        } else if (_usdAmountOfUser >= vip1MinAmount) {
            // this user is a vip1
            return 2;
        }
        // this user is not a vip
        return 1;
    }

    function getMinDepositAmount() external view returns (uint256) {
        return getTokenAmount(minDepositAmount);
    }

    function getVip1MinAmount() external view returns (uint256) {
        return getTokenAmount(vip1MinAmount);
    }

    function getVip2MinAmount() external view returns (uint256) {
        return getTokenAmount(vip2MinAmount);
    }

    function depositTokenDecimals() public view returns (uint8) {
        return depositToken.decimals();
    }

    function getTokenAmount(uint256 _amount) private view returns (uint256) {
        uint256 _usdPrice = uint256(getLatestPrice());
        uint256 _decimals = uint256(depositTokenDecimals());
        return _amount * USD * 10**_decimals / _usdPrice;
    }
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}