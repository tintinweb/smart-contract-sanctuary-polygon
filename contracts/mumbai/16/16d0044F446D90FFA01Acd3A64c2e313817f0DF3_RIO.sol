/**
 *Submitted for verification at polygonscan.com on 2022-05-30
*/

// SPDX-License-Identifier:MIT
pragma solidity 0.8.14;

/*
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
contract RIO{

    string public PLAN_1 = "";

    struct data {
        uint256 time;
        uint256 plan;
        uint256 amount;
        uint256 withdrawed;
        uint256 interest;

        bool lockBonus;
    }
    //------------------   Mapping   ------------------//
    mapping(address => data) public investers;
    
    //------------------   Variables   ------------------//
    // modifier checker(){
    //     require();
    // }
    
    
    //------------------   Variables   ------------------//
    uint256 minAmount = 5E18;
    uint256 finalTime = 28;

    //------------------   Investing   ------------------//
    function investing(uint256 _plan) external payable{
        require(msg.value >= minAmount, "Minumum amount is 5 ether");
        require(_plan == 1 || _plan == 2 || _plan == 3, "Invalid Plan, Please select 1, 2 or 3");
        investers[msg.sender].plan = _plan;
        investers[msg.sender].amount = msg.value;
        investers[msg.sender].time = block.timestamp;
        investers[msg.sender].lockBonus = true;
    }
    //------------------   Reward   ------------------//
    function calcReward(address _user) public view returns(uint256) {
        uint256 reward;
        uint256 slots = timeSlots();

        if(investers[_user].plan == 1){
            reward = slots*(investers[_user].amount/1000*5);
        }
        return reward-investers[_user].withdrawed;
    }
    // ----------------  TimeDiff -------------------
    function timeDiff() public view returns(uint256) {
        uint256 second = block.timestamp - investers[msg.sender].time;
        return second;
    }
    //------------------   Slots   ------------------//

    function timeSlots() public view returns(uint256){
        uint256 second = timeDiff();
        uint256 slots = second / 1 minutes;
        return slots;
    }
    //------------------   Hold-Bonus   ------------------//

    function holdBonus() public view returns(uint256){
        uint256 slots = timeSlots();
        uint256 bonus = slots * (investers[msg.sender].amount/1000*1); // 0.1 %
        uint256 maxBonus = investers[msg.sender].amount/1000*15; // 1.5% max
        if (bonus >= maxBonus)( bonus = maxBonus);
        return bonus;
        }

    //------------------   Withdraw Reward   ------------------//

    function withdrawReward() public returns(uint256){
        uint256 slots = timeSlots();
        require(slots >= 1 , "Wait: Min reward will be for one day");
        uint256 reward = calcReward(msg.sender);
        if (investers[msg.sender].lockBonus == true){
            uint256 bonus =  holdBonus();
            reward += bonus;
        }
        payable(msg.sender).transfer(reward);
        investers[msg.sender].withdrawed += reward;
        investers[msg.sender].lockBonus = false;
        // investers[msg.sender].time =  ;

        return reward;
    }

    //------------------   Withdraw Investement   ------------------//

    function withdrawInvestment() external returns(uint256){
        uint256 reward;
        uint256 remInvestment;
        uint256 slots = timeSlots();
        if(slots <= finalTime){
            remInvestment = investers[msg.sender].amount / 100 * 80;
            reward = calcReward(msg.sender);
        }
        
        
        payable(msg.sender).transfer(remInvestment);
        investers[msg.sender].amount = 0;
        return remInvestment;
    }
}