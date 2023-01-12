/**
 *Submitted for verification at polygonscan.com on 2023-01-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface BEP20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ZFIGlobal {
    using SafeMath for uint256; 

    BEP20 public dai = BEP20(0x40819F0145Cf3e5a20c705609693dAF7591A15B8);

    uint256 private constant baseDivider = 10000;
    uint256 private constant timeStep = 1 minutes;// 1 days
    uint256 private constant timeStep7 = 7 minutes;// 7 days
    uint256 private constant minDeposit = 25e18;
    
    struct UserInfo {
        address referrer;
        bool isReg;
        uint256 refNo;
        uint256 myLastDeposit;
        uint256 totalIncome;
        uint256 totalWithdraw;
        uint256 isStar;
        uint256 isLeader;
        uint256 isManager;
        uint256 myRegister;
        mapping(uint256 => uint256) myActDirect;
        mapping(uint256 => uint256) business;
        mapping(uint256 => uint256) levelTeam;
        mapping(uint256 => uint256) specialTeam;
        mapping(uint256 => uint256) specialDate;
        mapping(uint256 => uint256) incomeArray;
        mapping(uint256 => uint256) b5Entry;
    }
    mapping(address=>UserInfo) public userInfo;
    
    struct UserDept{
        uint256 amount;
        uint256 depTime;
    }
    
    mapping(address => UserDept[]) public userDepts;
    address payable defaultRefer;
    address payable aggregator;
    uint256 public startTime;
    
    mapping(uint256 => uint256) reward;
    mapping(uint256 => uint256) manager_reward;
    address [] reward_array;
    address [] manager_array;
    
    event Register(address user, address referral);
    event Deposit(address user, uint256 amount);
    
    uint[] level_bonuses = [500, 200, 100, 200, 100, 200, 50, 50, 50, 50];  
    uint[] weekly_bonuses = [1600, 1200, 800, 400, 400, 600, 800, 600, 1200, 2400];  
    
    modifier onlyAggregator(){
        require(msg.sender == aggregator,"You are not authorized.");
        _;
    }

    modifier security {
        uint size;
        address sandbox = msg.sender;
        assembly { size := extcodesize(sandbox) }
        require(size == 0, "Smart contract detected!");
        _;
    }

    constructor() public {
        startTime = block.timestamp;
        defaultRefer = msg.sender;
        aggregator = msg.sender;
        userInfo[msg.sender].isReg = true;
        for(uint8 i=0;i < 7; i++){
            userInfo[msg.sender].b5Entry[i]=1;
        }
    }
    
    function contractInfo() public view returns(uint256 balance, uint256 init){
       return (address(this).balance,startTime);
    }
    
    function register(address _referral) external security{
        require(msg.sender != defaultRefer, "Sorry!");
        require(userInfo[_referral].myLastDeposit > 0 || _referral == defaultRefer, "invalid refer");
        
        UserInfo storage user = userInfo[msg.sender];
        require(user.isReg == false, "Already registered");
        require(userInfo[_referral].isReg == true, "Invalid Sponsor");
        require(user.referrer == address(0), "referrer bonded");
        user.isReg = true;
        user.referrer = _referral;
        user.refNo = userInfo[_referral].myRegister;
        userInfo[_referral].myRegister++;
        userInfo[msg.sender].incomeArray[7]=10000e18;
        userInfo[_referral].incomeArray[7]+=5000e18;
        emit Register(msg.sender, _referral);
    }

    function packageInfo(uint256 _pkg) pure private  returns(uint8 p) {
        if(_pkg == 50e18){
            p=1;
        }else if(_pkg == 100e18){
            p=2;
        }else if(_pkg == 200e18){
            p=3;
        }else if(_pkg == 400e18){
            p=4;
        }else if(_pkg == 800e18){
            p=5;
        }else if(_pkg == 1600e18){
            p=6;
        }else if(_pkg == 3200e18){
            p=7;
        }else if(_pkg == 6400e18){
            p=8;
        }else if(_pkg == 12800e18){
            p=9;
        }
        else{
            p=0;
        }
        return p;
    }
    
    function deposit(uint256 _amount) external security{
        uint8 poolNo=packageInfo(_amount);
        require(_amount>=minDeposit, "Invalid Package.");//msg.value
        require(userInfo[msg.sender].referrer != address(0), "Register First");
        require(userInfo[msg.sender].b5Entry[poolNo] == 0, "Already registered in pool.");
        dai.transferFrom(msg.sender,address(this),_amount);
        _deposit(msg.sender, _amount);//msg.value
        bountyBonus(msg.sender);
        levelRoiBonus(msg.sender);
        emit Deposit(msg.sender, _amount);//msg.value
    }

    function _deposit(address _user, uint256 _amount) private {
        bool _isReDept = false;
        if(userInfo[_user].myLastDeposit==0){
            userInfo[userInfo[_user].referrer].myActDirect[0]++;
        }else{
            _isReDept=true;
        }
        userInfo[_user].myLastDeposit=_amount;
       
        userDepts[_user].push(UserDept(
            _amount,
            block.timestamp
        ));
        _setReferral(_user,userInfo[_user].referrer,_amount,_isReDept);
    }

    function _setReferral(address _user,address _referral, uint256 _refAmount, bool _isReDept) private {
        for(uint256 i = 0; i < level_bonuses.length; i++) {
            if(_isReDept==false){
                if(_refAmount>=500e18){
                    userInfo[_referral].specialTeam[i]+=1;
                    uint256 reqTeam = 10**(i+1);
                    if(userInfo[_referral].myLastDeposit>=500e18 && userInfo[_referral].specialDate[i]==0 && userInfo[_referral].specialTeam[i]>=reqTeam){
                        userInfo[_referral].specialDate[i] = block.timestamp;
                    }
                }
                userInfo[_referral].levelTeam[userInfo[_user].refNo]+=1;
                if(i==0){
                    userInfo[_referral].business[0]+=_refAmount;
                }
                else{
                    userInfo[_referral].business[1]+=_refAmount;
                }
            }
           
            if(userInfo[_referral].isStar==0 || userInfo[_referral].isLeader==0 || userInfo[_referral].isManager==0){
                uint256 myteam = teamInfo(_referral);
                if(userInfo[_referral].isStar==0 && userInfo[_referral].myActDirect[0]>=3 && userInfo[_referral].myLastDeposit>=100e18 && userInfo[_referral].business[0]>=2500e18){
                    userInfo[_referral].isStar=1;
                    userInfo[userInfo[_referral].referrer].myActDirect[1]++;
                }
                if(userInfo[_referral].isLeader==0 && userInfo[_referral].myActDirect[1]>=2 && userInfo[_referral].myLastDeposit>=500e18 && myteam>=50){
                    userInfo[_referral].isLeader=1;
                    userInfo[userInfo[_referral].referrer].myActDirect[2]++;
                }
                if(userInfo[_referral].isManager==0 && userInfo[_referral].myActDirect[2]>=2 && userInfo[_referral].myLastDeposit>=1000e18 && myteam>=100){
                    userInfo[_referral].isManager=1;
                    userInfo[userInfo[_referral].referrer].myActDirect[3]++;
                }
            }
            
            if(i==0){
                userInfo[_referral].totalIncome+=_refAmount.mul(level_bonuses[i]).div(baseDivider);
                userInfo[_referral].incomeArray[0]+=_refAmount.mul(level_bonuses[i]).div(baseDivider);
            }else{
                if(userInfo[_referral].isStar==1 && i < 3){
                    userInfo[_referral].totalIncome+=_refAmount.mul(level_bonuses[i]).div(baseDivider);
                    userInfo[_referral].incomeArray[1]+=_refAmount.mul(level_bonuses[i]).div(baseDivider);
                }else if(userInfo[_referral].isLeader==1 && i >= 3 && i < 5){
                    userInfo[_referral].totalIncome+=_refAmount.mul(level_bonuses[i]).div(baseDivider);
                    userInfo[_referral].incomeArray[2]+=_refAmount.mul(level_bonuses[i]).div(baseDivider);
                }else if(userInfo[_referral].isManager==1 && i >= 5){
                    userInfo[_referral].totalIncome+=_refAmount.mul(level_bonuses[i]).div(baseDivider);
                    userInfo[_referral].incomeArray[3]+=_refAmount.mul(level_bonuses[i]).div(baseDivider);
                }
            }
            
           _user = _referral;
           _referral = userInfo[_referral].referrer;
            if(_referral == address(0)) break;
        }
    }

    function teamInfo(address _addr) private view returns(uint256 myteam){
        for(uint8 i = 0; i < level_bonuses.length; i++){
            myteam+=userInfo[_addr].levelTeam[i];
        }
        return myteam;
    }
    
    function royaltyReward(address _rewardWinner, uint256 _amount) external onlyAggregator security{
        //_rewardWinner.transfer(_amount);
        dai.transfer(_rewardWinner,_amount);
    }
    
    function getCurDay(uint256 init) public view returns(uint256) {
        return (block.timestamp.sub(init)).div(timeStep);
    }

    function getCur7Day(uint256 init) public view returns(uint256) {
        return (block.timestamp.sub(init)).div(timeStep7);
    }

    function withdraw(uint256 _amount) public security{
        require(_amount >= 10e18, "Minimum 10 need");
        bountyBonus(msg.sender);
        levelRoiBonus(msg.sender);
        UserInfo storage player = userInfo[msg.sender];
        uint256 bonus;
        bonus=player.totalIncome-player.totalWithdraw;
        require(_amount<=bonus,"Amount exceeds withdrawable");
        player.totalWithdraw+=_amount;
        //msg.sender.transfer(_amount);
        dai.transfer(msg.sender,_amount);
    }

    function bountyBonus(address _addr) private {
        uint256 inc = 0;
        for(uint256 i =0; i < 4; i++){
            if(userInfo[_addr].specialDate[i]>0){
                uint256 totalDays = getCurDay(userInfo[_addr].specialDate[i]);
                if(totalDays>0){
                    uint256 reqInc = 10**(i+1);
                    inc+=totalDays.mul(reqInc);
                }
            }
        }
        if(inc>0){
            uint256 binc = inc.sub(userInfo[_addr].incomeArray[6]);
            userInfo[_addr].incomeArray[6]+=binc;
            userInfo[_addr].totalIncome+=binc;
        }
    }

    function levelRoiBonus(address _addr) private {
        uint256 inc = 0;
        for(uint256 i =0; i < userDepts[_addr].length; i++){
            uint256 totalDays = getCur7Day(userDepts[_addr][i].depTime);
            totalDays = (totalDays>=10)?10:totalDays;
            if(totalDays>0){
                for(uint256  j = 1; j <= totalDays; j++){
                    inc+=j.mul(10).div(2).mul(1e18);
                }
            }
        }
        if(inc>0){
            uint256 roiInc = inc.sub(userInfo[_addr].incomeArray[4]);
            userInfo[_addr].incomeArray[4]+=roiInc;
            userInfo[_addr].totalIncome+=roiInc;
            _setLevelROI(userInfo[_addr].referrer,roiInc);
        }
    }

    function _setLevelROI(address _referral,uint256 _refAmount) private {
        for(uint256 i = 0; i < weekly_bonuses.length; i++) {
            userInfo[_referral].totalIncome+=_refAmount.mul(weekly_bonuses[i]).div(baseDivider);
            userInfo[_referral].incomeArray[0]+=_refAmount.mul(weekly_bonuses[i]).div(baseDivider);
           _referral = userInfo[_referral].referrer;
            if(_referral == address(0)) break;
        }
    }

    function teamDetails(address _addr) public view returns(uint256 [10] memory lteam, uint256 [10] memory steam, uint256 [10] memory sdays){
        for(uint8 i = 0; i < level_bonuses.length; i++){
            lteam[i]=userInfo[_addr].levelTeam[i];
            steam[i]=userInfo[_addr].specialTeam[i];
            sdays[i]=userInfo[_addr].specialDate[i];
        }
        return (lteam, steam, sdays);
    }

    function incomeDetails(address _addr) public view returns(uint256 [8] memory income){
        for(uint8 i = 0; i < 8; i++){
            income[i]=userInfo[_addr].incomeArray[i];
        }
        return income;
    }

    function userDetails(address _addr) public view returns(uint256 mydirects,uint256 mystar, uint256 myleader, uint256 mymanager){
        UserInfo storage player = userInfo[_addr];
        return (player.myActDirect[0], player.myActDirect[1], player.myActDirect[2],player.myActDirect[3]);
    }

    function bountyDetails(address _addr) public view returns(uint256){
        uint256 inc = 0;
        for(uint256 i =0; i < 4; i++){
            if(userInfo[_addr].specialDate[i]>0){
                uint256 totalDays = getCurDay(userInfo[_addr].specialDate[i]);
                if(totalDays>0){
                    uint256 reqInc = 10**(i+1);
                    inc+=totalDays.mul(reqInc);
                }
            }
        }
        return inc.sub(userInfo[_addr].incomeArray[6]);
    }

    function levelRoiDetails(address _addr) public view returns(uint256){
        uint256 inc = 0;
        for(uint256 i =0; i < userDepts[_addr].length; i++){
            uint256 totalDays = getCur7Day(userDepts[_addr][i].depTime);
            totalDays = (totalDays>=10)?10:totalDays;
            if(totalDays>0){
                for(uint256  j = 1; j <= totalDays; j++){
                    inc+=j.mul(10).div(2);
                }
            }
        }
        return inc.sub(userInfo[_addr].incomeArray[4]);
    }
    
}


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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function pow(uint256 a, uint256 b) internal pure returns (uint256){ 
        return a**b;
    }
}