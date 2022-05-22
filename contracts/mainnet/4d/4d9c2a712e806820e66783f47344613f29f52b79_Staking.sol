// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "Ownable.sol";
import "IERC20.sol";

contract Staking is Ownable
	{
    IERC20 public unlock;

    uint256 public constant MIN_DEPOSIT_DAYS = 7;
    uint256 public constant MAX_DEPOSIT_DAYS = 4 * 365;

    uint256 public constant ONE_YEAR = 365 days; // ONE YEAR in seconds
    uint256 public constant ONE_DAY = 1 days; // ONE DAY in seconds

    uint256 public startTime;

    struct Stake
        {
        uint256 unlockAmount;
        uint256 xUnlockAmount;
        uint256 startingDay;
        uint256 endingDay;
        bool unstaked; // note that this is not updated for the stakes mapping, only for stakesByUser
        }

    mapping(address => Stake[]) private stakesByUser;
    mapping(address => uint256) public lastClaimedDayByUser;
    Stake[] private stakes;

    mapping(uint256 => uint256) public rewardsByDay;
    mapping(uint256 => uint256) public totalXUnlockByDay;

    uint256 public lastDayWithRewardsSet;
    uint256 public tempSum;

    event UnlockStaked
        (
        address indexed user,
        uint256 amount,
        uint256 indexed startingDay,
        uint256 indexed endingDay );

    event RewardClaimed
        (
        address indexed user,
        uint256 amount,
        uint256 indexed day,
        uint256 indexed stakeId );

    event UnlockUnstaked
        (
        address indexed user,
        uint256 indexed stakeId,
        uint256 amount );

    event XUnlockSetForDay (
        uint256 indexed day,
        uint256 indexed value );


    constructor()
        {
        startTime = block.timestamp;
        lastDayWithRewardsSet = 0;
        }


    function setUnlockAddress(address unlockAddress)
        public onlyOwner
        {
        unlock = IERC20( unlockAddress );
        }


    function _currentDay()
        private view returns (uint256)
        {
        return (block.timestamp - startTime) / ONE_DAY;
        }


    function currentDay()
        external view returns (uint256)
        {
        return _currentDay();
        }


    function numberOfStakes()
        external view returns (uint256)
        {
        return stakes.length;
        }

    function stakeUnlock( uint256 unlockAmount, uint256 durationInDays )
        external
        {
        require
            ( durationInDays >= MIN_DEPOSIT_DAYS &&
            durationInDays <= MAX_DEPOSIT_DAYS,
            "Invalid staking duration" );

        uint256 xUnlockAmount = unlockAmount * durationInDays / ( ONE_YEAR / ONE_DAY );

        uint256 startingDay = ( block.timestamp - startTime ) / ONE_DAY;

        uint256 endingDay = startingDay + durationInDays - 1;

        Stake memory stake = Stake
            (
            unlockAmount,
            xUnlockAmount,
            startingDay,
            endingDay,
            false
            );

        stakesByUser[msg.sender].push(stake);
        stakes.push(stake);

        unlock.transferFrom( msg.sender, address(this), unlockAmount );

        emit UnlockStaked( msg.sender, unlockAmount, startingDay, endingDay );
        }


    function claimRewards()
        external
        {
        uint256 length = stakesByUser[msg.sender].length;
        uint256 totalOwed;

        for ( uint256 i = 0; i < length; i++ )
            {
            Stake storage userStake = stakesByUser[msg.sender][i];

            uint256 lastClaimedDay = lastClaimedDayByUser[msg.sender];
            uint256 startingDay
                = lastClaimedDay == 0 || userStake.startingDay > lastClaimedDay
                ? userStake.startingDay : lastClaimedDay + 1;

            uint256 endingDay
                = userStake.endingDay > lastDayWithRewardsSet
                ? lastDayWithRewardsSet : userStake.endingDay;

            if ( lastClaimedDay == endingDay ) continue;

            for ( uint256 day = startingDay; day <= endingDay; day++ )
                {
                uint256 xUnlockAmountByDay = getXUnlockAmountForStakeOnDay( userStake, day );

                uint256 totalRewardAmount = rewardsByDay[day];
                uint256 totalXUnlockAmount = totalXUnlockByDay[day];

                if  ( xUnlockAmountByDay != 0 &&
                    totalRewardAmount != 0 &&
                    totalXUnlockAmount != 0 )
                    {
                    uint256 userReward = totalRewardAmount * xUnlockAmountByDay / totalXUnlockAmount;

                    totalOwed += userReward;

                    emit RewardClaimed( msg.sender, userReward, day, i );
	                }
                }
            }

        lastClaimedDayByUser[msg.sender] = lastDayWithRewardsSet;
        unlock.transfer(msg.sender, totalOwed);
        }


	// Unstake unlock from all the stakes that have fully matured
	function unstakeUnlock()
		external
		{
        uint256 length = stakesByUser[msg.sender].length;
		uint256 totalToUnstake = 0;

		uint256 day = ( block.timestamp - startTime ) / ONE_DAY;

        for ( uint256 i = 0; i < length; i++ )
            {
            Stake storage userStake = stakesByUser[msg.sender][i];

            if ( ! userStake.unstaked )
            if ( day > userStake.endingDay  )
                {
		        userStake.unstaked = true;

				uint256 amount = userStake.unlockAmount;

		        totalToUnstake = totalToUnstake + amount;

		        emit UnlockUnstaked( msg.sender, i, amount );
				}
            }

		if ( totalToUnstake > 0 )
	        unlock.transfer( msg.sender, totalToUnstake );
		}


    function clearTempSum()
        public onlyOwner
        {
        tempSum = 0;
        }


    function addXUnlockAmountToTempSum( uint256 day, uint256 startIndex, uint256 endIndex )
        external onlyOwner
		{
        require( day == ( lastDayWithRewardsSet + 1 ),
            "Day totals must be updated in sequence" );

        uint256 tempSum2;
        for ( uint256 i = startIndex; i <= endIndex; i++ )
            tempSum2 += getXUnlockAmountForStakeOnDay( stakes[i], day );

        tempSum += tempSum2;
        }


    function setXUnlockForDayToTempSumAndSpecifyRewards( uint256 day, uint256 rewardAmount )
        external onlyOwner
        {
        uint256 lastTimestampForDay = startTime + ( day * ONE_DAY );

        require( block.timestamp > lastTimestampForDay,
            "Day totals must be updated in sequence" );

        require( day == ( lastDayWithRewardsSet + 1 ),
            "Days must be updated in sequence" );

		// Set the total for the day
        totalXUnlockByDay[day] = tempSum;

        // Set the rewards for the day
        // These will be transferred from the sender/owner
        // Only send the rewards if there is xUNLOCK for the day
        if ( tempSum > 0 )
		if ( rewardAmount > 0 )
	        unlock.transferFrom( msg.sender, address( this ), rewardAmount );

        rewardsByDay[day] = rewardAmount;
        lastDayWithRewardsSet = day;

        emit XUnlockSetForDay( day, tempSum );

        clearTempSum();
        }


	// Not normally used - requires that the node be synced past the point of the end of the specified day
    function setXUnlockForDayAndSpecifyRewards( uint256 day, uint256 xunlockAmount, uint256 rewardAmount )
        external onlyOwner
        {
        uint256 lastTimestampForDay = startTime + ( day * ONE_DAY );

        require( block.timestamp > lastTimestampForDay,
            "Day totals must be updated in sequence" );

        require( day == ( lastDayWithRewardsSet + 1 ),
            "Days must be updated in sequence" );

		// Set the total for the day
        totalXUnlockByDay[day] = xunlockAmount;

        // Set the rewards for the day
        // These will be transferred from the sender/owner
        // Only send the rewards if there is xUNLOCK for the day
        if ( xunlockAmount > 0 )
		if ( rewardAmount > 0 )
	        unlock.transferFrom( msg.sender, address( this ), rewardAmount );

        rewardsByDay[day] = rewardAmount;
        lastDayWithRewardsSet = day;

        emit XUnlockSetForDay( day, xunlockAmount );
        }


    function forceSpecifyRewardsForDay( uint256 day, uint256 rewardAmount )
        external onlyOwner
        {
        rewardsByDay[day] = rewardAmount;
	    }


    function forceSendUnlock( address wallet, uint256 amount )
        external onlyOwner
	    {
        unlock.transfer( wallet, amount );
        }


    function forceCreateStake( address wallet, uint256 unlockAmount, uint256 xUnlockAmount, uint256 startingDay, uint256 endingDay, bool unstaked )
        external onlyOwner
        {
        Stake memory stake = Stake(
            unlockAmount,
            xUnlockAmount,
            startingDay,
            endingDay,
			unstaked );

        stakesByUser[wallet].push( stake );
        stakes.push( stake );
        }


    function getAllStakes()
        external view returns ( Stake[] memory )
        {
        return stakes;
        }


    function getStake( uint256 stakeIndex )
        external view returns (Stake memory)
        {
        return stakes[stakeIndex];
        }


    function getAllStakesByUser( address user )
        external view returns (Stake[] memory)
        {
        return stakesByUser[user];
        }


    function getAllStakeByUser( address user, uint256 stakeIndex )
        external view returns (Stake memory)
        {
        return stakesByUser[user][stakeIndex];
        }


	// Unstake unlock from all the stakes that have fully matured
    function currentAmountStakedUnlock( address wallet )
        external view returns ( uint256 amount )
        {
        uint256 length = stakesByUser[wallet].length;

        uint256 totalStaked = 0;

        for ( uint256 i = 0; i < length; i++ )
            {
            Stake storage userStake = stakesByUser[wallet][i];

            if ( ! userStake.unstaked )
                totalStaked = totalStaked + userStake.unlockAmount;
            }

        return totalStaked;
        }


    function _getXUnlockAmountForUserOnDay( address user, uint256 day )
        private view returns (uint256)
        {
        Stake[] storage userStakes = stakesByUser[user];
        uint256 length = userStakes.length;

        uint256 totalXUnlock;
        for (uint256 i = 0; i < length; i++)
            totalXUnlock += getXUnlockAmountForStakeOnDay( userStakes[i], day );

        return totalXUnlock;
	    }

    function getXUnlockAmountForUserOnDay( address user, uint256 day )
        external view returns (uint256)
        {
        return _getXUnlockAmountForUserOnDay( user, day );
	    }


    function getCurrentXUnlockAmountForUser( address user )
        external view returns (uint256)
        {
        uint256 day = _currentDay();

        return _getXUnlockAmountForUserOnDay( user, day );
	    }


	// Unstake unlock from all the stakes that have fully matured
    function unstakableUnlock( address wallet )
        external view returns ( uint256 amount )
        {
        uint256 day = _currentDay();

        uint256 length = stakesByUser[wallet].length;
        uint256 totalToUnstake = 0;

        for ( uint256 i = 0; i < length; i++ )
            {
            Stake storage userStake = stakesByUser[wallet][i];

            if ( ! userStake.unstaked )
            if ( day > userStake.endingDay  )
                totalToUnstake = totalToUnstake + userStake.unlockAmount;
            }

        return totalToUnstake;
        }


    function claimableRewards( address wallet )
        external view returns ( uint256 amount )
        {
        uint256 length = stakesByUser[wallet].length;
        uint256 totalOwed;

        for ( uint256 i = 0; i < length; i++ )
            {
            Stake storage userStake = stakesByUser[wallet][i];

            uint256 lastClaimedDay = lastClaimedDayByUser[wallet];
            uint256 startingDay = lastClaimedDay == 0 || userStake.startingDay > lastClaimedDay
				? userStake.startingDay : lastClaimedDay + 1;

            uint256 endingDay = userStake.endingDay > lastDayWithRewardsSet
                ? lastDayWithRewardsSet : userStake.endingDay;

            if ( lastClaimedDay == endingDay )
                continue;

            for ( uint256 day = startingDay; day <= endingDay; day++ )
                {
                uint256 xUnlockAmountByDay = getXUnlockAmountForStakeOnDay( userStake, day );

                uint256 totalRewardAmount = rewardsByDay[day];
                uint256 totalXUnlockAmount = totalXUnlockByDay[day];

                if  ( xUnlockAmountByDay != 0 &&
                    totalRewardAmount != 0 &&
                    totalXUnlockAmount != 0 )
                    {
                    uint256 userReward = totalRewardAmount * xUnlockAmountByDay / totalXUnlockAmount;

                    totalOwed += userReward;
                    }
                }
            }

        return totalOwed;
        }


    function getXUnlockAmountForStakeOnDay( Stake memory stake, uint256 day )
        private pure returns (uint256)
		{
        if ( stake.endingDay < day || day < stake.startingDay )
            return 0;

        uint256 totalDays = stake.endingDay - stake.startingDay + 1;

        uint256 remainingDays = stake.endingDay - day + 1;

        return stake.xUnlockAmount * remainingDays / totalDays;
        }


    function getXUnlockAmountByUserStake( address user, uint256 stakeId, uint256 day )
        public view returns (uint256)
            {
            return getXUnlockAmountForStakeOnDay( stakesByUser[user][stakeId], day );
		    }


    function getTotalXUnlockAmountOnDay( uint256 day )
        public view returns (uint256)
            {
            return totalXUnlockByDay[day];
		    }




    function markLastDayClaimedForUser( address user, uint256 day ) external onlyOwner
        {
        lastClaimedDayByUser[user] = day;
        }
    }