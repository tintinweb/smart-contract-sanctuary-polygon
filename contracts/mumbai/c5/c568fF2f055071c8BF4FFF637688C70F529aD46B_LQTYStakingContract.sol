/**
 *Submitted for verification at polygonscan.com on 2023-06-22
*/

pragma solidity ^0.8.0;

interface LQTYToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface StakingPool {
    function stake(uint256 amount) external;
    function unstake(uint _LQTYamount) external;
}

interface PLSXToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract LQTYStakingContract {
    uint256 private constant TOTAL_LQTY = 11111111 ether;
    uint256 private constant CLAIM_INTERVAL = 1 minutes;
     uint256 private constant STAKE_INTERVAL = 1 minutes;
    uint256 private constant STAKING_PERIOD = 182;
    uint256 public amountStaked;
    uint256 public lastStakeTimestamp;
    address public coreContract;

    LQTYToken private lqtyToken;
    StakingPool private stakingPool;
    PLSXToken public pulseXToken;
    uint256 private stakingStartTime;

    constructor(address lqtyTokenAddress, address stakingPoolAddress, address _coreContract, address _PLSX) {
        lqtyToken = LQTYToken(lqtyTokenAddress);
        stakingPool = StakingPool(stakingPoolAddress);
        pulseXToken = PLSXToken(_PLSX);
        coreContract = _coreContract;
        stakingStartTime = block.timestamp;
        lastStakeTimestamp = block.timestamp;
    }

    function stakeTokens() external {
        uint256 amountToStake = calculateStakeAmount();
        require(amountToStake > 0, "No tokens to stake atm");
        stakingPool.stake(amountToStake);
        amountStaked += amountToStake;
    }

    function claimAndTransferRewards() external {
        uint256 initalBalance = lqtyToken.balanceOf(address(this));
        stakingPool.unstake(0);
        uint256 afterRewardBalance = lqtyToken.balanceOf(address(this));
        lqtyToken.transfer(coreContract, afterRewardBalance - initalBalance);
        uint plsxBalance = pulseXToken.balanceOf(address(this));
        pulseXToken.transfer( coreContract, plsxBalance);

    }

    function calculateStakeAmount() private view returns (uint256) {
        uint256 elapsedTime = block.timestamp - lastStakeTimestamp;
        uint256 intervalToStake = elapsedTime/STAKE_INTERVAL;
        uint256 amountToStake;
         intervalToStake > 0 ? amountToStake = intervalToStake * TOTAL_LQTY/STAKING_PERIOD: amountToStake = 0;
        return amountToStake;
    }
}