//SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;



import "./plan2.sol";




contract MaticWin is MaticWin2{
   


    function Check_Profit_income( address _upline) public view returns(uint256 [] memory Amount,uint256 [] memory PoolA,uint256 PoolB,uint256  [] memory perdayAmount)
    {
        return (User[_upline].depositAmount,User[_upline].amount_Pool_A ,User[_upline].amount_Pool_B,User[_upline].PerdayReward);
    }
//..................................................................sponsor..................................................................

          function Check_Profit_income2( address _upline) public view returns(uint40 [] memory Time)
    {
        return (User[_upline].deposit_time);
    }
       function Check_Profit_income_Sponsor( address _upline) public view returns(address [] memory Sponsor,uint256 [] memory PoolA,uint256 PoolB,uint256  [] memory perdayAmount)
    {
        return (sponsorIncome[_upline].SponsorId,sponsorIncome[_upline].Amount ,User[_upline].amount_Pool_B,sponsorIncome[_upline].dailyReward);
    }

    function CheckDetails(address add,uint256 index) public view returns(uint256 Amount,uint256 depositTime,uint256 dailyReward,uint256 WithdrawReward)
    {
        return(User[add].depositAmount[index], User[add].deposit_time[index],User[add].PerdayReward[index],User[add].withdrawReward[index]);
    }


    function CheckDetailsSponsor(address add,uint256 index) public view returns(uint256 WithdrawReward)
    {
        return(sponsorIncome[add].withdrawReward[index]);
    }


    function checkrefList() public view returns(address[] memory Silver,address[] memory Gold,address[] memory platinum,address[] memory diamond)
    {
        return (Silver_UserAddress,Gold_UserAddress,platinum_UserAddress,diamond_UserAddress);
    }





    function CheckStatus(address add) public view returns(string memory _Status)
    {
        if(diamond_IsUpline(add) == true)
        {
            _Status = "diamond";
        }
        else if(platinum_IsUpline(add) == true)
        {
           _Status = "platinum"; 
        }
        else if(Gold_IsUpline(add) == true)
        {
           _Status = "Gold"; 
        }
        else if(silver_IsUpline(add) == true)
        {
           _Status = "Silver"; 
        }   
        return _Status;   
    }



    

}