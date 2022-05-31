/**
 *Submitted for verification at polygonscan.com on 2022-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/*
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
contract ROI{

//------------------   Struct   ------------------//
    struct data {
        uint256 time;
        uint256 amount;
        uint256 withdrawed;
        uint256 interest;
        uint256 plan;
        uint256 maxBonus;
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

    IERC20 MATIC;
    address owner;
    uint256 minAmount = 5E18;
    uint256 finalTime = 21 minutes;

//------------------   Constructor   ------------------//

    constructor(IERC20 _MATIC){
        MATIC = _MATIC;
        owner = msg.sender;

        plansReward[14] = 80000000000000000;    // 8/100 (0.08) for 14 days plan
        plansReward[28] = 100000000000000000;  // 10/100 (0.1) for 28 days plan
    }

    //------------------   Investing   ------------------//

    function investing(uint256 _plan) external payable{
        require(msg.value >= minAmount, "Minumum amount is 5 MATIC");
        require(isStaked[msg.sender] == false, "Already staked");
        require(_plan == 14 || _plan == 28, "Invalid_Plan, Please select 14 or 28");

        // MATIC.transferFrom(msg.sender, address(this), _amount);
        payable(address(this)).transfer(msg.value);
    
        isStaked[msg.sender] = true;
        investers[msg.sender].plan = _plan;
        investers[msg.sender].amount = msg.value;
        investers[msg.sender].time = block.timestamp;
        // 1.5% of amount max
        investers[msg.sender].maxBonus = investers[msg.sender].amount/1000*15;
        
    }
    //------------------   Reward   ------------------//
    function calcReward(address _staker) public view returns(uint256) {
        
        uint256 reward;
        uint256 Bonus;
        uint256 noOfDays = calNoOfDays();
        // Verify max number of days of staker
        
        // reward = days * amount * RewardPerToken
        reward = noOfDays.mul(investers[_staker].amount).mul(plansReward[investers[msg.sender].plan]);
        Bonus = holdBonus();
        reward += Bonus;
        return reward.sub(investers[_staker].withdrawed).div(1 ether);
    }
    //------------------   noOfDays   ------------------//

    function calNoOfDays() private view returns(uint256){
        uint256 noOfSeconds = block.timestamp - investers[msg.sender].time;
        uint256 noOfDays = noOfSeconds / 1 minutes;
        if(noOfDays > investers[msg.sender].plan)(noOfDays = investers[msg.sender].plan);
        return noOfDays;
    }
    //------------------   Hold-Bonus   ------------------//

    function holdBonus() private view returns(uint256){
        require(investers[msg.sender].lockBonus == false);
        uint256 noOfDays = calNoOfDays();
        uint256 bonus = noOfDays.mul(investers[msg.sender].amount.div(1000).mul(1)); // 0.1 % bonus
        if (bonus >= investers[msg.sender].maxBonus)(bonus = investers[msg.sender].maxBonus);
        return bonus;
        }

    //------------------   Withdraw Reward   ------------------//

    function withdrawReward() external returns(uint256){
        uint256 noOfDays = calNoOfDays();
        require(noOfDays >= 1 , "Wait: Min reward will be for one day");
        uint256 reward = calcReward(msg.sender);
        if (investers[msg.sender].lockBonus == false){
            uint256 bonus =  holdBonus();
            reward += bonus;
        }
        MATIC.transfer(msg.sender, reward);
        investers[msg.sender].withdrawed += reward;
        investers[msg.sender].lockBonus = true;
        return reward;
    }

    //------------------   Withdraw Investement   ------------------//

    function withdrawInvestment() external returns(uint256){
        uint256 reward;
        uint256 remInvestment;
        uint256 noOfDays = calNoOfDays();
        if(noOfDays <= finalTime){
            reward = calcReward(msg.sender);
            remInvestment = investers[msg.sender].amount.add(reward);
            remInvestment = investers[msg.sender].amount / 100 * 80;
            
        }
        MATIC.transfer(msg.sender, remInvestment);
        investers[msg.sender].amount = 0;
        return remInvestment;
    }
}


/*
    1:
*/