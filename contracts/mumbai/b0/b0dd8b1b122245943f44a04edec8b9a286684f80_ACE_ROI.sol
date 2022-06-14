/**
 *Submitted for verification at polygonscan.com on 2022-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/*

    There is an error: if User withdrwa investment before reward
    His reward will become 0



>> 2 plansReward, 14 days, 28 days
>> 14 days plan: 8% daily max 112%
>> 28 days plan: 10% daily max 280%

The MATICFomo smart-contract provides the opportunity to invest any amount of MATIC (from 5 MATIC) in 
the contract. 

Get 100% to 1000% return on investment in 21  days （from 20% to 30% daily）

Min. deposit: 5 MATIC and no max. limit. Investors can withdraw the profit without any fee.

Important notes:

1. Basic interest rate (only for new deposits): +0.5% every 24 hours

2. If users don't make a withdrawal everyday, will get extra bonus - hold bonus. Hold-bonus 
    increase by 0.1% per day, Max. is 1.5%. 
if users withdraw, Hold-bonus will reset to 0

3. Investors can close deposits early(If the plan has not expired), but there is a 20% penalty into the contract to sustain it. 



Function will be available on 28 of this month
*/
//------------------   Interface   ------------------//
interface IERC20{
    
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
contract ACE_ROI{

    //------------------   Struct   ------------------//
    struct data {
        uint256 time;
        uint256 amount;
        uint256 bonusChk;
        uint256 bonusWithdrawed; /// error
        uint256 TotalUsers;
        uint256 TotalStakedAmount;
        uint256 maxBonus;
        uint256 plan;
        uint256 rewardWithdrawed; // error
        bool lockBonus;
        

    }

    //------------------   Mapping   ------------------//
    using SafeMath for uint256;
    mapping(address => data) public investers;
    mapping(address => bool) public isStaked;
    mapping(uint256 => uint256) public plansReward;
    
    //------------------   Modifier   ------------------//
    modifier onlyOwner(){
        require(owner == msg.sender);
        _;
    }
    
    //------------------   Variables   ------------------//
    
    address owner;
    IERC20 public MATIC;
    uint256 public finalDate = 21 seconds; // change seconds to days on finalization
    uint256 public minAmount = 0.1 ether;
    uint256 public plan1FinalTime = 14 seconds;

    //------------------   Constructor   ------------------//

    constructor(IERC20 _MATIC){
        MATIC = _MATIC;
        owner = msg.sender;

        plansReward[1] = 100000000000000000;    // 10/100 (0.08) for 14 days plan
        plansReward[2] = 200000000000000000;  // 20/100 (0.1) for 21 days plan
        plansReward[3] = 300000000000000000;  // 30/100 (0.1) for 21 days plan
    }

    function STAAKEEBOOL() public view returns(bool){
        return investers[msg.sender].lockBonus;
    }

    // ---------------  Investing Plan- (1,2,3)   ---------------- //

    function Investing(uint256 _plan) public payable {

        require(msg.value >= minAmount, "Minumum amount is 0.1 MATIC");
        require(isStaked[msg.sender] == false, "Already staked");
        require(_plan == 1 || _plan == 2 || _plan == 3,"INVALID PLAN: SELECT 1, 2 OR 3");
        isStaked[msg.sender] = true;
        investers[msg.sender].TotalUsers +=1;
        investers[msg.sender].TotalStakedAmount+=msg.value;
        investers[msg.sender].amount = msg.value;
        investers[msg.sender].bonusChk = msg.value;
        investers[msg.sender].time = block.timestamp;
        investers[msg.sender].plan = _plan;
        

        // Bonus: 1.5% of amount max
        investers[msg.sender].maxBonus = investers[msg.sender].amount/1000*15;
    }

    //------------------   Calculate Reward   ------------------//
    function calcReward(address _staker, uint256 _plan) public view returns(uint256) {
        // plan must from plans you choosed on the time of staking
        // require(investers[_staker].plan == _plan,"PLAN select wisely"); 
        uint256 reward;
        uint256 noOfDays = calNoOfDays(_staker);
        
        if (investers[_staker].plan == _plan) {
        if(_plan == 1){
            // @dev reward = days * plan(REWARD PER TOKEN) * amount - rewardWithdrawed
            reward = noOfDays.mul(plansReward[1]).mul(investers[_staker].amount);
        // Plan 2
        } else if(_plan == 2){
            reward = noOfDays.mul(plansReward[2]).mul(investers[_staker].amount);
        // Plan 3
        } else if(_plan == 3){
            reward = noOfDays.mul(plansReward[3]).mul(investers[_staker].amount);
        }
        
        reward = reward.div(1 ether);
        uint256 c = reward.sub(investers[msg.sender].rewardWithdrawed);
        return c;
        }
        else {
            return 0;
        }
    }

    //------------------   noOfDays   ------------------//

    function calNoOfDays(address _staker) public view returns(uint256) {
        
        uint256 noOfSeconds = block.timestamp.sub(investers[_staker].time);
        uint256 noOfDays = noOfSeconds.div(1 seconds); // change seconds to days on finalization

        if(noOfDays > finalDate)(noOfDays = finalDate);
        // condition for plan 1 max days which are 14 days


        /// Not working
        if(investers[msg.sender].plan == 1){
            if(noOfDays > plan1FinalTime){
                (noOfDays = plan1FinalTime);
            }
        }
        return noOfDays;
    }

    //------------------   Hold-Bonus   ------------------//

    function holdBonus(address _staker) public view returns(uint256){
        uint256 noOfDays = calNoOfDays(_staker);
        uint256 bonus = noOfDays.mul(investers[_staker].bonusChk.div(1000).mul(1)); // 0.1 % bonus
        if (bonus >= investers[_staker].maxBonus)(bonus = investers[_staker].maxBonus);
        return bonus;
        }

    //------------------   Withdraw Reward   ------------------//

    function withdrawReward(uint256 _plan) public {
        // require(investers[msginsender].finalDate == )
        uint256 bonus;

        uint256 reward = calcReward(msg.sender, _plan); ////
        investers[msg.sender].rewardWithdrawed += reward;

        if (investers[msg.sender].lockBonus == false){
            bonus =  holdBonus(msg.sender);  
            investers[msg.sender].bonusWithdrawed += bonus;
            reward += bonus;
            investers[msg.sender].lockBonus = true;
            investers[msg.sender].bonusChk = 0;

        }
        if(_plan == 2 || _plan == 3){
            rewardFor21Days();
        }
        
        MATIC.transfer(msg.sender, reward);
    }

    function rewardFor21Days() view private{
        require(block.timestamp >= investers[msg.sender].time + 21, "Wait 21 Days");
    }

    //------------------   Withdraw Investement   ------------------//

    function withdrawInvestment() public{

        if(investers[msg.sender].plan==1){
          withdrawReward(1);
       }
       else if (investers[msg.sender].plan==2){
          withdrawReward(2);
       }
       else if (investers[msg.sender].plan==3){
          withdrawReward(3);
       }
        
        uint256 amount = investers[msg.sender].amount;
        uint256 noOfDays = calNoOfDays(msg.sender);

        if(noOfDays < finalDate)(amount = amount / 100 * 80);
        
        payable(msg.sender).transfer(amount);
        investers[msg.sender].TotalStakedAmount -= investers[msg.sender].amount;
        investers[msg.sender].TotalUsers-=1;
        investers[msg.sender].amount = 0;
        investers[msg.sender].time = 0;
        investers[msg.sender].plan = 0;
        investers[msg.sender].maxBonus = 0;
        investers[msg.sender].rewardWithdrawed=0;
        isStaked[msg.sender] = false;
    }
        //  0xdE24F0cfA70Aa1241363313dAc5C871D680dFC97
}

/*
- User have to invest MATICS to get reward
- Minimum limit of investment is 5 MATICS
- There are two plans
    1: 14 days plan with 120% reward
    2: 28 days plan with 280% reward
- He will also get hold bonus if he will not withdraw reward daily
- He will get 0.1% daily reward and max 1.5 of amount.
- But he will lost future bonus if he withdraw before plan end.
- After that he can only get daily reward, not bonus
- If he withdraw amount before plan end, but there is a 
  20% penalty of amount and reward as well, into the contract to sustain it
- 
*/