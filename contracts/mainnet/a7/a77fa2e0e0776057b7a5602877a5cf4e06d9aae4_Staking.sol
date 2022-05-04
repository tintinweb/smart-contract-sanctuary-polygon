// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "Ownable.sol";
import "IUnlock.sol";

contract Staking is Ownable {
    IUnlock public unlock;

    uint256 public constant MIN_DEPOSIT_DURATION = 7; // 7 minutes
    uint256 public constant MAX_DEPOSIT_DURATION = 4 * (12 * 30 + 5); // 6:05

    uint256 public constant ONE_YEAR = 12 * 30 minutes + 5 minutes; // 6:05
    uint256 public constant ONE_DAY = 1 minutes; // 1 minute for sim

    uint256 public startTime;

    struct Stake {
        uint256 unlockAmount;
        uint256 xUnlockAmount;
        uint256 startingDay;
        uint256 endingDay;
        bool unstaked;
    }

    mapping(address => Stake[]) private stakesByUser;
    mapping(address => uint256) public lastClaimedDayByUser;
    Stake[] private stakes;

    mapping(uint256 => uint256) public rewardsByDay;
    mapping(uint256 => uint256) public totalXUnlockByDay;

    uint256 public rewardSetTillDay;
    uint256 public tempSum;

    event UnlockStaked(
        address indexed user,
        uint256 amount,
        uint256 indexed startingDay,
        uint256 indexed endingDay
    );

    event RewardClaimed(
        address indexed user,
        uint256 amount,
        uint256 indexed day,
        uint256 indexed stakeId
    );

    event UnlockUnstaked(
        address indexed user,
        uint256 indexed stakeId,
        uint256 amount
    );

    event XUnlockSetForDay(
        uint256 indexed day,
        uint256 indexed value
    );

    constructor() {
        startTime = block.timestamp;
        rewardSetTillDay = 0;
    }

  function setUnlockAddress(address unlockAddress) public onlyOwner {
    unlock = IUnlock(unlockAddress);
  }


    function currentDay()
        external
        view
        returns (uint256)
        {
        return (block.timestamp - startTime) / ONE_DAY;

        }


    function stakeUnlock(uint256 unlockAmount, uint256 durationInDays) external {
        require(
            durationInDays >= MIN_DEPOSIT_DURATION
            || durationInDays <= MAX_DEPOSIT_DURATION,
            "Staking::stakeUnlock: Incorrect duration in days provided"
        );

        uint256 xUnlockAmount
            = unlockAmount * durationInDays / (ONE_YEAR / ONE_DAY);

        uint256 startingDay
            = (block.timestamp - startTime + ONE_DAY) / ONE_DAY;

        uint256 endingDay = startingDay + durationInDays - 1;

        Stake memory stake = Stake(
            unlockAmount,
            xUnlockAmount,
            startingDay,
            endingDay,
            false
        );

        stakesByUser[msg.sender].push(stake);
        stakes.push(stake);

        unlock.transferFrom(
            msg.sender,
            address(this),
            unlockAmount
        );

        emit UnlockStaked(
            msg.sender,
            unlockAmount,
            startingDay,
            endingDay
        );
    }

    function claimRewards() external {
        uint256 length = stakesByUser[msg.sender].length;
        uint256 totalOwed;

        for (uint256 i = 0; i < length; i++) {
            Stake storage userStake = stakesByUser[msg.sender][i];

            uint256 lastClaimedDay = lastClaimedDayByUser[msg.sender];
            uint256 startingDay
                = lastClaimedDay == 0 || userStake.startingDay > lastClaimedDay
                    ? userStake.startingDay
                    : lastClaimedDay + 1;

            uint256 endingDay = userStake.endingDay > rewardSetTillDay
                ? rewardSetTillDay
                : userStake.endingDay;

            if (lastClaimedDay == endingDay) continue;

            for (uint256 day = startingDay; day <= endingDay; day++) {
                uint256 xUnlockAmountByDay
                    = getXUnlockAmountByDay(userStake, day);

                uint256 totalRewardAmount = rewardsByDay[day];
                uint256 totalXUnlockAmount = totalXUnlockByDay[day];
                if (
                    xUnlockAmountByDay != 0
                    && totalRewardAmount != 0
                    && totalXUnlockAmount != 0
                ) {
                    uint256 userReward = totalRewardAmount
                        * xUnlockAmountByDay
                        / totalXUnlockAmount;

                    totalOwed += userReward;

                    emit RewardClaimed(
                        msg.sender,
                        userReward,
                        day,
                        i
                    );
                }
            }
        }

        lastClaimedDayByUser[msg.sender] = rewardSetTillDay;
        unlock.transfer(msg.sender, totalOwed);
    }

    function markAsClaimed(address user) external onlyOwner {
        lastClaimedDayByUser[user] = rewardSetTillDay;
    }

    function unstakeUnlock(uint256 stakeId) external {
        Stake storage userStake = stakesByUser[msg.sender][stakeId];

        require(
            !userStake.unstaked,
            "Staking::unstakeUnlock: Unlock tokens are already unstaked"
        );

        require(
            userStake.endingDay <= ((block.timestamp - startTime) / ONE_DAY),
            "Staking::unstakeUnlock: Stake is still locked"
        );

        userStake.unstaked = true;

        uint256 amount = userStake.unlockAmount;
        unlock.transfer(msg.sender, amount);

        emit UnlockUnstaked(
            msg.sender,
            stakeId,
            amount
        );
    }

    function getXUnlockAmountByDay(
        Stake memory stake,
        uint256 onDay
    )
        private
        pure
        returns (uint256)
    {
        if (stake.endingDay < onDay || onDay < stake.startingDay) return 0;

        uint256 totalDays
            = stake.endingDay - stake.startingDay + 1;

        uint256 remainingDays = stake.endingDay - onDay + 1;

        return
            stake.xUnlockAmount
                * remainingDays
                / totalDays;
    }

    function getXUnlockAmountByUserStake(
        address user,
        uint256 stakeId,
        uint256 day
    ) public view returns (uint256) {
        return
            getXUnlockAmountByDay(
                stakesByUser[user][stakeId],
                day
            );
    }

    function getXUnlockAmountByUser(address user, uint256 day)
        external
        view
        returns (uint256)
    {
        Stake[] storage userStakes = stakesByUser[user];
        uint256 length = userStakes.length;

        uint256 totalXUnlock;
        for (uint256 i = 0; i < length; i++)
            totalXUnlock += getXUnlockAmountByDay(
                userStakes[i],
                day
            );

        return totalXUnlock;
    }

    function clearTempSum() public onlyOwner {
        tempSum = 0;
    }

    function addXUnlockAmountToTempSum(
        uint256 day,
        uint256 startIndex,
        uint256 endIndex
    ) external onlyOwner {
        uint256 _tempSum;
        for (uint256 i = startIndex; i <= endIndex; i++)
            _tempSum += getXUnlockAmountByDay(stakes[i], day);

        tempSum += _tempSum;
    }

    function setXUnlockForDay(
        uint256 day
    ) external onlyOwner {
        uint256 lastValidTimestamp = startTime + (day * ONE_DAY);

        require(
            block.timestamp > lastValidTimestamp,
            "Staking::setXUnlockForDay: an outdated day is provided"
        );

        uint256 _tempSum = tempSum;
        totalXUnlockByDay[day] = _tempSum;
        clearTempSum();

        emit XUnlockSetForDay(day, _tempSum);
    }

    function setRewardsForDay(
        uint256 day,
        uint256 rewardAmount
    ) external onlyOwner {
        uint256 lastValidTimestamp
            = startTime + (day * ONE_DAY);

        require(
            block.timestamp > lastValidTimestamp,
            "Staking::setRewardsForDay: an outdated day is provided"
        );

        require(
            day == (rewardSetTillDay + 1),
            "Staking::setRewardsForDay: incorrect day is provided"
        );

        unlock.transferFrom(
            msg.sender,
            address(this),
            rewardAmount
        );

        rewardsByDay[day] = rewardAmount;
        rewardSetTillDay = day;
    }

    function forceSpecifyRewardsForDay(
        uint256 day,
        uint256 rewardAmount
    ) external onlyOwner {
        rewardsByDay[day] = rewardAmount;
        rewardSetTillDay = day;
    }

    function forceSendUnlock(
        address wallet,
        uint256 amount
    )
        external
        onlyOwner
    {
        unlock.transfer(wallet, amount);
    }

    function getAllStakes()
        external
        view
        returns (Stake[] memory)
    {
        return stakes;
    }

    function getAllStakesByUser(address user)
        external
        view
        returns (Stake[] memory)
    {
        return stakesByUser[user];
    }
}