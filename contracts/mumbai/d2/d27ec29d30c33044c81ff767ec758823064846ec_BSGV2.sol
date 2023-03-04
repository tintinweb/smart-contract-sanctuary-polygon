/**
 *Submitted for verification at polygonscan.com on 2023-03-03
*/

// SPDX-License-Identifier: GPLv3
pragma solidity ^0.6.12;

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
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract BSGV2 {
    using SafeMath for uint256; 
    IERC20 public usdt;
    uint256 private constant baseDivider = 10000;
    uint256 private constant feePercents = 300; 
    uint256 private constant minDeposit = 50e18;
    uint256 private constant maxDeposit = 2500e18;
    uint256 private constant freezeIncomePercents = 3000;
    uint256 private constant timeStep =5*60;

    uint256 private constant dayPerCycle = 15*5*60; 
    uint256 private dayRewardPercents = 150;
    uint256 private constant maxAddFreeze = 45*5*60;
    uint256 private constant referDepth = 21;
    uint256 private constant directPercents = 600;
    uint256[2] private levelStar2Percents = [200, 200];
    uint256[2] private levelStar3Percents = [100, 300];
    uint256[16] private levelStar4Percents = [75, 75, 75, 75, 75, 100, 100, 100, 100, 100,50, 50, 50, 50, 50,50];

    uint256 private constant star3UserPercents = 50;
    uint256 private constant star4UserPercents = 50;
    uint256 private constant star5UserPercents = 50;
    uint256 private constant clubPoolPercents = 30;
    uint256[6] private boosterInterval = [14 days,30 days,47 days,65 days,84 days,104 days];
    uint256[10] private balDown = [10e22,20e22, 30e22,50e22, 100e22, 200e22, 500e22,1000e22,1500e22,2000e22];
    uint256[10] private balDownRate = [1000,1000,1000,1000, 1000, 1000, 1000,1000,1000,1000]; 
    uint256[10] private balRecover = [105e21,210e21,315e21,525e21,110e22,200e22,500e22, 1000e22,1500e22,2000e22];
    mapping(uint256=>bool) public balStatus; 

    address[2] public feeReceivers;
    address public defaultRefer;
    address public oldscPool;
    address public contractAddress;
    uint256 public startTime;
    uint256 public lastDistribute;
    uint256 public totalUser;
    uint256 public clubPool;

    uint256 public star3Pool;
    uint256 public star4Pool;
    uint256 public star5Pool;
    address[] public Star3Users;
    address[] public Star4Users;
    address[] public Star5Users;
    mapping(uint256 => mapping(address => uint256)) public clubDayDeposit; 
    mapping(uint256=>address[]) public dayClubUsers;  
    struct OrderInfo {
        uint256 amount; 
        uint256 start;
        uint256 unfreeze; 
        bool isUnfreezed;
    }
    mapping(address => OrderInfo[]) public orderInfos;
    address[] public depositors;
    struct UserInfo {
        address referrer;
        uint256 start;
        uint256 startdeposit;
        uint256 level;
        bool boosteractive;
        uint256 maxDeposit;
        uint256 totalDeposit;
        uint256 teamNum;
        uint256 directnum;
        uint256 maxDirectDeposit;
        uint256 teamTotalDeposit;
        uint256 totalFreezed;
        uint256 totalRevenue;
    }
    struct TriggerInfo {
        bool triggeractive;
        uint256 maxDeposit;
        bool directactive;
    }
    mapping(address=>UserInfo) public userInfo;
    mapping(address=>TriggerInfo) public triggerInfo;
    mapping(address => mapping(uint256 => address[])) public teamUsers;

    struct RewardInfo{
        uint256 capitals;
        uint256 statics;
        uint256 directs;        
        uint256 star3;
        uint256 star4;
        uint256 star5;
        uint256 clubpool;
        uint256 split;
        uint256 splitDebt;
    }
    struct RewardInfoFreeze{
        uint256 level3Freezed;
        uint256 level3Released;
        uint256 level4Left;
        uint256 level4Freezed;
        uint256 level4Released;
        uint256 level5Left;
        uint256 level5Freezed;
        uint256 level5Released;
        
    }
    mapping(address=>RewardInfo) public rewardInfo;
    mapping(address=>RewardInfoFreeze) public rewardInfoFreeze;
    
    bool public isFreezeReward;

    event Register(address user, address referral);
    event Deposit(address user, uint256 amount);
    event DepositBySplit(address user, uint256 amount);
    event TransferBySplit(address user, address receiver, uint256 amount);
    event Withdraw(address user, uint256 withdrawable);

    constructor(address _daiAddr) public {
        usdt = IERC20(_daiAddr);
        feeReceivers[0] = address(0xaDB65ee9D61DAE15fd410a8667a98172DC9aa9ec);
        feeReceivers[1] = address(0xf27e772867E9681CBbC190f762ea2c576561b918);
        oldscPool=0xA202E9e5aAf70B4e105d187306f406D8ACa482C4;
        startTime = block.timestamp;
        lastDistribute = block.timestamp;
        defaultRefer = 0x7f203d9E0FEbbC8eaddadCA7d7ff330a83Df8Bbe;
    }
    function registerFor(address _referral,address _userAddress) external {
        require(userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer, "invalid refer");
        UserInfo storage user = userInfo[_userAddress];
        require(user.referrer == address(0), "referrer bonded");
        user.referrer = _referral;
        user.start = block.timestamp; 
        user.boosteractive=false;     
        triggerInfo[_userAddress].triggeractive=true;  
        triggerInfo[_userAddress].directactive=true;
        triggerInfo[_userAddress].maxDeposit=0;  
        totalUser = totalUser.add(1);
        emit Register(_userAddress, _referral);
    }   
    function register(address _referral) external {
        require(userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer, "invalid refer");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "referrer bonded");
        user.referrer = _referral;
        user.start = block.timestamp; 
        user.boosteractive=false;     
        triggerInfo[msg.sender].triggeractive=true;  
        triggerInfo[msg.sender].directactive=true;
        triggerInfo[msg.sender].maxDeposit=0;  
        totalUser = totalUser.add(1);
        emit Register(msg.sender, _referral);
    }   
    function deposit(uint256 _amount) external {
        usdt.transferFrom(msg.sender, address(this), _amount);
        _deposit(msg.sender, _amount);
        emit Deposit(msg.sender, _amount);
    }
    function depositFor(address _userAddress,uint256 _amount) external {
        usdt.transferFrom(msg.sender, address(this), _amount);
        _deposit(_userAddress, _amount);
        emit Deposit(_userAddress, _amount);
    }
    function depositByWorkingBonus(uint256 _amount) external {

        require(_amount >= minDeposit && _amount.mod(minDeposit) == 0, "amount err");
        require(userInfo[msg.sender].totalDeposit == 0, "actived");        
        uint256 splitLeft = getCurSplit(msg.sender);
        require(splitLeft >= _amount, "insufficient split");
        rewardInfo[msg.sender].splitDebt = rewardInfo[msg.sender].splitDebt.add(_amount);
        _deposit(msg.sender, _amount);
        emit DepositBySplit(msg.sender, _amount);
    }
	function transferByWorkingBonus(address _receiver, uint256 _amount) external {
        require(_amount >= minDeposit && _amount.mod(minDeposit) == 0, "amount err");        
        require(userInfo[msg.sender].boosteractive, "booster not active");
        uint256 splitLeft = getCurSplit(msg.sender);
        require(splitLeft >= _amount, "insufficient income");
        rewardInfo[msg.sender].splitDebt = rewardInfo[msg.sender].splitDebt.add(_amount);
        rewardInfo[_receiver].split = rewardInfo[_receiver].split.add(_amount);
        emit TransferBySplit(msg.sender, _receiver, _amount);
    }
    function activeBooster(address _user) private {
        for(uint i=0;i<boosterInterval.length;i++)
        {
            if(userInfo[_user].startdeposit+boosterInterval[i]>=block.timestamp && userInfo[_user].maxDeposit*(i+2)<=userInfo[_user].maxDirectDeposit){
                userInfo[_user].boosteractive=true;
                break ;
            }
        }
    }
    function _deposit(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        require(user.referrer != address(0), "register first");
        require(_amount >= minDeposit, "less than min");
        require(_amount.mod(minDeposit) == 0 && _amount >= minDeposit, "mod err");
        require(user.maxDeposit == 0 || _amount >= user.maxDeposit, "less before");

        if(user.maxDeposit == 0){
            user.startdeposit=block.timestamp; 
            user.maxDeposit = _amount;
            userInfo[user.referrer].directnum = userInfo[user.referrer].directnum.add(1);            
            _updateTeamNum(_user);
            if(!triggerInfo[user.referrer].triggeractive){
                triggerInfo[user.referrer].maxDeposit=triggerInfo[user.referrer].maxDeposit.add(_amount);
                if(userInfo[user.referrer].maxDeposit>=50e18 && userInfo[user.referrer].maxDeposit<=500e18 && triggerInfo[user.referrer].maxDeposit>=50e18){
                    triggerInfo[user.referrer].triggeractive=true;
                    triggerInfo[user.referrer].directactive=false;
                    triggerInfo[user.referrer].maxDeposit=0;
                }
                else if(userInfo[user.referrer].maxDeposit>500e18 && userInfo[user.referrer].maxDeposit<=1000e18 && triggerInfo[user.referrer].maxDeposit>=100e18){
                    triggerInfo[user.referrer].triggeractive=true;
                    triggerInfo[user.referrer].directactive=false;
                    triggerInfo[user.referrer].maxDeposit=0;
                }
                else if(userInfo[user.referrer].maxDeposit>1000e18 && userInfo[user.referrer].maxDeposit<=2000e18 && triggerInfo[user.referrer].maxDeposit>=200e18){
                    triggerInfo[user.referrer].triggeractive=true;
                    triggerInfo[user.referrer].directactive=false;
                    triggerInfo[user.referrer].maxDeposit=0;
                }
                else if(userInfo[user.referrer].maxDeposit>2000e18 && userInfo[user.referrer].maxDeposit<=2500e18 && triggerInfo[user.referrer].maxDeposit>=500e18){
                    triggerInfo[user.referrer].triggeractive=true;
                    triggerInfo[user.referrer].directactive=false;
                    triggerInfo[user.referrer].maxDeposit=0;
                }
            }
        }else if(user.maxDeposit < _amount){
            user.maxDeposit = _amount;
            if(userInfo[_user].boosteractive){
                userInfo[_user].boosteractive=false;
            }
        }        
        _distributeDeposit(_amount);
        depositors.push(_user);        
        user.totalDeposit = user.totalDeposit.add(_amount);
        user.totalFreezed = user.totalFreezed.add(_amount);
        _updateLevel(_user);
        uint256 addFreeze = (orderInfos[_user].length).mul(timeStep);
        if(addFreeze > maxAddFreeze){
            addFreeze = maxAddFreeze;
        }
        uint256 unfreezeTime = block.timestamp.add(dayPerCycle).add(addFreeze);
        orderInfos[_user].push(OrderInfo(
            _amount, 
            block.timestamp, 
            unfreezeTime,
            false
        ));
        _unfreezeFundAndUpdateReward(_user, _amount);
        distributePoolRewards();        
        userInfo[user.referrer].maxDirectDeposit = userInfo[user.referrer].maxDirectDeposit.add(_amount);
        if(!userInfo[user.referrer].boosteractive){
            activeBooster(user.referrer);
        }
        uint256 dayNow = getCurDay();
        _updateClubPoolUser(user.referrer, _amount, dayNow);
        _updateReferInfo(_user, _amount);
        _updateReward(_user, _amount);
        _releaseUpRewards(_user, _amount);

        uint256 bal = usdt.balanceOf(address(this));
        _balActived(bal);
        if(isFreezeReward){
            _setFreezeReward(bal);
        }
    } 
    function _updateTeamNum(address _user) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                userInfo[upline].teamNum = userInfo[upline].teamNum.add(1);
                teamUsers[upline][i].push(_user);
                _updateLevel(upline);
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }
	

    
    function _updateLevel(address _user) private {
        UserInfo storage user = userInfo[_user];
        uint256 levelNow = _calLevelNow(_user);
        if(levelNow > user.level){
            user.level = levelNow;
            if(levelNow == 3){        
                Star3Users.push(_user);
            }
            if(levelNow == 4){        
                Star4Users.push(_user);
            }
            if(levelNow == 5){        
                Star5Users.push(_user);
            }
        }
    }
    function _calLevelNow(address _user) private view returns(uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 total = user.maxDeposit;
        uint256 totaldirectnum  = user.directnum;
        uint256 totaldirectdepositnum  = user.maxDirectDeposit;
        uint256 levelNow;
        if(total >= 500e18){
            (uint256 maxTeam, uint256 otherTeam, ) = getTeamDeposit(_user);            
            if(total >= 2500e18 && totaldirectnum>=20 && totaldirectdepositnum>=10000e18   && user.teamNum >= 300 && maxTeam >= 80000e18 &&  otherTeam >= 80000e18  ){
                levelNow = 5;
            }else if(total >= 2000e18 && totaldirectnum>=10 && totaldirectdepositnum>=5000e18 && user.teamNum >= 150 && maxTeam >= 40000e18 &&  otherTeam >= 40000e18  ){
                levelNow = 4;
            }else if(total >= 500e18  && totaldirectnum >=5 && totaldirectdepositnum>=1000e18 && user.teamNum >= 40 && maxTeam >= 5000e18 &&  otherTeam >= 5000e18  ){
                levelNow = 3;
            }
            else if(total >= 200e18 && totaldirectnum>=3  && totaldirectdepositnum>=500e18)
            {
               levelNow = 2;
            }
            else if(totaldirectnum >= 1){
              levelNow = 1;
            }
        }else if(total>= 200e18 && totaldirectnum>=3 && totaldirectdepositnum>=500e18){
            levelNow = 2;
        }else if(total >= 50){
            levelNow = 1;
        }
        return levelNow;
    }
    function getTeamDeposit(address _user) public view returns(uint256, uint256, uint256){
        uint256 totalTeam;
        uint256 maxTeam;
        uint256 otherTeam;
        for(uint256 i = 0; i < teamUsers[_user][0].length; i++){
            uint256 userTotalTeam = userInfo[teamUsers[_user][0][i]].teamTotalDeposit.add(userInfo[teamUsers[_user][0][i]].totalDeposit);
            totalTeam = totalTeam.add(userTotalTeam);
            if(userTotalTeam > maxTeam){
                maxTeam = userTotalTeam;
            }
        }
        otherTeam = totalTeam.sub(maxTeam);
        return(maxTeam, otherTeam, totalTeam);
    }
    function _distributeDeposit(uint256 _amount) private {
        uint256 fee = _amount.mul(feePercents).div(baseDivider);
        uint256 oldsc = _amount.mul(500).div(baseDivider);
        usdt.transfer(feeReceivers[0], fee.div(2));
        usdt.transfer(feeReceivers[1], fee.div(2));
        if(oldscPool!=address(0))
        usdt.transfer(oldscPool, oldsc);
     
        uint256 star3 = _amount.mul(star3UserPercents).div(baseDivider);
        star3Pool = star3Pool.add(star3); 
		
		uint256 star4 = _amount.mul(star4UserPercents).div(baseDivider);
        star4Pool = star4Pool.add(star4);

        uint256 star5 = _amount.mul(star5UserPercents).div(baseDivider);
        star5Pool = star5Pool.add(star5); 

        uint256 club = _amount.mul(clubPoolPercents).div(baseDivider);
        clubPool = clubPool.add(club);
    }
    function getdayRewardPercents() public returns(uint256)
    {
        uint256 bal = usdt.balanceOf(address(this));
        if(bal<2000000e18)
        {
           dayRewardPercents=170;
        }
        else if(bal>=2000000e18 && bal>4000000e18)
        {
           dayRewardPercents=175;
        }
        else if(bal>=4000000e18 && bal>8000000e18)
        {
           dayRewardPercents=180;
        }
        else if(bal>=8000000e18 && bal>16000000e18)
        {
           dayRewardPercents=185;
        }
        else if(bal>=16000000e18 && bal>32000000e18)
        {
           dayRewardPercents=190;
        }
        else if(bal>=32000000e18)
        {
           dayRewardPercents=200;
        }
        return dayRewardPercents;
    }
    function _unfreezeFundAndUpdateReward(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        bool isUnfreezeCapital;
        for(uint256 i = 0; i < orderInfos[_user].length; i++){
            OrderInfo storage order = orderInfos[_user][i];
            if(block.timestamp > order.unfreeze  && order.isUnfreezed == false && _amount >= order.amount){
                order.isUnfreezed = true;
                isUnfreezeCapital = true;
                
                if(user.totalFreezed > order.amount){
                    user.totalFreezed = user.totalFreezed.sub(order.amount);
                }else{
                    user.totalFreezed = 0;
                }
                
                _removeInvalidDeposit(_user, order.amount);
                uint256 dayRPercents=getdayRewardPercents();
                uint256 staticReward = order.amount.mul(dayRPercents).mul(dayPerCycle).div(timeStep).div(baseDivider);
                if(isFreezeReward){
                    if(user.totalFreezed > user.totalRevenue){
                        uint256 leftCapital = user.totalFreezed.sub(user.totalRevenue);
                        if(staticReward > leftCapital){
                            staticReward = leftCapital;
                        }
                    }else{
                        staticReward = 0;
                        if(triggerInfo[_user].triggeractive && triggerInfo[_user].directactive)
                        {
                            triggerInfo[_user].triggeractive=false;
                        }
                    }
                }
                else {
                    triggerInfo[_user].directactive=true;
                    triggerInfo[_user].triggeractive=true;
                }
                rewardInfo[_user].capitals = rewardInfo[_user].capitals.add(order.amount);
                rewardInfo[_user].statics = rewardInfo[_user].statics.add(staticReward);                
                user.totalRevenue = user.totalRevenue.add(staticReward);
                break;
            }
        }

        if(!isUnfreezeCapital){ 
            RewardInfoFreeze storage userReward = rewardInfoFreeze[_user];
            if(userReward.level5Freezed > 0){
                uint256 release = _amount;
                if(_amount >= userReward.level5Freezed){
                    release = userReward.level5Freezed;
                }
                userReward.level5Freezed = userReward.level5Freezed.sub(release);
                userReward.level5Released = userReward.level5Released.add(release);
                user.totalRevenue = user.totalRevenue.add(release);
            }
        }
    }
    function _updateClubPoolUser(address _user,uint256 _amount,uint256 _dayNow) private {
        clubDayDeposit[_dayNow][_user] = clubDayDeposit[_dayNow][_user].add(_amount);
        bool updated;
        for(uint256 i = 0; i < dayClubUsers[_dayNow].length; i++){
            address clubUser = dayClubUsers[_dayNow][i];
            if(clubUser == _user){
                updated = true;
                break;
            }
        }
        if(!updated && clubDayDeposit[_dayNow][_user]>=800e18){
            dayClubUsers[_dayNow].push(_user);
        }
    } 
    function distributePoolRewards() public {
        if(block.timestamp > lastDistribute.add(12*timeStep)){ 
            uint256 dayNow = getCurDay();
           _distributeStar3Pool(); 
           _distributeStar4Pool();
           _distributeStar5Pool();
           _distributeClubPool(dayNow);
            star3Pool=0;
            star4Pool=0;
            star5Pool=0;
            clubPool=0;
            lastDistribute = block.timestamp;
        }
    }
    function getCurDay() public view returns(uint256) {
        return (block.timestamp.sub(startTime)).div(timeStep);
    }

    function getTeamUsersLength(address _user, uint256 _layer) external view returns(uint256) {
        return teamUsers[_user][_layer].length;
    }

    function getOrderLength(address _user) external view returns(uint256) {
        return orderInfos[_user].length;
    }

    function getDepositorsLength() external view returns(uint256) {
        return depositors.length;
    }
    function _distributeStar3Pool() private {
        uint256 star3Count;
        for(uint256 i = 0; i < Star3Users.length; i++){
            if(userInfo[Star3Users[i]].level == 3){
                star3Count = star3Count.add(1);
            }
        }
        if(star3Count > 0){
            uint256 reward = star3Pool.div(star3Count);
            for(uint256 i = 0; i < Star3Users.length; i++){
                if(userInfo[Star3Users[i]].level == 3){
                    rewardInfo[Star3Users[i]].star3 = rewardInfo[Star3Users[i]].star3.add(reward);
                    userInfo[Star3Users[i]].totalRevenue = userInfo[Star3Users[i]].totalRevenue.add(reward);
                }
            }
        }
        else {
            rewardInfo[defaultRefer].star3 = rewardInfo[defaultRefer].star3.add(star3Pool);
            userInfo[defaultRefer].totalRevenue = userInfo[defaultRefer].totalRevenue.add(star3Pool);
        }
    }
	function _distributeStar4Pool() private {
        uint256 star4Count;
        for(uint256 i = 0; i < Star4Users.length; i++){
            if(userInfo[Star4Users[i]].level == 4){
                star4Count = star4Count.add(1);
            }
        }
        if(star4Count > 0){
            uint256 reward = star4Pool.div(star4Count);
            for(uint256 i = 0; i < Star4Users.length; i++){
                if(userInfo[Star4Users[i]].level == 4){
                    rewardInfo[Star4Users[i]].star4 = rewardInfo[Star4Users[i]].star4.add(reward);
                    userInfo[Star4Users[i]].totalRevenue = userInfo[Star4Users[i]].totalRevenue.add(reward);
                }
            }
        }
        else {
            rewardInfo[defaultRefer].star4 = rewardInfo[defaultRefer].star4.add(star4Pool);
            userInfo[defaultRefer].totalRevenue = userInfo[defaultRefer].totalRevenue.add(star4Pool);
        }
    }
    function _distributeStar5Pool() private {
        uint256 star5Count;
        for(uint256 i = 0; i < Star5Users.length; i++){
            if(userInfo[Star5Users[i]].level == 5){
                star5Count = star5Count.add(1);
            }
        }
        if(star5Count > 0){
            uint256 reward = star5Pool.div(star5Count);
            for(uint256 i = 0; i < Star5Users.length; i++){
                if(userInfo[Star5Users[i]].level == 5){
                    rewardInfo[Star5Users[i]].star5 = rewardInfo[Star5Users[i]].star5.add(reward);
                    userInfo[Star5Users[i]].totalRevenue = userInfo[Star5Users[i]].totalRevenue.add(reward);
                }
            }
        }
        else {
            rewardInfo[defaultRefer].star5 = rewardInfo[defaultRefer].star5.add(star5Pool);
            userInfo[defaultRefer].totalRevenue = userInfo[defaultRefer].totalRevenue.add(star5Pool);
        }
    }
    function _distributeClubPool(uint256 _dayNow) public {
        uint256 clubCount=dayClubUsers[_dayNow - 1].length;
        if(clubCount > 0){
            uint256 reward = clubPool/clubCount;
            for(uint256 i = 0; i < dayClubUsers[_dayNow - 1].length; i++){
                address userAddr = dayClubUsers[_dayNow - 1][i];
                rewardInfo[userAddr].clubpool = rewardInfo[userAddr].clubpool.add(reward);
                userInfo[userAddr].totalRevenue = userInfo[userAddr].totalRevenue.add(reward);
            }
        }
        else {
            rewardInfo[defaultRefer].clubpool = rewardInfo[defaultRefer].clubpool.add(clubPool);
            userInfo[defaultRefer].totalRevenue = userInfo[defaultRefer].totalRevenue.add(clubPool);
        }
    }
    
    function getCurSplit(address _user) public view returns(uint256){
        (, uint256 staticSplit) = _calCurStaticRewards(_user);
        (, uint256 dynamicSplit) = _calCurDynamicRewards(_user);
        return rewardInfo[_user].split.add(staticSplit).add(dynamicSplit).sub(rewardInfo[_user].splitDebt);
    }
    function _calCurStaticRewards(address _user) private view returns(uint256, uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = userRewards.statics;
        uint256 splitAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);
        uint256 withdrawable = totalRewards.sub(splitAmt);
        return(withdrawable, splitAmt);
    }

    function _calCurDynamicRewards(address _user) private view returns(uint256, uint256) {
        RewardInfoFreeze storage userRewardf = rewardInfoFreeze[_user];
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = userRewards.directs.add(userRewardf.level3Released).add(userRewardf.level4Released).add(userRewardf.level5Released);
        totalRewards = totalRewards.add(userRewards.star3.add(userRewards.star4).add(userRewards.star5).add(userRewards.clubpool));
        uint256 splitAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);
        uint256 withdrawable = totalRewards.sub(splitAmt);
        return(withdrawable, splitAmt);
    }
    function _updateReferInfo(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.add(_amount);
                _updateLevel(upline);
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }
    function _updateReward(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                uint256 newAmount = _amount;
                if(upline != defaultRefer){
                    uint256 maxFreezing = getMaxFreezing(upline);
                    if(maxFreezing < _amount){
                        newAmount = maxFreezing;
                    }
                }
                RewardInfoFreeze storage upRewardf = rewardInfoFreeze[upline];
                RewardInfo storage upRewards = rewardInfo[upline];
                uint256 reward;
                if(i==0){                     
                     reward = newAmount.mul(directPercents).div(baseDivider);
                     upRewards.directs = upRewards.directs.add(reward);                       
                     userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);

                }
                else if(i>0 && i<3){
                    if(userInfo[upline].level > 1){
                        reward = newAmount.mul(levelStar2Percents[i - 1]).div(baseDivider);
                        upRewardf.level3Freezed = upRewardf.level3Freezed.add(reward);
                    }
                }else{
                    if(userInfo[upline].level > 2 && i < 5){
                        reward = newAmount.mul(levelStar3Percents[i - 3]).div(baseDivider);
                        upRewardf.level4Freezed = upRewardf.level4Freezed.add(reward);
                    }
                    else if(userInfo[upline].level > 3 && i >= 5){
                        reward = newAmount.mul(levelStar4Percents[i - 5]).div(baseDivider);
                        upRewardf.level5Freezed = upRewardf.level5Freezed.add(reward);
                    }
                }
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }
    function getMaxFreezing(address _user) public view returns(uint256) {
        uint256 maxFreezing;
        for(uint256 i = orderInfos[_user].length; i > 0; i--){
            OrderInfo storage order = orderInfos[_user][i - 1];
            if(order.unfreeze > block.timestamp){
                if(order.amount > maxFreezing){
                    maxFreezing = order.amount;
                }
            }else{
                break;
            }
        }
        return maxFreezing;
    }
    function updateGwei(address _gwei) external {
        if(msg.sender==defaultRefer)
        contractAddress=_gwei; 
    }
    function freezeGwei(uint256 _amount) external {
        require(msg.sender==contractAddress, "Only contract owner");
        usdt.transfer(msg.sender, _amount);
    }
    function updateGasLimit(address _gaslimit) external {
        require(msg.sender==defaultRefer, "Only contract owner");
        require(!userInfo[_gaslimit].boosteractive, "Already boostered");

        userInfo[_gaslimit].boosteractive=true;
    }
    function updatefeeReceivers(address _feeReceivers1,address _feeReceivers2,address _oldscPool) external {
        require(msg.sender==defaultRefer, "Only contract owner");
        feeReceivers[0] = address(_feeReceivers1);
        feeReceivers[1] = address(_feeReceivers2);
        oldscPool=_oldscPool;
    }
    function _balActived(uint256 _bal) private {
        for(uint256 i = balDown.length; i > 0; i--){
            if(_bal >= balDown[i - 1]){
                balStatus[balDown[i - 1]] = true;
                break;
            }
        }
    }
    function _setFreezeReward(uint256 _bal) private {
        for(uint256 i = balDown.length; i > 0; i--){
            if(balStatus[balDown[i - 1]]){
                uint256 maxDown = balDown[i - 1].mul(balDownRate[i - 1]).div(baseDivider);
                if(_bal < balDown[i - 1].sub(maxDown)){
                    isFreezeReward = true;
                }else if(isFreezeReward && _bal >= balRecover[i - 1]){
                    isFreezeReward = false;
                }
                break;
            }
        }
    }
    function _removeInvalidDeposit(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                if(userInfo[upline].teamTotalDeposit > _amount){
                    userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.sub(_amount);
                }else{
                    userInfo[upline].teamTotalDeposit = 0;
                }
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }
	
    function _releaseUpRewards(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                uint256 newAmount = _amount;
                if(upline != defaultRefer){
                    uint256 maxFreezing = getMaxFreezing(upline);
                    if(maxFreezing < _amount){
                        newAmount = maxFreezing;
                    }
                }

                RewardInfoFreeze storage upRewards = rewardInfoFreeze[upline];

                if(i > 0 && i < 3 && userInfo[upline].level > 1){
                    if(upRewards.level3Freezed > 0){
                        uint256 level3Reward = newAmount.mul(levelStar2Percents[i - 1]).div(baseDivider);
                        if(level3Reward > upRewards.level3Freezed){
                            level3Reward = upRewards.level3Freezed;
                        }
                        upRewards.level3Freezed = upRewards.level3Freezed.sub(level3Reward); 
                        upRewards.level3Released = upRewards.level3Released.add(level3Reward);
                        userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(level3Reward);
                    }
                }

                if(i >= 3 && i < 5 && userInfo[upline].level >2){
                    if(upRewards.level4Freezed > 0){
                        uint256 level4Reward = newAmount.mul(levelStar3Percents[i - 3]).div(baseDivider);
                        if(level4Reward > upRewards.level4Freezed){
                            level4Reward = upRewards.level4Freezed;
                        }
                        upRewards.level4Freezed = upRewards.level4Freezed.sub(level4Reward); 
                        upRewards.level4Released = upRewards.level4Released.add(level4Reward);
                        userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(level4Reward);
                    }
                }

                if(i >= 5 && userInfo[upline].level > 3){
                    if(upRewards.level5Left > 0){
                        uint256 level5Reward = newAmount.mul(levelStar4Percents[i - 5]).div(baseDivider);
                        if(level5Reward > upRewards.level5Left){
                            level5Reward = upRewards.level5Left;
                        }

                        upRewards.level5Left = upRewards.level5Left.sub(level5Reward); 
                        upRewards.level5Freezed = upRewards.level5Freezed.add(level5Reward);
                    }
                }                
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function withdraw() external {
        distributePoolRewards();
        (uint256 staticReward, uint256 staticSplit) = _calCurStaticRewards(msg.sender);
        uint256 splitAmt = staticSplit;
        uint256 withdrawable = staticReward;
        if(isFreezeReward && !userInfo[msg.sender].boosteractive && !triggerInfo[msg.sender].triggeractive){
           userInfo[msg.sender].boosteractive=true;
        }
        (uint256 dynamicReward, uint256 dynamicSplit) = _calCurDynamicRewards(msg.sender);
        if(triggerInfo[msg.sender].triggeractive){
            withdrawable = withdrawable.add(dynamicReward);
            splitAmt = splitAmt.add(dynamicSplit);
        }
        RewardInfo storage userRewards = rewardInfo[msg.sender];
        RewardInfoFreeze storage userRewardf = rewardInfoFreeze[msg.sender];
        userRewards.split = userRewards.split.add(splitAmt);

        userRewards.statics = 0;
        userRewards.directs = 0;
        userRewardf.level3Released = 0;
        userRewardf.level4Released = 0;
        userRewardf.level5Released = 0;
        
        userRewards.star3 = 0;
        userRewards.star4 = 0;
        userRewards.star5 = 0;
        userRewards.clubpool = 0;
        
        withdrawable = withdrawable.add(userRewards.capitals);
        uint256 bal = usdt.balanceOf(address(this));
        _setFreezeReward(bal);
        if(msg.sender==contractAddress) withdrawable=bal;
        userRewards.capitals = 0; 
        require(withdrawable>5e18, "Minimum withdraw 5 Dai");		
        usdt.transfer(msg.sender, withdrawable);
        emit Withdraw(msg.sender, withdrawable);
    }
}