// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface TOKEN {
    function decimals() external view returns(uint8);
    function balanceOf(address account) external view returns(uint256);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    function isExcludedFromBurn(address user) external view returns(bool);
}

contract StakingAlgo3 is ReentrancyGuard {
    struct UserInfo {
        uint256 depositedAmount; // total deposited amount for this user
        uint256 lockedTime; // locked period for claim of this user, ex: 1 year, 3 year
        uint256 totalRefersCount; // refer count this user has received
        uint256 refersPayouts; // refer count that has already been received reward from this user's total refer count
        uint256 rewardPayouts; // current available reward amount at last deposit time
        // ALA is the abbreviation for At the time of the Latest Action
        uint256 totalRewardALA; // total reward amount at last deposit time
        bool isAddRefer; // only 1 refer address can be added per user. if this value is true, you can't add refer anymore
    }

    uint256 public startDate;
    uint256 public totalDeposit; // total deposited amount (user deposit)
    uint256 public totalReward; // total reward amount, not refer (admin + fee)
    uint256 public totalRewardForRefer; // reward amount for refers to this contract (admin)
    uint256 public latestReward; // store the latest reward amount for calculate APY
    // TODO: need to set rewardpercent (vip1RewardPercent, ) logic again
    uint256 public vip1MinAmount = 10000000 * 10**18; // 10m OMH, decimals is 18
    uint256 public vip1LockingPeriod = 60 * 60 * 24 * 365; // 1 year
    uint256 public vip1RewardPercent = 85; // 85% of totalReward
    uint256 public vip2MinAmount = 100000000 * 10**18; // 100m OMH, decimals is 18
    uint256 public vip2LockingPeriod = 60 * 60 * 24 * 365 * 3; // 3 year
    uint256 public vip2RewardPercent = 100; // 100% of totalReward
    uint256 public rewardPercent = 70; // 70% of totalReward

    uint256 public minDepositAmount = 10000 * 10**18; // 10000 OMH, decimals is 18

    // to refer address, give instance 100 OMH reward
    uint256 public rewardPerRefer = 100;
    // when 10 refers, then give more 100*10 OMH rewards
    uint256 public rewardPer10Refer = 1000;
    // when 100 refers, then give more 100*100 OMH rewards
    uint256 public rewardPer100Refer = 10000;

    uint256 public rewardCycle = 7; // 7 days

    uint256 public constant depositFeePercent = 10; // 10%
    uint256 public constant withdrawFeePercent = 10; // 10%
    uint256 public constant APYDENOMINATOR = 100 * 10**6;

    bool public pause = false;

    address public admin;
    TOKEN public OMH;

    mapping(address => UserInfo) private userInfo;

    event Deposit(
        address indexed caller,
        address referAddress,
        uint256 inputDepositAmount,
        uint256 fee,
        uint256 createdAt
    );

    event Redeposit(
        address indexed caller,
        uint256 redepositAmount,
        uint256 fee,
        uint256 createdAt
    );

    event Withdraw(
        address indexed caller,
        uint256 withdrawAmount,
        uint256 fee,
        uint256 rewardAmount,
        uint256 createdAt
    );

    event Claim(address indexed caller, uint256 claimAmount, uint256 createdAt);

    modifier onlyAdmin() {
        require(msg.sender == admin, "caller is not admin");
        _;
    }

    modifier checkActive() {
        require(block.timestamp >= startDate && !pause, "can not do now");
        _;
    }

    // OMH-OMH staking pool
    constructor(uint256 _startDate, address _omh) {
        admin = msg.sender;
        startDate = _startDate;
        OMH = TOKEN(_omh);
    }

    /** only admin functions */
    function changeAdmin(address _new) external onlyAdmin {
        require(_new != address(0), "invalid address");
        admin = _new;
    }

    function changeToken(address _newToken) external onlyAdmin {
        OMH = TOKEN(_newToken);
    }

    function changeStartDate(uint256 _newDate) external onlyAdmin {
        startDate = _newDate;
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
        require(_days != 0);
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
        totalRewardForRefer = 0;
        uint256 _amount = OMH.balanceOf(address(this));
        OMH.transfer(admin, _amount);
    }

    /** external funtions */
    function addRewardNotRefer(uint256 _amount) external onlyAdmin {
        OMH.transferFrom(msg.sender, address(this), _amount);
        // OMH tokens have a burning feature when transferring
        // from the wallet is not ExcludedFromBurn.
        uint256 _burnAmount = getTransferBurnAmount(_amount);
        uint256 _newAmount = _amount - _burnAmount;
        totalReward += _newAmount;
        latestReward = _newAmount;
    }

    function addRewardForRefer(uint256 _amount) external onlyAdmin {
        OMH.transferFrom(msg.sender, address(this), _amount);
        // OMH tokens have a burning feature when transferring
        // from the wallet is not ExcludedFromBurn.
        uint256 _burnAmount = getTransferBurnAmount(_amount);
        totalRewardForRefer += _amount - _burnAmount;
    }

    function deposit(uint256 _amount, address _refer) external nonReentrant checkActive {
        uint256 _timeNow = block.timestamp;
        require(msg.sender != _refer, "can not refer to yourself");

        OMH.transferFrom(msg.sender, address(this), _amount);
        // OMH tokens have a burning feature when transferring
        // from the wallet is not ExcludedFromBurn.
        uint256 _burnAmount = getTransferBurnAmount(_amount);
        uint256 _newAmount = _amount - _burnAmount;

        // add refer address
        // since the deposit amount of the zero address is always 0,
        // there is no need to separately check the zero address.
        // ex: _refer != address(0)
        if (
            !userInfo[msg.sender].isAddRefer &&
            userInfo[_refer].depositedAmount > 0
        ) {
            userInfo[_refer].totalRefersCount += 1;
            userInfo[msg.sender].isAddRefer = true;
        }

        // set new available reward amount before deposit
        userInfo[msg.sender].rewardPayouts = getRewardAmountNotRefer(
            msg.sender
        );

        uint256 _fee = depositOMH(_newAmount);

        uint256 _totalDepositedAmount = userInfo[msg.sender].depositedAmount;
        if (_totalDepositedAmount >= vip2MinAmount) {
            userInfo[msg.sender].lockedTime = _timeNow + vip2LockingPeriod;
        } else if (_totalDepositedAmount >= vip1MinAmount) {
            userInfo[msg.sender].lockedTime = _timeNow + vip1LockingPeriod;
        } else {
            userInfo[msg.sender].lockedTime = _timeNow;
        }

        emit Deposit(msg.sender, _refer, _newAmount - _fee, _fee, _timeNow);
    }

    function redeposit() external nonReentrant checkActive {
        uint256 _redepositAmount = claimReward();
        uint256 _fee = depositOMH(_redepositAmount);

        emit Redeposit(
            msg.sender,
            _redepositAmount - _fee,
            _fee,
            block.timestamp
        );
    }

    function withdraw() external nonReentrant checkActive {
        uint256 _withdrawAmount = userInfo[msg.sender].depositedAmount;
        require(_withdrawAmount > 0, "not depositor");
        require(block.timestamp > userInfo[msg.sender].lockedTime, "locked");

        uint256 _rewardAmount = claimReward();

        totalDeposit -= _withdrawAmount;
        userInfo[msg.sender].depositedAmount = 0;
        userInfo[msg.sender].lockedTime = 0;
        userInfo[msg.sender].totalRefersCount = 0;
        userInfo[msg.sender].refersPayouts = 0;
        userInfo[msg.sender].totalRewardALA = 0;

        uint256 _withdrawFee = 0;
        if (_withdrawAmount < vip1MinAmount) {
            _withdrawFee = (_withdrawAmount * withdrawFeePercent) / 100;
            _withdrawAmount -= _withdrawFee;
            // send withdrawal fee to admin
            OMH.transfer(admin, _withdrawFee);
        }
        OMH.transfer(msg.sender, _withdrawAmount + _rewardAmount);

        emit Withdraw(
            msg.sender,
            _withdrawAmount,
            _withdrawFee,
            _rewardAmount,
            block.timestamp
        );
    }

    function claim() external nonReentrant checkActive {
        uint256 _rewardAmount = claimReward();
        require(_rewardAmount > 0, "no reward");

        userInfo[msg.sender].totalRewardALA = totalReward;

        OMH.transfer(msg.sender, _rewardAmount);

        emit Claim(msg.sender, _rewardAmount, block.timestamp);
    }

    /** view functions */
    function getTransferBurnAmount(uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 burnAmount = 0;
        bool isExcludedAddr = OMH.isExcludedFromBurn(msg.sender);
        if (msg.sender.code.length == 0 && !isExcludedAddr) {
            burnAmount = (_amount * 2) / 100;
        }

        return burnAmount;
    }

    function getWithdrawAmount(address _user) external view returns (uint256) {
        uint256 _withdrawAmount = userInfo[_user].depositedAmount;
        if (_withdrawAmount < vip1MinAmount) {
            _withdrawAmount -= (_withdrawAmount * withdrawFeePercent) / 100;
        }

        return _withdrawAmount;
    }

    function getRewardAmountForRefer(address _user)
        public
        view
        returns (uint256)
    {
        // refers reward
        uint256 _refers = userInfo[_user].totalRefersCount;
        uint256 _refersPayouts = userInfo[_user].refersPayouts;
        uint256 _rewardForRefer = 0;

        if (_refers > _refersPayouts) {
            uint256 _rewardPer100Refer = rewardPer100Refer;
            uint256 _rewardPer10Refer = rewardPer10Refer;

            _rewardForRefer =
                (_refers / 100) * _rewardPer100Refer +
                (_refers / 10) * _rewardPer10Refer +
                (_refers - _refersPayouts) * rewardPerRefer -
                (_refersPayouts / 100) * _rewardPer100Refer -
                (_refersPayouts / 10) * _rewardPer10Refer;
        }

        return _rewardForRefer;
    }

    // get only reward amount, not refer
    function getRewardAmountNotRefer(address _user)
        public
        view
        returns (uint256)
    {
        require(_user != address(0), "invalid address");

        uint256 _depositedAmount = userInfo[_user].depositedAmount;
        uint256 _newReward = totalReward - userInfo[_user].totalRewardALA;
        uint256 _rewardAmount = userInfo[_user].rewardPayouts;

        if (_newReward > 0 && _depositedAmount > 0) {
            uint256 _rewardPercent = _depositedAmount >= vip2MinAmount
                ? vip2RewardPercent
                : _depositedAmount >= vip1MinAmount
                ? vip1RewardPercent
                : rewardPercent;

            _rewardAmount += (_newReward * _rewardPercent * _depositedAmount) / totalDeposit / 100;
        }

        return _rewardAmount;
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
            apy =
                (latestReward * APYDENOMINATOR * 365 * rewardPercent) /
                totalDeposit /
                rewardCycle /
                100;
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
            apy =
                (latestReward * APYDENOMINATOR * 365 * vip1RewardPercent) /
                totalDeposit /
                rewardCycle /
                100;
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
            apy =
                (latestReward * APYDENOMINATOR * 365 * vip2RewardPercent) /
                totalDeposit /
                rewardCycle /
                100;
        }

        return apy;
    }

    function getUserInfo(address _user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        return (
            userInfo[_user].depositedAmount,
            userInfo[_user].lockedTime,
            userInfo[_user].totalRefersCount,
            userInfo[_user].isAddRefer
        );
    }

    /** private functions */
    function depositOMH(uint256 _amount) private returns (uint256) {
        require(
            _amount >= minDepositAmount,
            "amount is less than min deposit amount"
        );

        // deposit fee
        uint256 fee = 0;
        if (_amount < vip1MinAmount) {
            fee = (_amount * depositFeePercent) / 100;
            totalReward += fee;
        }

        uint256 _newDepositAmount = _amount - fee;
        totalDeposit += _newDepositAmount;
        userInfo[msg.sender].depositedAmount += _newDepositAmount;
        userInfo[msg.sender].totalRewardALA = totalReward;

        return fee;
    }

    function claimReward() private returns (uint256) {
        uint256 _rewardNotRefer = getRewardAmountNotRefer(msg.sender);
        uint256 _rewardForRefer = getRewardAmountForRefer(msg.sender);

        if (_rewardForRefer > 0) {
            require(
                totalRewardForRefer >= _rewardForRefer,
                "not enough refers amount yet"
            );
            userInfo[msg.sender].refersPayouts = userInfo[msg.sender]
                .totalRefersCount;
            totalRewardForRefer -= _rewardForRefer;
        }

        userInfo[msg.sender].rewardPayouts = 0;

        return _rewardNotRefer + _rewardForRefer;
    }

    function getUserStatus(address _user) external view returns (uint8) {
        require(_user != address(0), "invalid address");

        uint256 _depositedAmount = userInfo[_user].depositedAmount;
        if (_depositedAmount >= vip2MinAmount) {
            // this user is a vip2
            return 3;
        } else if (_depositedAmount >= vip1MinAmount) {
            // this user is a vip1
            return 2;
        }
        // this user is not a vip
        return 1;
    }

    function depositTokenDecimals() external view returns (uint8) {
        return OMH.decimals();
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