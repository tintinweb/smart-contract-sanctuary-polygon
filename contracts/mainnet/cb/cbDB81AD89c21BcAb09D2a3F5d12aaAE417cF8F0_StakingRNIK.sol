/**
 *Submitted for verification at polygonscan.com on 2022-11-01
*/

// File: .deps/contracts/interfaces/IV1Rewards.sol


pragma solidity >0.8.0;

interface IV1Rewards {

    function addReward(address _user, uint256 _amount) external;
    function addSwapReward(address _user, uint256 _amount, address _token) external;
    function removeReward(address _user, uint256 _amount) external returns(bool);
    function claimAirdrop(address _ref) external;
    function getRewards(address _address) external view returns(uint256);
    function getClaimedAirdrop(address _address) external view returns(bool);
    function getApprovedCaller(address _address) external view returns(bool);
    function setCallerSetter(address _callerSetter) external;
    function setApprovedCaller(address _caller, bool _approved) external;
    function setAddRewardPaused(bool  _paused) external;
    function setRemoveRewardPaused(bool  _paused) external;
    function setAirdropAmounts(uint256 _amount, uint256 _refAmount) external;
    function enableAirdrop(bool  _enabled) external;
    function addLiquidityReward(address _user, address _token0, address _token1, uint256 _amount0, uint256 _amount1) external;
    function removeSwapReward(address _user, uint256 _amount, address _token) external returns(bool);
    function getApprovedToken(address _address) external view returns(bool);
    function getApprovedTokens(address _token0, address _token1) external view returns(bool,bool);
    function destroySmartContract(address payable _to) external;
}
// File: .deps/contracts/interfaces/IV1StakingRNIK.sol


pragma solidity >0.8.0;

interface IV1StakingRNIK {

    event StakeRNIK(address indexed user, uint);
    event UnstakeRNIK(address indexed user, uint);

    function rewards() external view returns(address);
    function stakingApy() external view returns(uint256);
    function apySetter() external view returns(address);
    function minStakeDuration() external view returns(uint256);
    function stakingOpen() external view returns(bool);
    function stakingCloseDate() external view returns(uint256);

    function stakeRNIK(uint256 _amount) external;
    function unstakeRNIK() external;
    function getInterest(address _account) external view returns(uint256);
    function getUserStake(address _account) external view returns (uint256, uint256); 
    function setRewardsAddress(address _address) external;
    function setApySetter(address _address) external;
    function setStakingApy(uint256 _stakingApy) external;
    function setMinStakeDuration(uint256 _minStakeDuration) external;
    function setStakingOpen(bool _stakingOpen) external;
    function setStakingCloseDate(uint256 _stakingCloseDate) external;
    function destroySmartContract(address payable _to) external;
}
// File: .deps/contracts/StakingRNIK.sol


pragma solidity >0.8.0;



contract StakingRNIK is IV1StakingRNIK {
    
    struct stake{
        uint256 amount;
        uint256 startDate;
    }
    
    address public override rewards; //rewards contract
    uint256 public override stakingApy; //staking apy 2 decimals
    address public override apySetter; //address of the apy setter
    uint256 public override minStakeDuration; //minimum stake duration (3888000 - 45 days)
    bool public override stakingOpen; //pause new stakes
    uint256 public override stakingCloseDate; //staking deadline

    mapping(address => stake) public userStakes;

    modifier onlySetter() {
        require(msg.sender == apySetter, 'TKNV1: Forbidden');
        _;
    }
    
    constructor() {
        apySetter = msg.sender;
        stakingApy = 2000; //20%
        minStakeDuration = 3888000; // 45 days
        stakingOpen = true;
    }


    function stakeRNIK(uint256 _amount) external override{
        require(stakingOpen, 'TokenikV1: Staking is disabled');

        bool useRewards = IV1Rewards(rewards).removeReward(msg.sender, _amount);
        if(useRewards){

            uint256 pendingInterest = getInterestInternal(msg.sender);
            uint256 addAmount = pendingInterest + _amount;
            userStakes[msg.sender].amount += addAmount;
            userStakes[msg.sender].startDate = block.timestamp;

            emit StakeRNIK(msg.sender, _amount);
        }
    }

    function unstakeRNIK() external override{
        
        require(block.timestamp >= (userStakes[msg.sender].startDate + minStakeDuration), 'TKNV1: cannot unstake early');
        require(userStakes[msg.sender].amount > 0,'TKNV1: nothing to unstake');

        uint256 earnedInterest = getInterestInternal(msg.sender);

        uint256 totalAmount = userStakes[msg.sender].amount + earnedInterest;
        userStakes[msg.sender].amount = 0;

        IV1Rewards(rewards).addReward(msg.sender, totalAmount);

        emit UnstakeRNIK(msg.sender, totalAmount);
    }

    function getInterestInternal(address _account) internal view returns(uint256){
        
        uint256 lastDay = block.timestamp;

        if(stakingCloseDate !=0 ){
            if(block.timestamp > stakingCloseDate){
                lastDay = stakingCloseDate;
            }
        }

        uint256 daysStaked = (lastDay - userStakes[_account].startDate) / 86400;

        if(daysStaked == 0) return(0);

        uint256 interestEarned = userStakes[msg.sender].amount * stakingApy * daysStaked / 3650000;

        return interestEarned;
    }

    function getInterest(address _account) external view override returns(uint256){
        return getInterestInternal(_account);
    }


    function getUserStake(address _account) external view override returns (uint256, uint256) {
 
        return (userStakes[_account].amount, userStakes[msg.sender].startDate);
    }

    
    function setRewardsAddress(address _address) external override onlySetter {
        require(_address != address(0), 'TKNV1: cannot set empty address');
        rewards = _address;
    }

    function setApySetter(address _address) external override onlySetter {
        require(_address != address(0), 'TKNV1: cannot set empty address');
        apySetter = _address;
    }

    function setStakingApy(uint256 _stakingApy) external override onlySetter {
        require(_stakingApy > stakingApy,'TKNV1: APY can only be increased');
        stakingApy = _stakingApy;
    }

    function setMinStakeDuration(uint256 _minStakeDuration) external override onlySetter {
        minStakeDuration = _minStakeDuration;
    }

    function setStakingOpen(bool _stakingOpen) external override onlySetter {
        stakingOpen = _stakingOpen;
    }

    function setStakingCloseDate(uint256 _stakingCloseDate) external override onlySetter {
        stakingCloseDate = _stakingCloseDate;
    }

    function destroySmartContract(address payable _to) override external onlySetter {
        selfdestruct(_to);
    }

}