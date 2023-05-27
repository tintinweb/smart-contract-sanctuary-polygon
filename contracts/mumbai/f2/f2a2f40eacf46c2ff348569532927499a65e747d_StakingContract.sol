/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract StakingContract {
    address private constant mUSDTAddress = 0xaF966EAfEbc870535d947e5A0CCBf225c6d5d4C5;  // mUSDT contract address
    uint256 private constant APY = 10;  // Annual percentage yield (APY) for staking

    struct Staker {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => Staker) private stakers;

    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        IERC20 mUSDT = IERC20(mUSDTAddress);
        bool success = mUSDT.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");

        Staker storage staker = stakers[msg.sender];
        staker.amount += amount;
        staker.timestamp = block.timestamp;

        emit Staked(msg.sender, amount);
    }

    function unstake() external {
        Staker storage staker = stakers[msg.sender];
        require(staker.amount > 0, "No staked amount");
        require(staker.timestamp + 1 days <= block.timestamp, "Cannot unstake within 24 hours");

        IERC20 mUSDT = IERC20(mUSDTAddress);
        bool success = mUSDT.transfer(msg.sender, staker.amount);
        require(success, "Transfer failed");

        emit Unstaked(msg.sender, staker.amount);

        delete stakers[msg.sender];
    }

    function getStakedAmount(address staker) public view returns (uint256) {
        return stakers[staker].amount;
    }

    function getStakingTimestamp(address staker) public view returns (uint256) {
        return stakers[staker].timestamp;
    }

    function getAPY() public pure returns (uint256) {
        return APY;
    }
}