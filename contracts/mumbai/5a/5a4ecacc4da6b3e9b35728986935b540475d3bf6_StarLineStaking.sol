/**
 *Submitted for verification at polygonscan.com on 2023-06-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


contract StarLineStaking is Ownable {
    struct userStakeData {
        uint256 amount;
        uint256 claimedApr;
        uint256 startTime;
        uint256 endTime;
        uint256 lastWithdrawTime;
        uint256 percentPerInterval;
        uint256 lockupPeriod;
        bool isClaimed;
        bool isActive;
    }

    struct User {
        bool isExists;
        userStakeData[] stakes;
        uint256 totalStaked;
        uint256 totalWithdrawn;
        uint256 stakingCount;
    }

    uint256[] public minAmounts;
    uint256[] public stakingPeriod;
    uint256[] public aprPercent;
    uint256[] public lockupPeriod;
    IERC20 public token;
    mapping(address => User) public users;
    uint256 public percentDivider;

    constructor() {

        token = IERC20(0x30CAc8312fB08ce6972e8C50eBeB5845B3e9e5E8);
        minAmounts = [
            50000 * (10 ** token.decimals()),
            100000 * (10 ** token.decimals()),
            250000 * (10 **  token.decimals()),
            500000 * (10 **  token.decimals()),
            1000000 * (10 **  token.decimals())
        ];

        stakingPeriod = [
            30 minutes,
            60 minutes,
            90 minutes,
            180 minutes,
            365 minutes
        ];

        aprPercent = [333333, 222222, 185185, 111111, 68493];
        lockupPeriod = [0, 30 minutes, 90 minutes, 90 minutes, 120 minutes];
        percentDivider = 100 * 1e8;
    }

    function stake(uint256 amount, uint256 plan) external {
        User storage user = users[msg.sender];
        require(plan < aprPercent.length, "Invalid Plan");
        require(
            amount >= minAmounts[plan],
            "Amount is less than min plan amount limit"
        );

        token.transferFrom(msg.sender, address(this), amount);

        (!user.isExists) ? (user.isExists = true) : true;
        user.totalStaked += amount;
        user.stakingCount++;

        user.stakes.push(
            userStakeData(
                amount,
                0,
                block.timestamp,
                block.timestamp + stakingPeriod[plan],
                block.timestamp,
                aprPercent[plan],
                block.timestamp + lockupPeriod[plan],
                false,
                true
            )
        );
    }

    function claimApr(uint256 _index) external {
        User storage user = users[msg.sender];
        require(user.stakes.length > _index, "Invalid Staking Index");
        require(
            !user.stakes[_index].isClaimed,
            "You already claimed your reward"
        );
        require(
            user.stakes[_index].isActive,
            "You cannot claim reward becuase you already withdrawn funds"
        );
        require(
            user.stakes[_index].lastWithdrawTime < user.stakes[_index].endTime,
            "You already claimed your Apr"
        );
        uint256 amount = getCurrentClaimableReward(msg.sender, _index);
        token.transfer(msg.sender, amount);

        user.stakes[_index].claimedApr += amount;

        user.stakes[_index].lastWithdrawTime = block.timestamp;

        if (block.timestamp >= user.stakes[_index].endTime) {
            user.stakes[_index].isClaimed = true;
        }
    }

    function getCurrentClaimableReward(address _user, uint256 _index)
        public
        view
        returns (uint256)
    {
        User storage user = users[_user];
        return (
            (!user.stakes[_index].isClaimed &&
                user.stakes[_index].isActive &&
                user.stakes[_index].lastWithdrawTime <
                user.stakes[_index].endTime)
                ? ((((
                    (block.timestamp >= user.stakes[_index].endTime)
                        ? user.stakes[_index].endTime
                        : block.timestamp
                ) - user.stakes[_index].lastWithdrawTime) *
                    user.stakes[_index].amount *
                    user.stakes[_index].percentPerInterval) / percentDivider)
                : 0
        );
    }

    function withdrawAmount(uint256 _index) external {
        User storage user = users[msg.sender];
        require(
            user.stakes[_index].amount > 0,
            "You did not stake at this index"
        );
        require(user.stakes[_index].isActive, "You already withdrawn amount");
        require(
            block.timestamp >= user.stakes[_index].lockupPeriod,
            "You cannot withdraw before lockup time ends"
        );

        // token.transfer(msg.sender, user.stakes[_index].amount);
        user.stakes[_index].isActive = false;
    }

    function viewPlans(uint256 _index)
        external
        view
        returns (
            uint256 minimumAmount,
            uint256 stakingTime,
            uint256 percentage,
            uint256 lockupTime
        )
    {
        minimumAmount = minAmounts[_index];
        stakingTime = stakingPeriod[_index];
        percentage = aprPercent[_index];
        lockupTime = lockupPeriod[_index];
    }

    function viewStaking(address _user, uint256 _index)
        external
        view
        returns (
            uint256 amount,
            uint256 claimedApr,
            uint256 startTime,
            uint256 endTime,
            uint256 lastWithdrawTime,
            uint256 percentPerInterval,
            uint256 lockupTime,
            bool isClaimed,
            bool isActive
        )
    {
        User storage user = users[_user];
        amount = user.stakes[_index].amount;
        claimedApr = user.stakes[_index].claimedApr;
        startTime = user.stakes[_index].startTime;
        endTime = user.stakes[_index].endTime;
        lastWithdrawTime = user.stakes[_index].lastWithdrawTime;
        percentPerInterval = user.stakes[_index].percentPerInterval;
        lockupTime = user.stakes[_index].lockupPeriod;
        isClaimed = user.stakes[_index].isClaimed;
        isActive = user.stakes[_index].isActive;
    }

    function changePlan(
        uint256 _planIndex,
        uint256 minimumAmount,
        uint256 stakingTime,
        uint256 percentage,
        uint256 lockupTime
    ) external onlyOwner {
        minAmounts[_planIndex] =  minimumAmount ;
        stakingPeriod[_planIndex] = stakingTime;
        aprPercent[_planIndex] = percentage;
         lockupPeriod[_planIndex] = lockupTime;
    }

    function changeStakingToken(IERC20 _token) external onlyOwner{
        token  = _token;
    }

    function withdrawFunds(IERC20 _token , uint256 _amount) external onlyOwner{
        _token.transfer(msg.sender,_amount);
    }
}