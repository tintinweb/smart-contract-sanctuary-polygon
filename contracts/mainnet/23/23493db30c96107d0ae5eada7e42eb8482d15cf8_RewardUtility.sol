/**
 *Submitted for verification at polygonscan.com on 2022-07-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;


interface IUnlock
    {
    function withdrawReward() external;
    }


interface IStaking
    {
    function claimRewards() external;
    }


contract RewardUtility
	{
    IUnlock public unlock;
    IStaking public staking;


    constructor()
        {
        unlock = IUnlock( 0x930A7Dc10ae084FBbddC6537D7df7d4c65a40944 );
        staking = IStaking( 0x4D9c2A712E806820e66783f47344613F29f52b79 );
        }


    function claimRewards()
        external
        {
        unlock.withdrawReward();
        staking.claimRewards();
        }
    }