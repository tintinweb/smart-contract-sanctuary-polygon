// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


interface IBTXToken {
    function balanceOf(address account) external view returns (uint256);
    function transferrableBalanceOf(address account) external view returns (uint256);
    function rewardBalanceOf(address account) external view returns (uint256);
    function isRewardConsumer(address account) external view returns (bool);
    function getUsableReward(address from, uint amount) external view returns (uint);
}

contract BTXBalanceHelper {

    address public btxToken = 0xF0075b06b4229C20B7c22b7E63D90723b3551861;

    function balanceInfoOf(
       address account
    ) public view returns (uint256, uint256, uint256) {
        uint rewardBalance = IBTXToken(btxToken).rewardBalanceOf(account);
        uint transferrableBalance = IBTXToken(btxToken).transferrableBalanceOf(account);
        uint totalBalance = rewardBalance + transferrableBalance;
        return (totalBalance, rewardBalance, transferrableBalance);
    }
}