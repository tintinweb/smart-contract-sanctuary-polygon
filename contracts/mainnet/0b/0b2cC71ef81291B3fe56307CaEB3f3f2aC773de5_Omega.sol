/**
 *Submitted for verification at polygonscan.com on 2022-10-19
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface USDT{
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) ;
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    }
contract Omega
    {

        struct allInvestments{

            uint investedAmount;
            uint expire_Time;
            uint DepositTime;  
            uint investmentNum;
            uint unstakeTime;
            bool unstake;
            uint category;


        }
        struct ref_data{
            uint reward;
            uint count;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
        }

        struct Data{

            mapping(uint=>allInvestments) investment;
            address[] hisReferrals;
            address referralFrom;
            mapping(uint=>ref_data) referralLevel;
            uint reward;
            uint noOfInvestment;
            uint totalInvestment;
            uint totalWithdraw_reward;
            bool investBefore;
            uint stakeTime;
            uint TotalReferrals_earning;
        }
        
        uint public minimum_investment=15000000000000000000;
        address public usdt_address=0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;

        address owner;
        uint public totalbusiness; 
        uint public investmentPeriod=50 days;

        
        uint public totalusers;

        mapping(uint=>uint) public category_percentage;
        mapping(uint=>address) public All_investors;
        mapping(address=>Data) public user;
        uint[] public arr=[3000000000000000000,3500000000000000000,4000000000000000000,4500000000000000000,5000000000000000000,5500000000000000000,6000000000000000000,6500000000000000000,7000000000000000000,7500000000000000000];



     constructor(){
        owner=msg.sender;

        for(uint i=0;i<10;i++)
        {
            category_percentage[i]=arr[i];
        }



        }



        function sendRewardToReferrals(address investor,uint _investedAmount)  internal  //this is the freferral function to transfer the reawards to referrals
        { 

            address temp = investor;       
            uint[] memory percentage = new uint[](5);
            percentage[0] = 20;
            percentage[1] = 10;
            percentage[2] = 3;
            percentage[3] = 2;
            percentage[4] = 1;


            uint j;



            for(uint i=0;i<10;i++)
            {

                if(i==0)
                {
                    j=0;
                }
                else if(i==1)
                {
                    j=1;
                }
                else if(i==2)
                {
                    j=2;
                }
                else if(i==3)
                {
                    j=3;
                }
                else if(i>3)
                {
                    j=4;
                }
                
                if(user[temp].referralFrom!=address(0))
                {
                    if(i==0)
                    {
                        
                    }

                    temp=user[temp].referralFrom;
                    uint reward1 = ((percentage[j]*1000000000000000000) * _investedAmount)/100000000000000000000;

                    user[temp].TotalReferrals_earning+=reward1 ;                  
                    user[temp].referralLevel[i].reward+=reward1;
                    user[temp].referralLevel[i].count++;


                } 
                else{
                    break;
                }

            }

        }



        function define_category(uint amount) pure internal returns(uint){
            if(amount>=15000000000000000000 && amount<=100000000000000000000)
            {
                return 0;
            }
            else if(amount>100000000000000000000 && amount<=300000000000000000000)
            {
                return 1;

            }
            else if(amount>300000000000000000000 && amount<=600000000000000000000)
            {
                return 2;

            }
            else if(amount>600000000000000000000 && amount<=1200000000000000000000)
            {
                return 3;

            }
            else if(amount>1200000000000000000000 && amount<=2400000000000000000000)
            {
                return 4;

            }
            else if(amount>2400000000000000000000 && amount<=5000000000000000000000)
            {
                return 5;

            }

            else if(amount>5000000000000000000000 && amount<=10000000000000000000000)
            {
                return 6;

            }
            else if(amount>10000000000000000000000 && amount<=20000000000000000000000)
            {
                return 7;

            }
            else if(amount>20000000000000000000000 && amount<=40000000000000000000000)
            {
                return 8;

            }
            else if(amount>40000000000000000000000)
            {
                return 9;

            }
            
 return 100;
        }


       


       function invest(uint _investedamount,address _referral) external  returns(bool)
       {
            require(_investedamount>=minimum_investment,"you cant invest less than minimumum investment");
             uint temp;
             uint reward=getReward(msg.sender);

            if(reward>=_investedamount)
            {
                user[msg.sender].totalWithdraw_reward+=_investedamount;            
            }
            else{
                 temp=_investedamount-reward;
                 require(USDT(usdt_address).balanceOf(msg.sender)>=temp,"you dont have enough usdt");
                 require(USDT(usdt_address).allowance(msg.sender,address(this))>=temp,"kindly appprove the USDT");
                 user[msg.sender].totalWithdraw_reward+=reward;

                USDT(usdt_address).transferFrom(msg.sender,address(this),temp*70000000000000000000/100000000000000000000);
                USDT(usdt_address).transferFrom(msg.sender,owner,temp*30000000000000000000/100000000000000000000);




            }


            uint num = user[msg.sender].noOfInvestment;
            user[msg.sender].investment[num].investedAmount =_investedamount;
            user[msg.sender].investment[num].category= define_category(_investedamount);
            user[msg.sender].investment[num].DepositTime=block.timestamp;
            user[msg.sender].investment[num].expire_Time=block.timestamp + investmentPeriod ;  // 60 days
            user[msg.sender].investment[num].investmentNum=num;
            user[msg.sender].totalInvestment+=_investedamount;
            user[msg.sender].noOfInvestment++;
            totalbusiness+=_investedamount;
            if(user[msg.sender].investBefore == false)
            { 

                All_investors[totalusers]=msg.sender;
                totalusers++;   

                if(_referral==address(0) || _referral==msg.sender)                                         //checking that investor comes from the referral link or not
                {

                    user[msg.sender].referralFrom = address(0);
                }
                else
                {
                   
                    user[msg.sender].referralFrom = _referral;
                    user[_referral].hisReferrals.push(msg.sender);
                
                    sendRewardToReferrals(msg.sender,_investedamount);      //with this function, sending the reward to the all 12 parent referrals
                    
                }

            }
     
            user[msg.sender].investBefore=true;

            return true;
        }

        function getReward() view public returns(uint){ //this function is get the total reward balance of the investor
            uint totalReward;
            uint depTime;
            uint rew;
            uint temp = user[msg.sender].noOfInvestment;
            for( uint i = 0;i < temp;i++)
            {   
                if(user[msg.sender].investment[i].expire_Time >block.timestamp)
                {
                    if(!user[msg.sender].investment[i].unstake)
                    {
                        depTime =block.timestamp - user[msg.sender].investment[i].DepositTime;
                       

                    }
                    else{

                        depTime =user[msg.sender].investment[i].unstakeTime - user[msg.sender].investment[i].DepositTime;

                    }
                }
                else{

                    if(!user[msg.sender].investment[i].unstake)
                    {
                        depTime =user[msg.sender].investment[i].expire_Time - user[msg.sender].investment[i].DepositTime;

                    }
                    else{
                        if(user[msg.sender].investment[i].unstakeTime > user[msg.sender].investment[i].expire_Time)
                        {
                            depTime =user[msg.sender].investment[i].expire_Time - user[msg.sender].investment[i].DepositTime;

                        }
                        else{

                            depTime =user[msg.sender].investment[i].unstakeTime - user[msg.sender].investment[i].DepositTime;

                        }


                    }

                }
          
                depTime=depTime/86400; //1 day

                if(depTime>0)
                {
                    rew  = ((user[msg.sender].investment[i].investedAmount)*category_percentage[user[msg.sender].investment[i].category])/100000000000000000000;

                    totalReward += depTime * rew;

                }
            }
            totalReward += user[msg.sender].TotalReferrals_earning;

            totalReward -= user[msg.sender].totalWithdraw_reward;

            return totalReward;
        }


        function get_Total_Earning() view public returns(uint){ //this function is get the total reward balance of the investor
            uint totalReward;
            uint depTime;
            uint rew;
            uint temp = user[msg.sender].noOfInvestment;
            for( uint i = 0;i < temp;i++)
            {   
                if(user[msg.sender].investment[i].expire_Time >block.timestamp)
                {
                    if(!user[msg.sender].investment[i].unstake)
                    {
                        depTime =block.timestamp - user[msg.sender].investment[i].DepositTime;
                       

                    }
                    else{

                        depTime =user[msg.sender].investment[i].unstakeTime - user[msg.sender].investment[i].DepositTime;

                    }
                }
                else{

                    if(!user[msg.sender].investment[i].unstake)
                    {
                        depTime =user[msg.sender].investment[i].expire_Time - user[msg.sender].investment[i].DepositTime;

                    }
                    else{
                        if(user[msg.sender].investment[i].unstakeTime > user[msg.sender].investment[i].expire_Time)
                        {
                            depTime =user[msg.sender].investment[i].expire_Time - user[msg.sender].investment[i].DepositTime;

                        }
                        else{

                            depTime =user[msg.sender].investment[i].unstakeTime - user[msg.sender].investment[i].DepositTime;

                        }


                    }

                }
          
                depTime=depTime/86400; //1 day
                if(depTime>0)
                {
                    rew  = ((user[msg.sender].investment[i].investedAmount)*category_percentage[user[msg.sender].investment[i].category])/100000000000000000000;

                    totalReward += depTime * rew;

                }
            }
                totalReward += user[msg.sender].TotalReferrals_earning;


            return totalReward;
        }





        function getReward(address _investor) view public returns(uint){ //this function is get the total reward balance of the investor
            uint totalReward;
            uint depTime;
            uint rew;
            uint temp = user[_investor].noOfInvestment;
            for( uint i = 0;i < temp;i++)
            {   
                if(user[_investor].investment[i].expire_Time >block.timestamp)
                {
                    if(!user[_investor].investment[i].unstake)
                    {
                        depTime =block.timestamp - user[_investor].investment[i].DepositTime;

                    }
                    else{

                        depTime =user[_investor].investment[i].unstakeTime - user[_investor].investment[i].DepositTime;

                    }
                }
                else{

                    if(!user[_investor].investment[i].unstake)
                    {
                        depTime =user[_investor].investment[i].expire_Time - user[_investor].investment[i].DepositTime;

                    }
                    else{
                        if(user[_investor].investment[i].unstakeTime > user[_investor].investment[i].expire_Time)
                        {
                            depTime =user[_investor].investment[i].expire_Time - user[_investor].investment[i].DepositTime;

                        }
                        else{

                            depTime =user[_investor].investment[i].unstakeTime - user[_investor].investment[i].DepositTime;

                        }


                    }

                }
          
                depTime=depTime/86400; //1 day

                if(depTime>0)
                {
                    rew  = ((user[_investor].investment[i].investedAmount)*category_percentage[user[_investor].investment[i].category])/100000000000000000000;

                    totalReward += depTime * rew;

                }
            }
            totalReward += user[_investor].TotalReferrals_earning;

            totalReward -= user[_investor].totalWithdraw_reward;


            return totalReward;
        }



        function getReward_perInvestment(uint i) view public returns(uint){ //this function is get the total reward balance of the investor
            uint totalReward;
            uint depTime;
            uint rew;
  
            if(user[msg.sender].investment[i].expire_Time >block.timestamp)
            {
                if(!user[msg.sender].investment[i].unstake)
                {
                    depTime =block.timestamp - user[msg.sender].investment[i].DepositTime;
                    
                }
                else{

                    depTime =user[msg.sender].investment[i].unstakeTime - user[msg.sender].investment[i].DepositTime;

                }
            }
            else{

                if(!user[msg.sender].investment[i].unstake)
                {
                    depTime =user[msg.sender].investment[i].expire_Time - user[msg.sender].investment[i].DepositTime;

                }
                else{
                    if(user[msg.sender].investment[i].unstakeTime > user[msg.sender].investment[i].expire_Time)
                    {
                        depTime =user[msg.sender].investment[i].expire_Time - user[msg.sender].investment[i].DepositTime;

                    }
                    else{

                        depTime =user[msg.sender].investment[i].unstakeTime - user[msg.sender].investment[i].DepositTime;

                    }


                }

            }
          
            depTime=depTime/86400; //1 day
            if(depTime>0)
            {
                rew  = ((user[msg.sender].investment[i].investedAmount)*category_percentage[user[msg.sender].investment[i].category])/100000000000000000000;

                totalReward += depTime * rew;

            }
            
            return totalReward;
        }


        function withdrawReward(uint _amount) external returns (bool success){
            require(_amount>=15000000000000000000,"you can't withdraw less than 8 usdt");         //ensuring that if the investor have rewards to withdraw

            uint Total_reward = getReward(msg.sender);
            require(Total_reward>=_amount,"you dont have rewards to withdrawn");         //ensuring that if the investor have rewards to withdraw
        
            USDT(usdt_address).transfer(msg.sender,_amount);             // transfering the reward to investor             
            user[msg.sender].totalWithdraw_reward+=_amount;

            return true;

        }


       function change_minimum_investment(uint _inv) external returns(bool){
           require(msg.sender==owner,"only owner can do this");
           require(_inv > 0,"value should be greater than 0");
           minimum_investment=_inv;
           return true;

        }


        function change_investmentPeriod(uint _period) external returns(bool){
           require(msg.sender==owner,"only owner can do this");
           require(_period > 0,"value should be greater than 0");
           investmentPeriod=_period * 1 days;
           return true;

        } 


        function getTotalInvestment() public view returns(uint) {   //this function is to get the total investment of the ivestor
            
            return user[msg.sender].totalInvestment;

        }

        function getAllinvestments() public view returns (allInvestments[] memory) { //this function will return the all investments of the investor and withware date
            uint num = user[msg.sender].noOfInvestment;
            uint temp;
            uint currentIndex;
            
            for(uint i=0;i<num;i++)
            {
               if( user[msg.sender].investment[i].investedAmount > 0  ){
                   temp++;
               }

            }
         
            allInvestments[] memory Invested =  new allInvestments[](temp) ;

            for(uint i=0;i<num;i++)
            {
               if( user[msg.sender].investment[i].investedAmount > 0 ){
                 //allInvestments storage currentitem=user[msg.sender].investment[i];
                   Invested[currentIndex]=user[msg.sender].investment[i];
                   currentIndex++;
               }

            }
            return Invested;

        }

        function referralLevel_earning() public view returns( uint[] memory arr1 )
        {
            uint[] memory referralLevels_reward=new uint[](10);
            for(uint i=0;i<10;i++)
            {
                if(user[msg.sender].referralLevel[i].reward>0)
                {
                    referralLevels_reward[i] = user[msg.sender].referralLevel[i].reward;


                }
                else{

                    referralLevels_reward[i] = 0;

                }


            }
            return referralLevels_reward ;


        }



        function referralLevel_count() public view returns( uint[] memory _arr )
        {
            uint[] memory referralLevels_reward=new uint[](10);
            for(uint i=0;i<10;i++)
            {
                if(user[msg.sender].referralLevel[i].reward>0)
                {
                    referralLevels_reward[i] = user[msg.sender].referralLevel[i].count;


                }
                else{
                    referralLevels_reward[i] = 0;

                }


            }
            return referralLevels_reward ;


        }


        function TotalReferrals() public view returns(uint){ // this function is to get the total number of referrals 
            return (user[msg.sender].hisReferrals).length;
        }
        function TotalReferrals_inside(address investor) internal view returns(uint){ // this function is to get the total number of referrals 
            return (user[investor].hisReferrals).length;
        }

        function ReferralsList() public view returns(address[] memory){ //this function is to get the all investors list with there account number
           return user[msg.sender].hisReferrals;
        }

        function get_total_ref_earning() public view returns(uint){ //this function is to get the all investors list with there account number
           return user[msg.sender].TotalReferrals_earning;
        }



  
        function transferOwnership(address _owner)  public
        {
            require(msg.sender==owner,"only Owner can call this function");
            owner = _owner;
        }

        function total_withdraw_reaward() view public returns(uint){


            uint Temp = user[msg.sender].totalWithdraw_reward;

            return Temp;
            

        }
        function get_currTime() public view returns(uint)
        {
            return block.timestamp;
        }
        function withdrawFunds(uint _amount)  public
        {
            require(msg.sender==owner,"only Owner can call this function");
            uint bal = USDT(usdt_address).balanceOf(address(this));
            require(bal>=_amount,"you dont have funds");

            USDT(usdt_address).transfer(owner,_amount); 
        }
        function get_Contract_Funds() view public returns(uint) 
        {
            require(msg.sender==owner,"only Owner can call this function");
            uint bal = USDT(usdt_address).balanceOf(address(this)); 

            return bal;
        }
        function get_InvExp_Date(uint _num) public view returns(uint)
        {
            return user[msg.sender].investment[_num].expire_Time;
        }








    }