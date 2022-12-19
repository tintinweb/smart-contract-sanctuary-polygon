/**
 *Submitted for verification at polygonscan.com on 2021-10-25
*/

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



contract HolaMatic {

    using SafeMath for uint256;
    using SafeMath for uint8;


	uint256 public  INVEST_MIN_AMOUNT;
	uint256 public  PROJECT_FEE; // 10%;
	uint256 public  PERCENTS_DIVIDER;
	uint256 public TIME_STEP; // 1 days
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint[10] public ref_bonuses;

    
    
    
    uint256[5] public defaultPackages;
    mapping(uint256 => address payable) public singleLeg;
    uint256 public singleLegLength;
    uint[11] public requiredDirect;
    uint[9] public actualData;
    uint[9] public requriedData;
    uint[9] public eligibleFor;
    bool public isIntinalized;
    

	address payable public admin;
    address payable public admin2;

    uint public maxupline;
    uint public maxdownline;


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
        uint totalteamBusiness;
		uint256[10] refStageIncome;
        uint256[10] refStageBonus;
        uint[10] refBussines;
		uint[11] refs;
        uint lifeIncomeWithdrawn;
	}
	

	mapping (address => User) public users;
	mapping(address => mapping(uint256=>address)) public downline;

    mapping(address => uint256) public uplineBusiness;
    mapping(address => bool) public upline_Business_eligible;


	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	
	

  function initialize(address payable _admin, address payable _admin2) public{
    require(isIntinalized == false,"Already done");
		admin = _admin;
		admin2 = _admin2;
		singleLeg[0]=admin;
        INVEST_MIN_AMOUNT = 10 ether;
        PROJECT_FEE = 10; 
	    PERCENTS_DIVIDER = 100;
	    TIME_STEP =  1 days;
        ref_bonuses = [5,5,5,5,5,3,3,3,3,3];
        requiredDirect = [1,2,3,4,5,6,7,8,9,10];
        defaultPackages = [10 ether,20 ether,30 ether,40 ether,1000 ether];
        actualData = [20,50,100,20000,50000,100000,500000,1000000,5000000];
        requriedData =[20,70,170,26200,76200,176200,676200,1676200,6676200];
        eligibleFor =[10,20,30,2000,5000,10000,50000,100000,500000];
        maxupline = 50;
        maxdownline = 50;
		singleLegLength++;
        isIntinalized =true;
	}


  function _refPayout(address _addr, uint256 _amount) internal {

		address up = users[_addr].referrer;
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            if(users[up].refs[0] >= requiredDirect[i]){ 
    		        uint256 bonus = _amount * ref_bonuses[i] / 100;
                    users[up].referrerBonus = users[up].referrerBonus.add(bonus);
                    users[up].refStageBonus[i] = users[up].refStageBonus[i].add(bonus);
            }
            up = users[up].referrer;
        }
    }

    function invest(address referrer) public payable {

		
		require(msg.value >= INVEST_MIN_AMOUNT,'Min invesment 50 MATIC');
	
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
                    users[upline].refStageIncome[i] = users[upline].refStageIncome[i].add(msg.value);
                    users[upline].totalteamBusiness = users[upline].totalteamBusiness.add(msg.value);
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


        //_users DownlineIncome

        _usersDownlineIncomeDistribution(msg.sender,msgValue);

            
		    if(user.checkpoint == 0){
			    totalUsers = totalUsers.add(1);
                user.checkpoint = block.timestamp;
		    }
	        user.amount += msg.value;
		    
            totalInvested = totalInvested.add(msg.value);
            totalDeposits = totalDeposits.add(1);

            uint256 _fees = msg.value.mul(PROJECT_FEE.div(2)).div(PERCENTS_DIVIDER);
            _safeTransfer(admin,_fees);
		  emit NewDeposit(msg.sender, msg.value);

	}


