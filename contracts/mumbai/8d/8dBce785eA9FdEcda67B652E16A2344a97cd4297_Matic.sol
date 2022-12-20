/**
 *Submitted for verification at polygonscan.com on 2022-12-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;


abstract contract Initializable {

    bool private _initialized;

    bool private _initializing;

    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

contract Matic is Initializable{
    uint256 IdProvider;
    address owner;
    address secondOwner;
    bool isWithdrawAvailable;

    uint256[11] InvestmentPercentage;

    uint256[11] WithdrawPercentage;

    uint256 [11] directTurnoverRecord;
    uint256 [11] teamTurnoverRecord; 

    struct userDetail {
        uint256 userID;
        address Useraddress;
        uint256 referalId;
        address referalAddress;
        uint256 UserTotalWthdrwal;
        uint256 userTotalInvestment;
        uint256 userDirectReferal;
        uint256 userTeamreferalEarnings;
        uint256 totalIncentive;
        mapping(uint8 => bool) activeX2Levels;
        mapping(uint8 => X2) x2Matrix;
        mapping(uint8=>uint) holdAmount;
    }

    struct X2 {
        address currentReferrer;
        address[] referrals;
    }

    mapping(address => userDetail) public UserAllDetailByAddress;
    mapping(address => mapping(uint8 => uint256)) public UserIncentiveDetail;
    mapping(address => mapping(uint8 => uint256)) public UserwithdrwalIncentiveDetail;
    mapping(address => uint256 ) public ReferalInPreviousAMonth;
    mapping(uint256 => address) public idToAddress;
    mapping(uint256 => uint256 ) public returnvalue;
    mapping(uint256 => uint256 ) public returnPrice;
    mapping(address => uint256 ) public MaticFiInUserWallet;
    mapping(address => bool) public isUserRegisterd;
    mapping(uint256 => bool) public IsIdValid;
    mapping(address => uint256) public UserMaticInCurrentPurchase;
    mapping(address => uint256) public lastWithdrawlMaticRecived;
    uint8 public LAST_LEVEL;
    uint public socialWelfare;

    mapping(uint8 => mapping(uint256 => address)) public x2vId_number;
    mapping(uint8 => uint256) public x2CurrentvId;
    mapping(uint8 => uint256) public x2Index;

    uint256[9] matrixPackage;
    uint256[9] matrixProfit;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlySecondOwner() {
        require(msg.sender == secondOwner);
        _;
    }

    event InvestmentDetail( address Buyer,address RefferedBy,uint256 referdbyId, uint256 AmountInvetsed );
    event register( address Buyer,address RefferedBy,uint userId, uint256 referdbyId, uint256 AmountInvetsed );
    event withdrawDetail( address WithdarawalBy , uint256 Amount);
    event Upgrade(address indexed user, address indexed referrer, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 level, uint8 place);
    event LeaderShipIncome(address indexed user , uint amount);
    event UserIncome(address sender ,address receiver,uint256 amount ,uint level,string _for);

    function initialize() external  initializer{
        LAST_LEVEL = 9;
        IdProvider = 4000;
        isWithdrawAvailable = true;
        matrixPackage =[5,9,18,44,104,328,992,6976,85856];
        matrixProfit = [1,18,100,600,3000,20000,120000,1700000,40000000];
        InvestmentPercentage = [10,4,2,1,1,1,1,1,2,2,3];
        WithdrawPercentage = [15,10,8,6,3,3,3,7,7,8,10 ];
        directTurnoverRecord = [0,100,200,300,400,500,600,700,800,900,1000];
        teamTurnoverRecord = [0,0,0,0,0,500,700,1000,1300,1600,2100];
        owner = msg.sender;
        secondOwner =0x4Bb8401E93fd89488F5D0cd099c3c40D49B1B5D0;
        UserAllDetailByAddress[msg.sender].userID =3999;
        IsIdValid[3999]=true;
        UserAllDetailByAddress[msg.sender].Useraddress=owner;
        idToAddress[3999]=owner;
        UserAllDetailByAddress[msg.sender].referalId=3998;
        UserAllDetailByAddress[msg.sender].referalAddress= 0x6Be705610b19Ff3412b64F628478B404FF311269;

        UserAllDetailByAddress[msg.sender].userTotalInvestment =100;
        UserAllDetailByAddress[msg.sender].userTeamreferalEarnings = 10000;

        returnvalue[2] = 5; 
        returnvalue[50] = 50; 
        returnvalue[75] = 70; 
        returnvalue[100] = 70; 

        returnPrice[0]=1; 
        returnPrice[1]=10; 
        returnPrice[2]=100; 
        returnPrice[3]=1000; 
        returnPrice[4]=10000; 
        returnPrice[5]=100000; 
        returnPrice[6]=1000000; 
        returnPrice[7]=10000000;
        returnPrice[8]=100000000;

        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            x2vId_number[i][1]=owner;
            x2Index[i]=1;
            x2CurrentvId[i]=1;
        }

        UserAllDetailByAddress[owner].activeX2Levels[1] = true;
        emit Upgrade(owner, UserAllDetailByAddress[owner].referalAddress, 1);
    }

    function Invest(uint256 _amount, uint256 _ReferdBy) public payable {
        
        // require( _amount >=10*1e18,"value must be greater than 10 matic" );
        require(_amount !=0 &&_amount % (15*1e18) == 0,"Amount must be multiple of 15!");
        require(IsIdValid[_ReferdBy]==true,"not Valid referal Id !!");
        require(_ReferdBy != 0,"Please Check Refral ID !! Not valid ID");
        // require(msg.value >= _amount,"Amount Transfer Issues !! Please check Issue");
        require(UserAllDetailByAddress[msg.sender].userID != _ReferdBy," This is not valid Action");

        // user info 
        uint256 IncentiveAmount = (_amount*2666)/10000; 
        
        if (UserAllDetailByAddress[msg.sender].userID == 0) {
            UserAllDetailByAddress[msg.sender].userID = IdProvider;
            idToAddress[IdProvider]=msg.sender;
            UserAllDetailByAddress[msg.sender].Useraddress = msg.sender;
            IsIdValid[IdProvider]=true;
            UserAllDetailByAddress[msg.sender].referalId = _ReferdBy;
            UserAllDetailByAddress[msg.sender].referalAddress = idToAddress[_ReferdBy];
            isUserRegisterd[msg.sender]= true;
            emit register(msg.sender,idToAddress[_ReferdBy],IdProvider,_ReferdBy,_amount);
            IdProvider++;
        }

        socialWelfare += ((IncentiveAmount * 5) / 100);

        // payable(owner).transfer((IncentiveAmount * 5) / 100);

        UserAllDetailByAddress[msg.sender].userTotalInvestment += _amount;
        UserAllDetailByAddress[idToAddress[_ReferdBy]].userDirectReferal += _amount;
        //direct transfer
        // UserAllDetailByAddress[idToAddress[_ReferdBy]].totalIncentive +=(IncentiveAmount * InvestmentPercentage[0]) / 100;
        // UserIncentiveDetail[idToAddress[_ReferdBy]][0] += (IncentiveAmount * InvestmentPercentage[0]) / 100;
        // emit UserIncome(msg.sender,idToAddress[_ReferdBy],(IncentiveAmount * InvestmentPercentage[0]) / 100,1,"LevelIncome");
      

        uint256 TurnOver = balanceInContract();
        uint256 MaticFi;

        uint256 principal = IncentiveAmount * 60/100; 

        if(TurnOver == 0*1e18) {
            MaticFi = (principal/returnPrice[0])/1e8 ;
        } else if(TurnOver > 0*1e18 && TurnOver <= 10*1e18) {
            MaticFi = (principal/returnPrice[1])/1e8 ;
        } else if(TurnOver > 10*1e18 && TurnOver <= 100*1e18 ) {
            MaticFi = (principal/returnPrice[2])/1e8 ;
        } else if(TurnOver > 100*1e18 && TurnOver <= 1000*1e18 ) {
            MaticFi = (principal/returnPrice[3])/1e8 ;
        } else if(TurnOver > 1000*1e18 && TurnOver <= 10000*1e18 ) {
            MaticFi = (principal/returnPrice[4])/1e8 ;
        } else if(TurnOver > 10000*1e18 && TurnOver <= 100000*1e18 ) {
            MaticFi = (principal/returnPrice[5])/1e8 ;
        } else if(TurnOver > 100000*1e18 && TurnOver <= 1000000 *1e18) {
            MaticFi = (principal/returnPrice[6])/1e8 ;
        } else if(TurnOver > 1000000*1e18 && TurnOver <= 10000000*1e18 ) {
            MaticFi = (principal/returnPrice[7])/1e8 ;
        } else if(TurnOver > 10000000*1e18 && TurnOver <= 100000000*1e18 ) {
            MaticFi = (principal/returnPrice[8])/1e8 ;
        } else if(TurnOver > 100000000*1e18 ) {
            MaticFi = (principal/returnPrice[8])/1e8 ;
        }

        UserMaticInCurrentPurchase[msg.sender] = MaticFi;

        MaticFiInUserWallet[msg.sender] += MaticFi;

        address _referrer = UserAllDetailByAddress[msg.sender].referalAddress;

        for (uint8 i = 0; i < 12; i++) {
            if (_referrer != address(0)) {
                if(i !=0) {
                    UserAllDetailByAddress[_referrer].userTeamreferalEarnings += _amount;
                    if(directTurnoverRecord[i] <= UserAllDetailByAddress[_referrer].userDirectReferal && teamTurnoverRecord[i] <= UserAllDetailByAddress[_referrer].userTeamreferalEarnings ){
                        UserAllDetailByAddress[_referrer].totalIncentive +=(IncentiveAmount * InvestmentPercentage[i]) / 100;
                        UserIncentiveDetail[idToAddress[_ReferdBy]][i] +=(IncentiveAmount * InvestmentPercentage[i]) / 100;
                        emit UserIncome(msg.sender,_referrer, ((IncentiveAmount * InvestmentPercentage[i]) / 100), i+1 ,"LevelIncome" );
                    } 
                }

                if (UserAllDetailByAddress[_referrer].referalAddress != address(0) )
                    _referrer = UserAllDetailByAddress[_referrer].referalAddress;
                else break;
            }
        }

        UserAllDetailByAddress[msg.sender].activeX2Levels[1] = true; 
        address freeX6Referrer = findFreeX6Referrer(1);
        UserAllDetailByAddress[msg.sender].x2Matrix[1].currentReferrer = freeX6Referrer;
        // UserAllDetailByAddress[msg.sender].holdAmount[1] = ((_amount*3333)/10000);
        updateX6Referrer(msg.sender, freeX6Referrer, 1);
        emit Upgrade(msg.sender, UserAllDetailByAddress[msg.sender].referalAddress, 1);

    }

    function withdrawAmount(uint256 _amount) public {

        require(isWithdrawAvailable == true ," Currently Withdrawl Is Unavaible");
        require(MaticFiInUserWallet[msg.sender] > 0," User balance is zero !! Unable To Complete transanction");

        uint256 TurnOver = balanceInContract();
        
        uint256 Maticrem;

        uint256 userDemanded = _amount ;

        userDemanded = (MaticFiInUserWallet[msg.sender] * userDemanded)/100; 

        require(MaticFiInUserWallet[msg.sender] >= userDemanded ,"Not Enough Maticfi !! Please Purchase More to Continue");

        if(TurnOver == 0*1e18) {
            Maticrem = (userDemanded*returnPrice[0])/1e8;
        } else if(TurnOver > 0*1e18 && TurnOver <= 10*1e18 ) {
            Maticrem = (userDemanded*returnPrice[1])/1e8 ;
        } else if(TurnOver > 10*1e18 && TurnOver <= 100*1e18 ) {
            Maticrem = (userDemanded*returnPrice[2])/1e8 ;
        } else if(TurnOver > 100*1e18 && TurnOver <= 1000*1e18 ) {
            Maticrem = (userDemanded*returnPrice[3])/1e8 ;
        } else if(TurnOver > 1000*1e18 && TurnOver <= 10000*1e18 ) {
            Maticrem = (userDemanded*returnPrice[4])/1e8 ;
        } else if(TurnOver > 10000*1e18 && TurnOver <= 100000*1e18 ) {
            Maticrem = (userDemanded*returnPrice[5])/1e8 ;
        } else if(TurnOver > 100000*1e18 && TurnOver <= 1000000*1e18 ) {
            Maticrem = (userDemanded*returnPrice[6])/1e8 ;
        } else if(TurnOver > 1000000*1e18 && TurnOver <= 10000000*1e18 ) {
            Maticrem = (userDemanded*returnPrice[7])/1e8 ;
        } else if(TurnOver > 10000000*1e18 && TurnOver <= 100000000*1e18 ) { 
            Maticrem = (userDemanded*returnPrice[8])/1e8 ;
        } else if(TurnOver > 100000000*1e18 ) {
            Maticrem = (userDemanded*returnPrice[8])/1e8 ;
        }

        MaticFiInUserWallet[msg.sender] = MaticFiInUserWallet[msg.sender] - userDemanded;

        uint256 levelWillGet = (Maticrem * returnvalue[_amount])/100; 

        // payable(msg.sender).transfer(userDemanded - levelWillGet);
        lastWithdrawlMaticRecived[msg.sender] = userDemanded - levelWillGet;
        uint256 Amount;

        UserAllDetailByAddress[msg.sender].UserTotalWthdrwal += userDemanded;

        uint256 refBalance = levelWillGet;
        Amount = refBalance;
        refBalance = (refBalance * 80) / 100;

        emit withdrawDetail(msg.sender,userDemanded);

        address _referrer = UserAllDetailByAddress[msg.sender].referalAddress;

        for (uint8 i = 0; i < 12; i++) {
            if (_referrer != address(0)){
                UserAllDetailByAddress[_referrer].totalIncentive +=(refBalance * WithdrawPercentage[i]) / 100;
                UserwithdrwalIncentiveDetail[_referrer][i] += (refBalance * WithdrawPercentage[i]) / 100;
                emit UserIncome(msg.sender,_referrer, ((refBalance * WithdrawPercentage[i]) / 100), i+1 ,"LevelBonus" );
                if ( UserAllDetailByAddress[_referrer].referalAddress !=address(0))
                _referrer = UserAllDetailByAddress[_referrer].referalAddress;
                else break;
            }
        } 

        uint256 adminwallet = ((Amount * 20) / 100);
        payable(owner).transfer(adminwallet);

    }

    function TransferAmountToOwnerWallet() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    function balanceInContract() public view returns (uint256){
        return address(this).balance;

    } 

    function ClaimIncentiveReward () public payable{
        require( UserAllDetailByAddress[msg.sender].totalIncentive > 0,"available balance Is Zero ");
        payable(msg.sender).transfer(UserAllDetailByAddress[msg.sender].totalIncentive);
        UserAllDetailByAddress[msg.sender].totalIncentive = 0;
    } 

    function ChangeOwner (address newOwner) public onlyOwner{
        owner = newOwner;
    }

    function ChangeSecondOwner (address newOwner) public onlyOwner{
        secondOwner = newOwner;
    }

    function stopWithdrawl(bool _status) public onlyOwner{
        isWithdrawAvailable = _status;
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(level<=LAST_LEVEL,"not valid level");
        if(referrerAddress==userAddress) return;
        uint256 newIndex=x2Index[level]+1;
        x2vId_number[level][newIndex]=userAddress;
        x2Index[level]=newIndex;
        
        if(UserAllDetailByAddress[referrerAddress].x2Matrix[level].referrals.length < getNumberofmember(level)) {
            UserAllDetailByAddress[referrerAddress].x2Matrix[level].referrals.push(userAddress);
            UserAllDetailByAddress[referrerAddress].holdAmount[level]+=matrixPackage[level];
            emit NewUserPlace(userAddress, referrerAddress, level, uint8(UserAllDetailByAddress[referrerAddress].x2Matrix[level].referrals.length));

        if(level<9 && UserAllDetailByAddress[referrerAddress].holdAmount[level]>=matrixPackage[level+1]&&UserAllDetailByAddress[referrerAddress].x2Matrix[level].referrals.length==getNumberofmember(level))
        {
        
        
        //Next Pool Upgradation
        UserAllDetailByAddress[referrerAddress].holdAmount[level] = UserAllDetailByAddress[referrerAddress].holdAmount[level]-matrixPackage[level+1];
        x2CurrentvId[level]=x2CurrentvId[level]+1; 
        autoUpgrade(referrerAddress, (level+1));
        // uint256 _amount= UserAllDetailByAddress[referrerAddress].holdAmount[level];
        
        
        //net holding ammount sent to UserAllDetailByAddress
        // payable(referrerAddress).transfer(UserAllDetailByAddress[referrerAddress].holdAmount[level]);
        emit UserIncome(userAddress,referrerAddress,UserAllDetailByAddress[referrerAddress].holdAmount[level],level,"AutoPool");
        UserAllDetailByAddress[referrerAddress].holdAmount[level]=0;
        // emit ReEntry(referrerAddress,level);
        }
            if(level==9 && UserAllDetailByAddress[referrerAddress].x2Matrix[level].referrals.length==getNumberofmember(level))
            {

                emit UserIncome(userAddress,referrerAddress,UserAllDetailByAddress[referrerAddress].holdAmount[level],level,"AutoPool");
                UserAllDetailByAddress[referrerAddress].holdAmount[level]=0;
            }
        }

        
    }

    function autoUpgrade(address _user, uint8 level) private {
        UserAllDetailByAddress[_user].activeX2Levels[level] = true;
        
        // address freeX6Referrer = findFreeX6Referrer(level-1);
        // users[_user].x6Matrix[level-1].currentReferrer = freeX6Referrer;
        // updateX6Referrer(_user, freeX6Referrer, level-1);
        
        address freeX6Referrer = findFreeX6Referrer(level);
        UserAllDetailByAddress[_user].x2Matrix[level].currentReferrer = freeX6Referrer;
        updateX6Referrer(_user, freeX6Referrer, level);
        emit Upgrade(_user, freeX6Referrer, level);
    }

    function findFreeX6Referrer(uint8 level) public view returns(address){
        uint256 id=x2CurrentvId[level];
        return x2vId_number[level][id];
    }

    function getNumberofmember(uint8 _level) internal pure returns (uint8 num) {
        num=1;
        for(uint8 i=1; i<=_level;i++){
        num = num*2;
        }
    } 

    function usersX2Matrix(address userAddress, uint8 level) public view returns(address, address[] memory) {
            return (UserAllDetailByAddress[userAddress].x2Matrix[level].currentReferrer,
            UserAllDetailByAddress[userAddress].x2Matrix[level].referrals);
    }

    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool ,uint) {
        return (UserAllDetailByAddress[userAddress].activeX2Levels[level],UserAllDetailByAddress[userAddress].holdAmount[level]);
    }


 receive() external payable {}

}