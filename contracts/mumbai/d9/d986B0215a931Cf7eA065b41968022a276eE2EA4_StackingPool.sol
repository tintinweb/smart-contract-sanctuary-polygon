pragma solidity 0.8.9;
contract StackingPool{
    IERC20 public immutable stackingToken;
    IERC20 public immutable rewardsToken;
    address public owner;
    //Duration  of rewards  to be paid out
    uint public duration;
    //Timestamp of when the rewards finish
    uint public finishAt;
    
    //minimum of last updated time and reward finish time
    uint public updatedAt;
    
    //Reward to be paid out per second

    uint public rewardRate;
    //sum of reward rate * dt * 1e18 / total supply)
    uint public rewardPerTokenStored;
    //User address Reward per token stored 
    mapping(address  => uint)public userRewardPerTokenPaid;
    //User address rewards to be claimed
    mapping(address => uint)public rewards;
    //Total stacked
    uint public totalSupply;

    //User adddress staked amount
    mapping(address => uint)public balanceOf;


    constructor(address _stackingToken,address _rewardToken){
        owner = msg.sender;
        stackingToken = IERC20(_stackingToken);
        rewardsToken = IERC20(_rewardToken);
    } 

    modifier onlyOwner(){
        require(msg.sender == owner,'not authorized');
        _;
    }

    modifier updateReward(address _account){
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();
        if(_account  != address(0)){
            rewards[_account]=earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable()public view returns(uint){
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken() public view returns(uint){
        if(totalSupply == 0){
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored +(rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /totalSupply;
    }

    function stake(uint _amount)external updateReward(msg.sender){
        require(_amount >0, "amount = 0");
        stackingToken.transferFrom(msg.sender,address(this), _amount);
        balanceOf[msg.sender]+=_amount;
        totalSupply += _amount;
    }

    function withdraw(uint _amount)external updateReward(msg.sender){
        require(_amount >0,'amount = 0');
        balanceOf[msg.sender]-= _amount;
        totalSupply -= _amount;
        stackingToken.transfer(msg.sender,_amount);
    }

    function earned(address _account)public view returns(uint){
        return ((balanceOf[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    function getReward()external updateReward(msg.sender){
        uint reward = rewards[msg.sender];
        if(reward>0){
            rewards[msg.sender]=0;
            rewardsToken.transfer(msg.sender,reward);
        }
    }

    function setRewardDuration(uint _duration)external onlyOwner{
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
    }

    function notifyRewardAmount(uint _amount)external onlyOwner updateReward(address(0)){
        if(block.timestamp>=finishAt){
            rewardRate  = _amount/duration;
        }else{
            uint remainingRewards = (finishAt-block.timestamp)*rewardRate;
            rewardRate = (_amount + remainingRewards)/duration;
        }
        require(rewardRate>0,'reward rate = 0');
        require(rewardRate * duration<= rewardsToken.balanceOf(address(this)),"reward amount > balannce");
        finishAt = block.timestamp+duration;
        updatedAt = block.timestamp;
    }

    function _min(uint x,uint y)private pure returns(uint){
        return x<=y?x:y;
    }
}


interface IERC20{
    function totalSupply() external view returns (uint);
    function balanceOf(address account)external view returns(uint);
    function transfer(address recipient,uint amount)external view returns(bool);
    function allowance(address owner, address spender)external view returns(uint);
    function approve(address spender,uint amount)external returns(bool);
    function transferFrom(address sender, address recipient, uint amount)external returns(bool);
    event Transfer(address indexed from,address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}