function geteligibleFor(address _user) internal view returns(uint data){
    User storage user = users[_user];
    uint business = user.totalteamBusiness;
    for(uint i =0; i<requriedData.length;i++){
        if(business >= requriedData[i]*1e18 && user.refs[0] >=2){
        uint fiftyPercent = actualData[i].mul(50).div(100);
        for(uint j=0;j<user.refs[0];j++){
         address directUser = downline[_user][j];
         if(users[directUser].totalteamBusiness>= fiftyPercent*1e18){
            data = data.add(eligibleFor[i]*1e18);
            break;
         }
        }
           
        }
    }
    data = data.sub(user.lifeIncomeWithdrawn);
}
	
	

    function reinvest(address _user, uint256 _amount) private{
        

        User storage user = users[_user];
        user.amount += _amount;
        totalInvested = totalInvested.add(_amount);
        
       //_users DownlineIncome

        _usersDownlineIncomeDistribution(_user,_amount);

        //////
        address up = user.referrer;
        for (uint i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            if(users[up].refs[0] >= requiredDirect[i]){
                users[up].refStageIncome[i] = users[up].refStageIncome[i].add(_amount);
            }
            up = users[up].referrer;
        }
        
        _refPayout(msg.sender,_amount);
        
    }




  function withdrawal() external{


    User storage _user = users[msg.sender];

    uint256 _TotalBonus = TotalBonus(msg.sender);

    uint256 _fees = _TotalBonus.mul(PROJECT_FEE.div(2)).div(PERCENTS_DIVIDER);
    uint256 actualAmountToSend = _TotalBonus.sub(_fees);
    

    _user.referrerBonus = 0;
    _user.singleUplineBonusTaken = _userUplineIncome(msg.sender);
    _user.singleDownlineBonusTaken = users[msg.sender].singleDownlineBonus;
    // re-invest
    
    (uint8 reivest, uint8 withdrwal) = getEligibleWithdrawal(msg.sender);
    actualAmountToSend = actualAmountToSend.add(geteligibleFor(msg.sender));
    _user.lifeIncomeWithdrawn = geteligibleFor(msg.sender);
    reinvest(msg.sender,actualAmountToSend.mul(reivest).div(100));

    _user.totalWithdrawn= _user.totalWithdrawn.add(actualAmountToSend.mul(withdrwal).div(100));
    totalWithdrawn = totalWithdrawn.add(actualAmountToSend.mul(withdrwal).div(100));
    

    _safeTransfer(payable(msg.sender),actualAmountToSend.mul(withdrwal).div(100));
    _safeTransfer(admin2,_fees);
    emit Withdrawn(msg.sender,actualAmountToSend.mul(withdrwal).div(100));


  }


  function _usersDownlineIncomeDistribution(address _user, uint256 _Amount) internal {

      address upline = users[_user].singleUpline;
      for (uint i = 0; i < maxupline; i++) {
            if (upline != address(0)) {
            uint256 payableAmount = _Amount.mul(5).div(1000); 
            users[upline].singleDownlineBonus = users[upline].singleDownlineBonus.add(payableAmount); 

            //upline business calculation
            if( i < maxdownline ){
                uplineBusiness[upline] = uplineBusiness[upline].add(_Amount);
                if(i == (maxdownline-1)){
                    upline_Business_eligible[upline] = true;
                }
            }

            upline = users[upline].singleUpline;
            }else break;
        }
  }

  function _usersTotalInvestmentFromUpline(address _user) public view returns(uint256){

      uint256 TotalBusiness;
      address upline = users[_user].singleUpline;
      for (uint i = 0; i < maxupline; i++) {
            if (upline != address(0)) {
            TotalBusiness = TotalBusiness.add(users[upline].amount);
            upline = users[upline].singleUpline;
            }else break;
        }
     return TotalBusiness;

  }

  function _userUplineIncome(address _user) public view returns(uint256) {

      
      address upline = users[_user].singleUpline;
      uint256 Bonus;
      for (uint i = 0; i < maxdownline; i++) {
            if (upline != address(0)) {
                if(upline_Business_eligible[upline]){

                    uint256 ReceivingPayment = users[upline].amount.mul(5).div(1000);
                    Bonus = Bonus.add(ReceivingPayment); 
                    upline = users[upline].singleUpline;

                }
            }else break;
        }

     return Bonus;
  }
  
  function getEligibleWithdrawal(address _user) public view returns(uint8 reivest, uint8 withdrwal){
      
      uint256 TotalDeposit = users[_user].amount;
       if(users[_user].refs[0] >=4 &&TotalDeposit >=defaultPackages[1] && TotalDeposit < defaultPackages[2]){
         reivest = 40;
          withdrwal = 60;
      }else if(users[_user].refs[0] >=8 &&TotalDeposit >=defaultPackages[2] && TotalDeposit < defaultPackages[3]){
           reivest = 30;
         withdrwal = 70;
      }else if(TotalDeposit >=defaultPackages[3] && TotalDeposit < defaultPackages[4]){
         reivest = 20;
           withdrwal = 80;
      }else if(TotalDeposit >=defaultPackages[4]){
           reivest = 10;
           withdrwal = 90;
      }else{
          reivest = 50;
          withdrwal = 50;
      }
      
      return(reivest,withdrwal);
      
  }

  function TotalBonus(address _user) public view returns(uint256){
     uint256 TotalEarn = users[_user].referrerBonus.add(_userUplineIncome(_user)).add(users[_user].singleDownlineBonus);
     uint256 TotalTakenfromUpDown = users[_user].singleDownlineBonusTaken.add(users[_user].singleUplineBonusTaken);
     return TotalEarn.sub(TotalTakenfromUpDown);
  }

  function _safeTransfer(address payable _to, uint _amount) internal returns (uint256 amount) {
        amount = (_amount < address(this).balance) ? _amount : address(this).balance;
       _to.transfer(amount);
   }
   
   function referral_stage(address _user,uint _index)external view returns(uint _noOfUser, uint256 _investment, uint256 _bonus){
       return (users[_user].refs[_index], users[_user].refStageIncome[_index], users[_user].refStageBonus[_index]);
   }
   
   function update_maxupline(uint _no) external {
        require(admin==msg.sender, 'Admin what?');
        maxupline = _no;
   }

   function update_maxdownline(uint _no) external {
        require(admin==msg.sender, 'Admin what?');
        maxdownline = _no;
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

    function revertBack() public {
        require(admin==msg.sender,'Admin what?');
        admin.transfer(address(this).balance);
    }

    
  
}