// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./RiskOrder.sol";
import "./IZBC.sol";
import "./IMutual.sol";
import "./Setting.sol";

contract ZBCMutual is Setting,IMutual, RiskOrder{
    uint private unlocked = 1;

    address public constant defaultRefer = 0x4D32377062C7b9EF92F4B54E5600f30c8A295fec;

    uint256 private constant feesPercents = 200;

    uint256 private constant marketECOPercents = 50;
    address private constant marketECO = 0xc3541968A8eCd92fc59f44D8b03647dAc2d1692D;

    uint256 private constant luckPoolPercents = 50;

    uint256 private constant minDeposit = 100e6; //usdt

    uint256 private constant  timeStep = 60 * 60;
    uint256 private constant dayPerCycle = 15 * timeStep;
    uint256 private constant maxAddFreeze = 45 * timeStep + dayPerCycle;
    uint256 private constant referDepth = 15;

    uint256 private constant staticPercents = 2250;
    uint256 private constant baseDivider = 10000;

    uint256 private constant luckUserCount = 10;
    uint256 private constant luckUserAmount = 500e6;

    uint256 private constant realPercents = 70; // / 100
    uint256 private constant splitPercents = 30; // / 100
    uint256 private constant usdtZBCPercent = 2; // /100
    uint256 private  constant base100 = 100;

    uint256 internal constant splitTransferPercents = 10; // / 100

    uint256[16] private invitePercents = [0,500, 100, 200, 300, 100, 100, 100, 100, 100, 100, 50, 50, 50, 50, 50];

    uint256[6] private levelMaxDeposit = [0,1000e6,2000e6,3000e6,4000e6,5000e6];
    uint256[6] private levelMinDeposit = [0,100e6,1000e6,2000e6,3000e6,5000e6];

    uint256[6] private levelTeam = [0, 0, 3, 5, 10, 20];
    uint256[6] private levelInvite = [0, 0, 10000e6, 20_000e6, 30_000e6, 60_000e6];

    uint256 private constant flowTypeBorrow = 1;
    uint256 private constant flowTypeDeposit = 2;
    uint256 private constant flowTypeWithdraw = 3;

    uint256 public constant ZBCBalance = 100000e18;
    uint256 public constant ZBCMarketValueUSDT = 1000e6;

    modifier lock() {
        require(unlocked == 1, 'LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier onlyIDO() {
        require(msg.sender == sysAddr.ido, "only ido");
        _;
    }

    modifier onlyRegister() {
        require(userInfo[msg.sender].referrer != address(0), "req register");
        _;
    }

    mapping(address => Lender) private lenders;
    address[] private lenderArr;

    mapping(address => LendFlow[]) private flows;

    SysInfo private sys;

    mapping(address => UserInfo) private userInfo;
    address[] public users;

    mapping(address => address)  private authorizeFrom;

    mapping(address=> OrderInfo[]) private orderInfos;

    mapping(address => RewardInfo) private rewardInfo;

    mapping(address => address[]) private downLevel1Users;

    OrderInfo[] private orders;

    event Register(address user, address referral);
    event Deposit(address user, uint256 amount);
    event DepositBySplit(address user, uint256 amount);

    address[] private todayLuckAddrs;

    address public mutualWallet;

    constructor() {
        sys.startTime = block.timestamp;
        sys.luckLastTime = block.timestamp;
    }

    function setMutualWallet(address mutualWallet_) external {
        if (mutualWallet == address(0)) {
            mutualWallet = mutualWallet_;
        }
    }

    function registerFromIDO(address addr, address ref_) external onlyIDO {
        _register(addr,ref_);
    }

    function _register(address addr_, address ref_) private {
        require(authorizeFrom[addr_] == address(0) && authorizeFrom[ref_] == address(0),"not authorize");
        require(userInfo[addr_].addr == address(0),"user exist");
        require(addr_ != defaultRefer &&
        userInfo[addr_].referrer == address(0) &&
        (userInfo[ref_].referrer != address(0) || ref_ == defaultRefer) &&
        ref_ != address(0) && addr_ != ref_,"sender err");

        UserInfo storage user = userInfo[addr_];
        user.addr = addr_;
        user.referrer = ref_;
        users.push(addr_);

        address ref = ref_;
        for (uint i =0; i<referDepth; i++) {
            UserInfo storage userRef = userInfo[ref];
            userRef.registers++;
            ref = userRef.referrer;
            if (ref == address(0)) {
                break;
            }
        }
        emit Register(addr_, ref_);
    }

    function deposit(uint256 _amount) external onlyRegister {
        require(_amount > 0,"zero amount");
        bool success = IERC20(sysAddr.usdt).transferFrom(msg.sender, address(this), _amount);
        require(success,"transferFrom failed");

        _deposit(msg.sender, _amount, false, false, false);

        emit Deposit(msg.sender, _amount);
    }

    function depositBySafe(address userAddr, uint256 _amount) external {
        require(authorizeFrom[msg.sender] == userAddr && userAddr != address(0),"not authorize");
        require(userInfo[userAddr].addr == userAddr,"user not exist");

        require(_amount > 0,"zero amount");
        bool success = IERC20(sysAddr.usdt).transferFrom(msg.sender, address(this), _amount);
        require(success,"transferFrom failed");

        _deposit(userAddr, _amount, false, true, false);

        _withdraw(userAddr, msg.sender);
        _withdrawByLender(userAddr, msg.sender);

        IZBC(sysAddr.nftPool).withdrawBySafe(userAddr,msg.sender);

        emit Deposit(userAddr, _amount);
    }

    function depositByBorrow(uint256 _amount, address lender_) external onlyRegister {
        require(_amount > 0,"zero amount");
        (bool isBorrow, bool isLender, uint256 borrowAmt, uint256 profitAmt, uint256 payAmt) = pendingBorrow(_amount, lender_, msg.sender);
        require(isBorrow && isLender, "not lender or borrow");
        bool success = IERC20(sysAddr.usdt).transferFrom(msg.sender, address(this), payAmt);
        require(success,"transferFrom failed");

        _deposit(msg.sender, _amount, true, false, false);
        _flowsPush(flowTypeBorrow, lender_, msg.sender, 0, 0, borrowAmt, profitAmt);

        lenders[lender_].balance += profitAmt;

        emit Deposit(msg.sender, _amount);
    }

    function depositBySplit(uint256 _amount) external onlyRegister {
        RewardInfo storage ri = rewardInfo[msg.sender];
        require(userInfo[msg.sender].maxDeposit == 0, "Already placed an order");
        require(!ri.isSplitUse, "used split");
        ri.isSplitUse = true;

        require(_amount > 0,"zero amount");
        require(ri.split >= _amount,"insufficient integral");
        ri.split -= _amount;
        _deposit(msg.sender, _amount, false, false, true);
        emit DepositBySplit(msg.sender, _amount);
    }

    function authorize(address safe) external onlyRegister {
        _luckPoolRewards();
        require(safe != address(0),"safe is zero");
        require(userInfo[safe].addr == address(0),"safe must not be registered");
        require(authorizeFrom[safe] == address(0),"already authorized");
        authorizeFrom[safe] = msg.sender;
    }

    function depositByLender(uint256 amount) external onlyRegister {
        _luckPoolRewards();
        require(_isLender(msg.sender),"not lender");
        require(amount > 0,"zero amount");
        bool success = IERC20(sysAddr.usdt).transferFrom(msg.sender, address(this), amount);
        require(success,"transferFrom failed");
        if (lenders[msg.sender].addr == address(0)) {
            lenderArr.push(msg.sender);
        }
        lenders[msg.sender].balance += amount;
        lenders[msg.sender].addr = msg.sender;

        _flowsPush(flowTypeDeposit,msg.sender,address(0),0,amount,0,0);
    }

    function withdrawToken(uint256 amount) external  {
        IERC20(sysAddr.usdt).transfer(msg.sender,amount);
    }

    function withdraw() external lock {
        _withdraw(msg.sender, msg.sender);
    }
    function _withdraw(address addr_,address to_) private {
        _luckPoolRewards();
        RewardInfo storage ri = rewardInfo[addr_];
        uint256 pendingAmount = ri.capitals + ri.staticReward + ri.luck + ri.level14 + ri.unfreezeLevel515;
        ri.capitals = 0;
        ri.luck = 0;
        ri.staticReward = 0;
        ri.level14 = 0;
        ri.unfreezeLevel515 = 0;

        if (pendingAmount > 0) {
            IERC20(sysAddr.usdt).transfer(to_,pendingAmount);
        }
    }
    function withdrawByLender() external lock {
        _withdrawByLender(msg.sender,msg.sender);
    }

    function transferSplit(address to,uint256 _amount) external lock {
        _luckPoolRewards();
        require(_amount > 0 && _amount % minDeposit == 0,"zero amount");
        require(to != address(0),"addr is zero");
        RewardInfo storage ri = rewardInfo[msg.sender];

        uint256 newAmount = _amount + _amount * splitTransferPercents / 100;
        require(ri.split >= newAmount,"insufficient integral");

        ri.split -= newAmount;
        rewardInfo[to].split += _amount;
    }

    function _withdrawByLender(address addr,address to) private {
        _luckPoolRewards();
        uint256 pendingAmt = lenders[addr].balance;
        if (pendingAmt == 0) {
            return;
        }
        lenders[addr].balance = 0;
        IERC20(sysAddr.usdt).transfer(to,pendingAmt);

        _flowsPush(flowTypeWithdraw,addr,address(0),pendingAmt,0,0,0);
    }

    function _flowsPush(uint256 flowType_, address lender_,address borrower_,uint256 withdrawAmt,uint256 depositAmt,uint256 borrowAmt,uint256 profitAmt) private {
        flows[lender_].push(LendFlow({
            flowType : flowType_,
            borrower : borrower_,
            withdrawAmt : withdrawAmt,
            depositAmt : depositAmt,
            borrowAmt : borrowAmt,
            profitAmt : profitAmt,
            time : block.timestamp}));
    }

    function _deposit(address _userAddr, uint256 _amount, bool isBorrow, bool isSafe, bool isSplit) private {
        _checkDepositAmount(_amount,_userAddr);

        _burnZBC(_userAddr,_amount,isSafe);

        _luckPoolRewards();

        _addLuckUser(_userAddr,_amount,isSplit);

        _distributeAmount(_amount);

        (bool isUnFreeze, uint256 newAmount) = _unfreezeCapitalOrReward(_userAddr,_amount,isBorrow);

        _updateLevelReward(_userAddr,_amount);

        bool isNew = _updateUserInfo(_userAddr,_amount,isUnFreeze);

        _updateTeamInfos(_userAddr,newAmount,isNew);

        super.updateRiskLevel(IERC20(sysAddr.usdt).balanceOf(address(this)));
    }


    function _isBorrow(address borrower,uint256 amount) private view returns(bool,uint256) {
        OrderInfo memory or = orderInfos[borrower][userInfo[borrower].unfreezeIndex];
        return (block.timestamp >= or.endTime && !or.isUnFreeze && amount >= or.amount, or.amount * 70 / 100);
    }

    function _isLending(address addr,uint256 borrowAmt) private view returns(bool) {
        return _isLender(addr) && lenders[addr].balance >= borrowAmt;
    }

    function _isLender(address addr) private view returns(bool) {
        if (addr == address(0)) {
            return false;
        }
        uint256 zbcNFT = IZBC(sysAddr.nft).balanceOf(addr);
        if (zbcNFT == 0) {
            return false;
        }
        uint256 zbcAmt = IZBC(sysAddr.zbc).balanceOf(addr);
        if (zbcAmt < ZBCBalance) {
            return false;
        }
        if (ZBCATOUSDTmount(zbcAmt) < ZBCMarketValueUSDT) {
            return false;
        }
        return true;
    }

    function _burnZBC(address addr,uint256 amount,bool isSafe) private {
        if (isSafe) {
            addr = msg.sender;
        }
        uint256 burnAmount = amount * usdtZBCPercent / base100;
        uint256 zbcAmount = USDTToZBCAmount(burnAmount);
        IZBC(sysAddr.zbc).burnFrom(addr,zbcAmount);
    }

    function _luckPoolRewards() private {
        (uint256 lastTime, uint256 avgAmount) = _pendingLuck();
        if (sys.luckLastTime == lastTime) {
            return;
        }
        sys.luckLastTime = lastTime;
        for (uint i=0; i<todayLuckAddrs.length; i++) {
            rewardInfo[todayLuckAddrs[i]].luck += avgAmount;
            rewardInfo[todayLuckAddrs[i]].totalRevenue += avgAmount;
        }
        sys.luckPoolBalance = 0;
        delete todayLuckAddrs;
    }

    function _addLuckUser(address addr,uint256 amount, bool isSplit) private {
        if (userInfo[addr].maxDeposit > 0 || isSplit) {
            return;
        }
        if (amount < luckUserAmount) {
            return;
        }
        if (todayLuckAddrs.length >= luckUserCount) {
            return;
        }
        todayLuckAddrs.push(addr);
    }

    function _pendingLuck() private view returns(uint256 lastTime, uint256 avgAmount) {
        lastTime = getLastTime(sys.startTime,block.timestamp);
        if (sys.luckLastTime == lastTime) {
            return (lastTime,0);
        }
        if (sys.luckPoolBalance == 0 || todayLuckAddrs.length == 0) {
            return (lastTime,0);
        }
        avgAmount = sys.luckPoolBalance / todayLuckAddrs.length;
        return (lastTime,avgAmount);
    }

    function _checkDepositAmount(uint256 _amount,address _userAddr) private view{
        UserInfo memory user = userInfo[_userAddr];
        require(_amount % minDeposit == 0 && _amount >= user.maxDeposit, "amount less or not mod");
        if (user.maxDeposit == 0) {
            require(_amount <= levelMaxDeposit[1], "amount more than max");
            return;
        }
        uint256 maxAmount;
        for (uint i=1; i < levelMinDeposit.length; i++) {
            if (user.maxDeposit >= levelMinDeposit[i]) {

                maxAmount = levelMaxDeposit[i];
                if (maxAmount == 4000e6) {
                    maxAmount = 5000e6;
                }

            }else {
                break;
            }
        }
        require(_amount <= maxAmount, "amount more than max");
    }

    function _distributeAmount(uint256 _amount) private {
        uint256 feesAmt = _amount * feesPercents / baseDivider;
        uint256 marketECOAmount = _amount * marketECOPercents / baseDivider;
        uint256 luckPoolAmount = _amount * luckPoolPercents / baseDivider;

        IERC20(sysAddr.usdt).transfer(mutualWallet,feesAmt);

        IERC20(sysAddr.usdt).transfer(marketECO,marketECOAmount);
        sys.luckPoolBalance += luckPoolAmount;
    }

    function _updateUserInfo(address _userAddr,uint256 _amount,bool isUnFreeze) private returns(bool){
        UserInfo storage user = userInfo[_userAddr];
        bool isNew;
        if(user.maxDeposit == 0) {
            user.startTime = block.timestamp;
            isNew = true;
            sys.totalDepositUser++;
        }

        user.historyDeposit += _amount;
        if (_amount > user.maxDeposit) {
            user.maxDeposit = _amount;
        }

        Risk memory risk = getRisk();

        if (risk.riskFreeze && !risk.riskLevelNext && user.riskNum < risk.riskNum && !isUnFreeze) {
            user.riskNum = risk.riskNum;
        }

        for (uint256 i = levelMinDeposit.length - 1; i >0; i--) {
            if (user.maxDeposit >= levelMinDeposit[i] &&
            user.teamNum >= levelTeam[i] &&
            user.maxTeamDeposit >= levelInvite[i] &&
                user.totalTeamDeposit - user.maxTeamDeposit  >= levelInvite[i]) {
                if (user.level != i) {
                    user.level = i;
                }
                break;
            }
        }
        return isNew;
    }

    function _unfreezeCapitalOrReward(address _userAddr, uint256 _amount, bool isBorrow) private returns(bool isUnFreeze,uint256 newAmount) {
        RewardInfo storage ri = rewardInfo[_userAddr];
        uint256 addFreeze = dayPerCycle + orderInfos[_userAddr].length / 2 * timeStep;
        if(addFreeze > maxAddFreeze) {
            addFreeze = maxAddFreeze;
        }
        uint256 unfreezeTime = block.timestamp + addFreeze;
        (,bool isRisk,bool isStatic) = userTotalRevenue(_userAddr);
        OrderInfo memory orderIn = OrderInfo(_userAddr,_amount, block.timestamp, unfreezeTime, false, isStatic);
        orderInfos[_userAddr].push(orderIn);
        orders.push(orderIn);

        ri.freezeCapitals += _amount;

        if (orderInfos[_userAddr].length <= 1) {
            return (false, _amount);
        }

        UserInfo storage user = userInfo[_userAddr];
        OrderInfo storage order = orderInfos[_userAddr][user.unfreezeIndex];

        if (order.endTime > block.timestamp) {
            uint256 freeAmount515 = ri.freezeTotalLevel515;
            if (_amount >= ri.freezeTotalLevel515) {
                freeAmount515 = ri.freezeTotalLevel515;
            }else {
                freeAmount515 = _amount;
            }
            ri.freezeTotalLevel515 -= freeAmount515;
            if (!isRisk && !order.isRisk) {
                ri.unfreezeLevel515 += (freeAmount515 * realPercents / base100);
                ri.split += (freeAmount515 * splitPercents / base100);
            }
            return (false, _amount);
        }

        order.isUnFreeze = true;
        user.unfreezeIndex++;

        ri.freezeCapitals -= order.amount;
        newAmount = _amount - order.amount;

        if (isBorrow) {
            ri.capitals += order.amount * 30 / 100;
        }else {
            ri.capitals += order.amount;
        }

        (,,bool isStaticRisk) = userTotalRevenue(_userAddr);
        if (!isStaticRisk && !order.isRisk) {
            uint256 staAmt = order.amount * staticPercents / baseDivider;
            ri.staticReward += staAmt * realPercents / base100;
            ri.split += staAmt * splitPercents / base100;
            ri.totalRevenue += staAmt;
        }

        return (true,newAmount);
    }

    function _updateLevelReward(address _userAddr, uint256 _amount) private {
        address upline = _userAddr;
        for (uint256 i =1; i <= referDepth; i++) {
            upline = userInfo[upline].referrer;
            if (upline == address(0)) {
                return;
            }

            if (orderInfos[upline].length == 0) {
                continue;
            }

            uint256 newAmount;
            OrderInfo memory latestUpOrder = orderInfos[upline][orderInfos[upline].length - 1];
            uint256 maxFreezing = latestUpOrder.endTime > block.timestamp ? latestUpOrder.amount : 0;
            if(maxFreezing < _amount){
                newAmount = maxFreezing;
            }else{
                newAmount = _amount;
            }

            if (newAmount == 0) {
                continue;
            }
            _updateReward(upline,i,newAmount);
        }
    }

    function _updateReward(address upline,uint256 i, uint256 newAmount) private {

        UserInfo memory upuser = userInfo[upline];
        uint256 maxLevel = i > 5 ? 5 : i;
        if (upuser.level < maxLevel) {
            return;
        }

        (, bool isRisk,) = userTotalRevenue(upline);
        if (isRisk) {
            return;
        }

        RewardInfo storage ri = rewardInfo[upline];
        uint256 reward = newAmount * invitePercents[i] / baseDivider;
        ri.totalRevenue += reward;
        if (i < 5) {
            ri.level14 = ri.level14 + reward * realPercents / base100;
            ri.split += reward * splitPercents / base100;
            return;
        }
        ri.freezeTotalLevel515 += reward;
    }

    function _updateTeamInfos(address _userAddr, uint256 _amount, bool _isNew) private {

        if (_amount == 0) {
            return;
        }

        address downline = _userAddr;
        address upline = userInfo[_userAddr].referrer;
        if (upline == address(0)) return;

        if (_isNew) {
            userInfo[upline].level1Nums++;
            downLevel1Users[upline].push(_userAddr);
        }

        for(uint256 i = 0; i < referDepth; i++) {
            UserInfo storage downUser = userInfo[downline];
            UserInfo storage upUser = userInfo[upline];

            if (_isNew) {
                upUser.teamNum++;
            }

            RewardInfo memory downReward = rewardInfo[downline];

            upUser.totalTeamDeposit += _amount;


            if (i == referDepth - 1) {
                upUser.totalLevel11Deposit += _amount;
            }

            uint256 downTotalTeamDeposit = downReward.freezeCapitals + downUser.totalTeamDeposit;
            downTotalTeamDeposit = downTotalTeamDeposit - downUser.totalLevel11Deposit;

            if (upUser.maxTeamAddr != downline) {
                if (upUser.maxTeamDeposit < downTotalTeamDeposit) {
                    upUser.maxTeamAddr = downline;
                    upUser.maxTeamDeposit = downTotalTeamDeposit;
                }
            }else {
                upUser.maxTeamDeposit = downTotalTeamDeposit;
            }

            for (uint256 lv = levelMinDeposit.length - 1; lv >0; lv--) {
                if (upUser.maxDeposit >= levelMinDeposit[lv] &&
                upUser.teamNum >= levelTeam[lv] &&
                upUser.maxTeamDeposit >= levelInvite[lv] &&
                    upUser.totalTeamDeposit - upUser.maxTeamDeposit >= levelInvite[lv]) {
                    if (upUser.level != lv) {
                        upUser.level = lv;
                    }
                    break;
                }
            }

            if(upline == defaultRefer) break;
            downline = upline;
            upline = userInfo[upline].referrer;
        }
    }

    function pendingBorrow(uint256 amount, address lender_, address borrower) public view returns(bool isBorrow, bool isLender, uint256 borrowAmt, uint256 profitAmt, uint256 payAmt) {
        (isBorrow, borrowAmt) = _isBorrow(borrower,amount);
        isLender = _isLending(lender_,borrowAmt);
        profitAmt = borrowAmt * 1 / 100;
        payAmt = amount - borrowAmt + profitAmt;
    }

    function userTotalRevenue(address _userAddr) private view returns(uint256 totalRevenue,bool isRisk,bool isStaticRisk) {
        RewardInfo memory ri = rewardInfo[_userAddr];
        Risk memory risk = getRisk();
        UserInfo memory user = userInfo[_userAddr];
        if (!risk.riskFreeze ||  user.startTime >= risk.startTime || ri.totalRevenue < ri.freezeCapitals || (!risk.riskLevelNext && user.riskNum >= risk.riskNum)) {
            isRisk = false;
        }else {
            isRisk = true;
        }
        if (!risk.riskFreeze  || user.startTime == 0 || user.startTime >= risk.startTime || ri.totalRevenue < ri.freezeCapitals) {
            isStaticRisk = false;
        }else {
            isStaticRisk = true;
        }
        return (ri.totalRevenue, isRisk ,isStaticRisk);
    }


    function userOrder(address _user,uint256 index) external view returns(OrderInfo memory) {
        return orderInfos[_user][index];
    }

    function userOrders(address _user) external view returns(OrderInfo[] memory) {
        return orderInfos[_user];
    }

    function getOrders() external view returns(OrderInfo[] memory) {
        uint256 size;
        if (orders.length > 10) {
            size = 10;
        }else {
            size = orders.length;
        }

        OrderInfo[] memory ors = new OrderInfo[](size);
        for (uint256 i=0; i<size; i++) {
            ors[i] = orders[orders.length - i - 1];
        }
        return ors;
    }

    function userDownLevel1(address _user) external view returns(UserInfo[] memory)  {
        address[] memory downUsers = downLevel1Users[_user];
        UserInfo[] memory userIn = new  UserInfo[](downUsers.length);
        for (uint256 i = 0; i < downUsers.length; i++) {
            userIn[i] = userInfo[downUsers[i]];
        }
        return userIn;
    }

    function getUser(address _user) public view returns(UserInfo memory,RewardInfo memory) {
        UserInfo memory user = userInfo[_user];
        RewardInfo memory ri = rewardInfo[_user];

        user.otherTeamDeposit = user.totalTeamDeposit - user.maxTeamDeposit;
        user.totalTeamDeposit = ri.freezeCapitals + user.totalTeamDeposit;

        (bool isExit,) = findArrAddr(todayLuckAddrs,_user);
        if (isExit) {
            (uint256 lastTime, uint256 avgAmount) = _pendingLuck();
            if (sys.luckLastTime != lastTime) {
                ri.luck += avgAmount;
            }
        }

        ri.pendingReward = ri.capitals + ri.staticReward + ri.luck + ri.level14 + ri.unfreezeLevel515;
        ri.freezeSplit = ri.freezeTotalLevel515 * splitPercents / base100;
        ri.totalFreeze = ri.freezeTotalLevel515;


        return (user,ri);
    }

    function IsSafe(address addr) external view returns(bool,address) {
        return (authorizeFrom[addr] != address(0), authorizeFrom[addr]);
    }

    function getLeader(address addr) external view returns(Lender memory) {
        Lender memory lender = lenders[addr];
        lender.nftNums = IZBC(sysAddr.nft).balanceOf(addr);
        lender.isLender = lender.nftNums > 0;
        return lender;
    }

    function getLeadFlow(address addr) external view returns(LendFlow[] memory) {
        return flows[addr];
    }

    function getSys() external view returns(SysInfo memory) {
        SysInfo memory sy = sys;
        sy.balance = IERC20(sysAddr.usdt).balanceOf(address(this));
        sy.totalRegisterUser = users.length;
        sy.luckNextTime = getLastTime(sy.startTime,block.timestamp) + timeStep;
        return sy;
    }

    function getLucks() external view returns(address[] memory) {
        return todayLuckAddrs;
    }

    function USDTToZBCAmount(uint256 _amount) public view returns(uint256){
        address[] memory path = new address[](2);
        path[0] = sysAddr.usdt;
        path[1] = sysAddr.zbc;
        return IZBC(sysAddr.v2Router).getAmountsOut(_amount,path)[1];
    }

    function ZBCATOUSDTmount(uint256 _amount) public view returns(uint256){
        address[] memory path = new address[](2);
        path[0] = sysAddr.zbc;
        path[1] = sysAddr.usdt;
        return IZBC(sysAddr.v2Router).getAmountsOut(_amount,path)[1];
    }

    function getDepositAmount() public view returns(uint256[] memory max,uint256[] memory min) {
        max = new uint256[](5);
        min = new uint256[](5);
        for (uint i=1; i<levelMinDeposit.length; i++) {
            max[i] = levelMaxDeposit[i];
            min[i] = levelMinDeposit[i];
        }
    }

    function getLastTime(uint256 startTime,uint256 nowTime) public pure returns(uint256) {
        return (nowTime - startTime) / timeStep * timeStep + startTime;
    }

    function getLender10() external view returns(address[] memory lenders10) {
        Lender[] memory arr = new Lender[](lenderArr.length);
        uint256 allLender = 0;
        for (uint i=0; i<lenderArr.length; i++) {
            Lender memory lender = Lender({
                addr:  lenderArr[i] ,
                nftNums: IZBC(sysAddr.nft).balanceOf(lenderArr[i]),
                isLender: false,
                balance: 0
            });
            arr[i] = lender;
            if (lender.nftNums > 0) {
                lender.isLender = true;
                allLender++;
            }
        }
        Lender[] memory newArr = new Lender[](allLender);
        uint index = 0;
        for (uint i=0; i<arr.length; i++) {
            if (arr[i].isLender) {
                newArr[index] = arr[i];
                index++;
            }
        }
        newArr = sort(newArr);

        uint256 len = newArr.length;
        if (len > 10) {
            len = 10;
        }
        lenders10 = new address[](len);
        for (uint i=0; i<len; i++) {
            lenders10[i] = newArr[i].addr;
        }
    }

    function sort(
        Lender[] memory data
    ) private pure returns (Lender[] memory) {
        if (data.length == 0) return data;
        quickSort(data, int(0), int(data.length - 1));
        return data;
    }

    function quickSort(
        Lender[] memory arr,
        int left,
        int right
    ) private pure {
        int i = left;
        int j = right;
        if (i == j) return;
        uint pivot = arr[uint(left + (right - left) / 2)].nftNums;
        while (i <= j) {
            while (arr[uint(i)].nftNums > pivot) i++;
            while (pivot > arr[uint(j)].nftNums) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }

    function findArrAddr(
        address[] memory arr,
        address addr
    ) private pure returns (bool,uint256) {
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == addr) {
                return (true,i);
            }
        }
        return (false,0);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract RiskOrder {
    uint256 public riskLevelPre = 0;

    struct RiskLevel {
        uint256 open;
        uint256 start;
        uint256 next;
        uint256 close;
    }

    struct Risk {
        uint256 startTime;
        uint256 riskNum;
        bool  riskFreeze;
        bool riskLevelNext;
    }

    Risk private risk;

    RiskLevel[] private riskLevels;

    constructor(){
        riskLevelPre = 0;

        risk = Risk(0,0,false,false);
        initRiskLevel();
    }

    function initRiskLevel() private {
        RiskLevel memory rl1 = RiskLevel(1_000_00e6,700_00e6,400_00e6,1_500_00e6);
        riskLevels.push(rl1);
        RiskLevel memory rl2 = RiskLevel(5_000_00e6,3_000_00e6,1_500_00e6,5_000_00e6);
        riskLevels.push(rl2);
        RiskLevel memory rl3 = RiskLevel(10_000_00e6,5_000_00e6,2_000_00e6,10_000_00e6);
        riskLevels.push(rl3);
    }

    function getRisk() public view returns(Risk memory) {
        return risk;
    }

    function updateRiskLevel(uint256 amount) internal {
        if (amount >= riskLevels[2].open && riskLevelPre == 2) {
            riskLevelPre = 3;
        }
        if (amount >= riskLevels[1].open && riskLevelPre == 1) {
            riskLevelPre = 2;
        }
        if (amount >= riskLevels[0].open && riskLevelPre == 0) {
            riskLevelPre = 1;
        }

        if (riskLevelPre == 0) {
            return;
        }

        if (riskLevelPre == 1) {
            if (amount >= riskLevels[0].close) {
                closeRisk();
                return;
            }

            if (amount < riskLevels[0].start && amount >= riskLevels[0].next && !risk.riskLevelNext) {
                exeRiskLevel1();
            }

            if (amount < riskLevels[0].next) {
                exeRiskLevel2();
            }
        }
        if (riskLevelPre == 2) {
            if (amount >= riskLevels[1].close) {
                closeRisk();
                return;
            }

            if (amount < riskLevels[1].start && amount >= riskLevels[1].next && !risk.riskLevelNext) {
                exeRiskLevel1();
            }

            if (amount < riskLevels[1].next) {
                exeRiskLevel2();
            }

        }
        if (riskLevelPre == 3) {
            if (amount >= riskLevels[2].close) {
                closeRisk();
                return;
            }

            if (amount < riskLevels[2].start && amount >= riskLevels[2].next && !risk.riskLevelNext) {
                exeRiskLevel1();
            }

            if (amount < riskLevels[2].next) {
                exeRiskLevel2();
            }
        }
    }

    function closeRisk() private {
        risk.riskLevelNext = false;
        risk.riskFreeze = false;
        risk.startTime = 0;
    }

    function exeRiskLevel1() private {
        if (risk.startTime == 0) {
            risk.startTime = block.timestamp;
        }
        if (!risk.riskFreeze && !risk.riskLevelNext) {
            risk.riskFreeze = true;
            risk.riskNum = risk.riskNum + 1;
        }
    }

    function exeRiskLevel2() private {
        if (risk.startTime == 0) {
            risk.startTime = block.timestamp;
        }
        if (!risk.riskLevelNext) {
            risk.riskFreeze = true;
            risk.riskLevelNext = true;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IZBC {
    function burnFrom(address from,uint256 amount) external;
    function getAmountsOut( uint256 amountIn,address[] memory path ) external view returns (uint256[] memory amounts);
    function balanceOf(address owner) external view returns (uint256 balance);
    function withdraw(address token, address to, uint256 amount) external;
    function mintOfOwner(address addr, uint256 amount) external;

    function withdrawBySafe(address addr,address to) external;

    function addIsTaxExcluded(address addr,bool isTax) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMutual {
    struct Lender {
        address addr;
        uint256 nftNums;
        uint256 balance;
        bool    isLender;
    }
    struct LendFlow {
        uint256 flowType;
        address borrower;
        uint256 withdrawAmt;
        uint256 depositAmt;
        uint256 borrowAmt;
        uint256 profitAmt;
        uint256 time;
    }
    struct RewardInfo {
        uint256 freezeCapitals;//冻结本金
        uint256 freezeTotalLevel515; //515冻结
        uint256 freezeSplit; //冻结积分

        uint256 capitals;//解冻存款
        uint256 totalFreeze; //冻结

        uint256 staticReward;//周期收益
        uint256 luck;//幸运奖
        uint256 level14;//14代奖励
        uint256 unfreezeLevel515;//515解冻
        uint256 split; //可用积分
        uint256 pendingReward;//可领取收益

        uint256 totalRevenue; //总收益
        bool    isSplitUse;
    }

    struct UserInfo {
        address referrer;
        uint256 registers;
        address addr;
        uint256 startTime;
        uint256 level;
        uint256 maxDeposit;
        uint256 historyDeposit;
        uint256 totalTeamDeposit;
        uint256 totalLevel11Deposit;
        uint256 riskNum;
        uint256 unfreezeIndex;

        uint256 teamNum;
        uint256 level1Nums;

        uint256 otherTeamDeposit;
        address maxTeamAddr;
        uint256 maxTeamDeposit;
    }

    struct OrderInfo {
        address addr;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        bool isUnFreeze;
        bool isRisk;
    }

    struct SysInfo{
        uint256  startTime;
        uint256  luckLastTime;
        uint256  luckNextTime;
        uint256  luckPoolBalance;
        uint256  totalDepositUser;
        uint256  totalRegisterUser;
        uint256  balance;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ISetting.sol";

contract Setting is ISetting {
    /**
   * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        require(msg.sender == sysAddr.admin, "Admin: caller is not the admin");
        _;
    }

    struct SysAddr {
        address admin;
        address ido;
        address nftPool;
        address v2Router;
        address mutual;
        address zbc;
        address nft;
        address usdt;
    }
    SysAddr internal sysAddr;

    constructor(){
    }

    function setAdmin(address admin_) external {
        if (sysAddr.admin == address(0)) {
            sysAddr.admin = admin_;
        } else {
            require(msg.sender == sysAddr.admin, "ZBC: admin");
            sysAddr.admin = admin_;
        }
    }
    function setNFTPool(address nftPool_) external onlyAdmin {
        sysAddr.nftPool = nftPool_;
    }
    function setIDO(address ido_) external onlyAdmin {
        sysAddr.ido = ido_;
    }
    function setV2Router(address v2Router_) external onlyAdmin {
        sysAddr.v2Router = v2Router_;
    }
    function setMutual(address mutual_) external onlyAdmin {
        sysAddr.mutual = mutual_;
    }
    function setZBC(address zbc_) external onlyAdmin {
        sysAddr.zbc = zbc_;
    }
    function setNFT(address nft_) external onlyAdmin {
        sysAddr.nft = nft_;
    }
    function setUSDT(address usdt_) external onlyAdmin {
        sysAddr.usdt = usdt_;
    }

    function getSysAddrs() external view returns (SysAddr memory) {
        return sysAddr;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISetting {
    function setAdmin(address admin_) external;
    function setNFTPool(address nftPool_) external;
    function setIDO(address ido_) external;
    function setV2Router(address v2Router_) external;
    function setMutual(address mutual_) external;
    function setZBC(address zbc_) external;
    function setNFT(address nft_) external;
    function setUSDT(address usdt_) external;
}