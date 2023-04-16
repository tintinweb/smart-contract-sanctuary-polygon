/**
 *Submitted for verification at BscScan.com on 2022-11-30
 */

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}

interface IIPFSDeployer {
    function deploy(
        address payable owner,
        address payable dev,
        address payable marketing,
        address payable mainContract
    ) external;

    function isWhitelisted(address _user) external view returns (bool);
}

interface IInsuranceContract {
    function initiate() external;

    function getBalance() external view returns (uint256);

    function getMainContract() external view returns (address);
}

contract INSURANCE {
    IERC20 public tokenAddress =
        IERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);

    //accept funds from MainContract
    receive() external payable {}

    address payable public MAINCONTRACT;

    constructor() {
        MAINCONTRACT = payable(msg.sender);
    }

    function initiate() public {
        require(msg.sender == MAINCONTRACT, "Forbidden");
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        if (balance == 0) return;
        IERC20(tokenAddress).transfer(MAINCONTRACT, balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMainContract() public view returns (address) {
        return MAINCONTRACT;
    }
}

struct DepositStruct {
    uint256 amount;
    uint40 time;
    uint256 withdrawn;
}

struct WithdrawDetails {
    uint256 timestamp;
    uint256 amount;
}

struct LatestDeposits{
    uint256 amount;
    uint256 time;
    address user;
}

struct Investor {
    uint256 lastInvestedAmount;
    address daddy;
    uint40 lastPayout;
    uint256 totalInvested;
    uint256 totalReferralInvested;
    uint256 totalWithdrawn;
    uint256 totalBonus;
    DepositStruct[] deposits;
    mapping(uint256 => uint256) referralEarningsL;
    uint256[5] structure;
    uint256 totalRewards;
    uint256 withdrawalTime;
    uint256 time;
    uint256 unsettled;
    bool isExist;
    uint256 lastDepositeTime;
}

struct UserTeams{
    uint256 totalBusiness;
    uint256 totalTeam;
}

struct userEarning{
    uint256 dividendIncome;
    uint256 royaltyIncome;
    uint256 royaltyIncome1;
    uint256 pensionIncome;
    uint256 joinedTime;
    uint256 pensionIncomeAvailable;
}

contract IPFSUNO {
    using SafeMath for uint256;
    using SafeMath for uint40;

    IERC20 public tokenAddress =
        IERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    address roiDeployerAddress;
    LatestDeposits[] public _latestDeposits;

    uint256 public contractInvested;
    uint256 public contractWithdrawn;
    uint256 public matchBonus;
    uint256 public totalUsers;

    uint8 constant BonusLinesCount = 5;
    uint16 constant percentDivider = 100;
    uint16 constant percentDividerROI = 10000;
    uint256 public maxWithdrawl = 100 ether;
    uint256 MAX_EARNING = 50100 ether;

    uint256 referralBonus = 0;

    uint256 public MAX_LIMIT = 200;
    uint40 public TIME_STEP = 86400;
    uint8 public Daily_ROI_Per = 100;

    uint256 MinimumDiposit = 5 * 1e18;
    uint256 MaximumDiposit = 100 * 1e18;
    uint256 CreatorsPercentage = 4;
    uint256 referralBonusPer = 40;
    uint256 public royaltyFunds = 0;
    uint256 public royaltyFundsLevel2 = 0;
    uint256 public pensionFunds;

    uint256[BonusLinesCount] RefferalPer = [35, 1, 2, 3, 4];

    mapping(address => Investor) public investorsMap;
    mapping(address=>userEarning) public earningUsers;
    mapping(address=>UserTeams) public userTeams;
    mapping(address => WithdrawDetails) public withdrawDetails;
    mapping(address => bool) public idDeactivated;
    address[] public royaltyUsers;

    address payable public owner;
    address payable public dev;
    address payable public marketing;

    address payable public INSURANCE_CONTRACT;
    mapping(uint256 => uint256) public INSURANCE_MAXBALANCE;
    uint256 public constant INSURANCE_PERCENT = 2; 
    uint256 public constant INSURANCE_LOWBALANCE_PERCENT = 2; // protection kicks in at 2% or lower
    uint256 public INSURANCE_TRIGGER_BALANCE;
    bool public isInsuranceTriggered;

    struct UserStruct {
        uint256 activeLevel;
        uint256 planbactivatedround;
    }
    struct userInfo {
        uint256 id;
        uint256 referrerID;
        uint256 childCount;
        address userAddress;
        uint256 noofpayments;
        uint256 activeLevel;
    }

    struct BonusLevels {
        uint40 level;
        uint256 index;
        bool isAdded;
    }
    mapping(address => UserStruct) public dividendUsers;
    mapping(address => bool) public isWhitelisted;
    mapping(uint256 => mapping(uint256 => userInfo)) public userInfos;
    mapping(address => mapping(uint256 => uint256)) public noofPayments;
    mapping(address => BonusLevels) public bonusLevels;
    uint256 public currUserID = 0;
    mapping(uint256 => mapping(uint256 => address payable))
        public userAddressByID;
    // mapping(uint256 => mapping(uint256 => uint256)) public walletAmountPlanB;

    mapping(uint256 => uint256) public lastIDCount;
    mapping(uint256 => uint256) public lastFreeParent;
    mapping(uint256 => uint256) public LEVEL_PRICE;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount);
    event MatchPayout(
        address indexed addr,
        address indexed from,
        uint256 amount
    );
    event Withdraw(address indexed addr, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);

    event regLevelEvent(
        address indexed _user,
        address indexed _referrer,
        uint256 _time
    );

    event buyLevelEvent(
        address indexed _user,
        uint256 _level,
        uint256 _time,
        uint256 _amount,
        uint256 _roundid
    );
    event binaryData(
        address indexed _user,
        uint256 _userId,
        uint256 _referralID,
        uint256 _level,
        address referralAddress,
        uint256 _roundid
    );

    constructor(address payable CreatorAddr, address payable DevAddr,address payable MarketingAddr) {
        INSURANCE_CONTRACT = payable(new INSURANCE());
        owner = CreatorAddr;
        dev = DevAddr;
        marketing = MarketingAddr;
        LEVEL_PRICE[1] = 1 ether;
        LEVEL_PRICE[2] = 2 ether;
        investorsMap[owner].isExist = true;
        investorsMap[owner].daddy = owner;
    }

    function setRoiDeployerAddress(address _restart) external {
        require(msg.sender == dev, "invalid to set restart");
        roiDeployerAddress = _restart;
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = investorsMap[_addr].daddy;
        uint256 i = 0;

        uint256 bonus = 0;
        for (i = 0; i < BonusLinesCount; i++) {
            if (up == address(0)) break;

            userTeams[up].totalBusiness+=_amount;
            
            bool flag = false;
            uint256 _sendAmount = investorsMap[up].totalInvested > _amount
                ? _amount
                : investorsMap[up].totalInvested;
            bonus = (_sendAmount * RefferalPer[i]) / percentDivider;

            if (i == 0) {
                flag = true;
            } else if (
                (i == 1 || i == 2) &&
                investorsMap[up].structure[0] >= 5 &&
                investorsMap[up].totalReferralInvested >= 500 * 1e18
            ) {
                flag = true;
            } else if (
                (i == 3 || i == 4) &&
                investorsMap[up].structure[0] >= 10 &&
                investorsMap[up].totalReferralInvested >= 1000 * 1e18
            ) {
                flag = true;
            }

            if (flag) {
                
                    investorsMap[up].referralEarningsL[i] = investorsMap[up]
                        .referralEarningsL[i]
                        .add(bonus);
                    investorsMap[up].totalBonus += bonus;
                    matchBonus += bonus;
                    emit MatchPayout(up, _addr, bonus);
                

                if (
                    investorsMap[up].structure[0]>5 &&
                    userTeams[up].totalTeam >= 50 &&
                    userTeams[up].totalBusiness >= 5000 ether &&
                    bonusLevels[up].level == 0
                ) {
                    //50
                    if (!bonusLevels[up].isAdded) {
                        royaltyUsers.push(up);
                        bonusLevels[up].isAdded = true;
                    }
                    bonusLevels[up].level = 1;
                }
                if (
                    investorsMap[up].structure[0]>10 &&
                    userTeams[up].totalTeam >= 100 &&
                    userTeams[up].totalBusiness >= 10000 ether &&
                    bonusLevels[up].level < 2
                ) {
                    //100
                    if (!bonusLevels[up].isAdded) {
                        royaltyUsers.push(up);
                        bonusLevels[up].isAdded = true;
                    }
                    bonusLevels[up].level = 2;
                }
            }

            up = investorsMap[up].daddy;
        }
    }

    function _setUpdaddy(address _addr, address _upline) private {
        if (
            investorsMap[_addr].daddy == address(0) &&
            investorsMap[_upline].isExist &&
            _addr != _upline  && _upline!=address(0)
        ) {
            investorsMap[_addr].daddy = _upline;
            emit regLevelEvent(_addr,_upline,block.timestamp);

            for (uint256 i = 0; i < BonusLinesCount; i++) {
                investorsMap[_upline].structure[i]++;
                userTeams[_upline].totalTeam++;
                _upline = investorsMap[_upline].daddy;

                if (_upline == address(0)) break;
            }
        }
    }

    function deposit(uint256 _amount, address _upline) public payable {
        uint256 amount = _amount;
        require(!idDeactivated[msg.sender], "Id Deactivated");
        require(!isInsuranceTriggered, "Insurance payment started");
        collect(msg.sender);
        Investor storage investor = investorsMap[msg.sender];
        if (investorsMap[msg.sender].deposits.length == 0) {
            require(
                amount >= MinimumDiposit && amount <= MaximumDiposit,
                "You can deposite min 5$ or max 100$"
            );
            earningUsers[msg.sender].joinedTime = block.timestamp;
        } else  {
            require(amount >= 1 ether, "Deposite must be greater than 1$");
            require(investor.totalWithdrawn>=investor.totalInvested.div(2),"Need to wait");
        }

        require(investor.deposits.length < 100, "Max 100 deposits per address");

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);

        if (_upline == address(0) || !investorsMap[_upline].isExist) {
            _upline = owner;
        }

        uint256 cfee = amount.mul(CreatorsPercentage).div(percentDivider).div(
            2
        );
        IERC20(tokenAddress).transfer(marketing, cfee);
        IERC20(tokenAddress).transfer(dev, cfee);

        _setUpdaddy(msg.sender, _upline);
        investor.isExist = true;
        investor.deposits.push(
            DepositStruct({
                amount: amount,
                time: uint40(block.timestamp),
                withdrawn: 0
            })
        );
        _latestDeposits.push(LatestDeposits({amount:amount,time:block.timestamp,user:msg.sender}));

        investor.lastInvestedAmount = amount;
        if (investor.deposits.length == 1) {
            totalUsers++;
        }

        investor.totalInvested += amount;
        investorsMap[investorsMap[msg.sender].daddy]
            .totalReferralInvested += amount;
        investorsMap[msg.sender].time = block.timestamp;
        contractInvested += amount;
        royaltyFunds = royaltyFunds.add(_amount.mul(50).div(10000));
        royaltyFundsLevel2 = royaltyFundsLevel2.add(_amount.mul(25).div(10000));
        pensionFunds = pensionFunds.add(_amount.mul(25).div(10000));

        _refPayout(msg.sender, amount);
        if (investor.deposits.length == 1) {
            regUserPlanB(payable(msg.sender));
        }
        investor.lastDepositeTime = block.timestamp;
        uint256 insuranceAmount = (amount * INSURANCE_PERCENT) / percentDivider;
        IERC20(tokenAddress).transfer(INSURANCE_CONTRACT, insuranceAmount);
        distributePool();
        emit NewDeposit(msg.sender, amount);
    }

    function _insuranceTrigger() internal {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));

        INSURANCE_TRIGGER_BALANCE =
            (contractInvested * INSURANCE_LOWBALANCE_PERCENT) /
            percentDivider;

        //low balance - initiate Insurance
        if (balance < INSURANCE_TRIGGER_BALANCE && !isInsuranceTriggered) {
            isInsuranceTriggered = true;
            IInsuranceContract(INSURANCE_CONTRACT).initiate();
        }
    }

    function regUserPlanB(address payable userAddress) internal {
        dividendUsers[userAddress].planbactivatedround++;
        uint256 _roundid = dividendUsers[userAddress].planbactivatedround;
        if (lastFreeParent[_roundid] == 0) {
            UserStruct memory userStruct;

            userStruct = UserStruct({
                activeLevel: 1,
                planbactivatedround: _roundid
            });

            dividendUsers[owner] = userStruct;

            userInfo memory UserInfoowner;

            UserInfoowner = userInfo({
                id: 1,
                referrerID: 0,
                childCount: 0,
                userAddress: owner,
                noofpayments: 0,
                activeLevel: 8
            });

            userInfos[_roundid][1] = UserInfoowner;
            lastIDCount[_roundid] = 1;
            lastFreeParent[_roundid] = 1;
            userAddressByID[_roundid][1] = owner;
        }

        if (userInfos[_roundid][lastFreeParent[_roundid]].childCount >= 2)
            lastFreeParent[_roundid]++;

        userInfo memory UserInfo;
        lastIDCount[_roundid]++;

        UserInfo = userInfo({
            id: lastIDCount[_roundid],
            referrerID: lastFreeParent[_roundid],
            childCount: 0,
            userAddress: userAddress,
            noofpayments: 0,
            activeLevel: 1
        });

        userInfos[_roundid][lastIDCount[_roundid]] = UserInfo;
        userInfos[_roundid][lastFreeParent[_roundid]].childCount++;
        userAddressByID[_roundid][lastIDCount[_roundid]] = userAddress;
        dividendUsers[userAddress].activeLevel = 1;

        emit buyLevelEvent(
            userAddress,
            1,
            block.timestamp,
            LEVEL_PRICE[1],
            _roundid
        );
        emit binaryData(
            userAddress,
            lastIDCount[_roundid],
            lastFreeParent[_roundid],
            6,
            userAddressByID[_roundid][lastFreeParent[_roundid]],
            _roundid
        );
        distributeBonus(lastIDCount[_roundid], 1, _roundid);
    }

    function distributeBonus(
        uint256 _addr,
        uint256 _level,
        uint256 _roundid
    ) internal {
        uint256 up = userInfos[_roundid][_addr].referrerID;
        uint256 amt = LEVEL_PRICE[_level];

        for (uint256 i = 0; i < _level - 1; i++) {
            if (up == 0) break;
            up = userInfos[_roundid][up].referrerID;
        }
        if (up < 2) {
            investorsMap[owner].totalBonus += amt;
            earningUsers[owner].dividendIncome +=amt;
        } else {
            address payable receiver = userAddressByID[_roundid][up];
            noofPayments[receiver][_level]++;

            if (_level == 1 && noofPayments[receiver][_level] == 2) {
                distributeBonus(up, 2, _roundid);
                // _buyLevel(2, up, _roundid);
                emit buyLevelEvent(
                    receiver,
                    _level,
                    block.timestamp,
                    LEVEL_PRICE[_level],
                    _roundid
                );
            }
            if (_level == 2 && noofPayments[receiver][_level] == 4) {
                investorsMap[receiver].totalBonus += LEVEL_PRICE[2].div(2);
                earningUsers[receiver].dividendIncome +=LEVEL_PRICE[2].div(2);
                noofPayments[receiver][1] = 0;
                noofPayments[receiver][2] = 0;
                regUserPlanB(receiver);
            } else if (_level == 2) {
                investorsMap[receiver].totalBonus += amt;
                earningUsers[receiver].dividendIncome += amt;
            }
        }
    }


    function withdraw() external {
        require(!idDeactivated[msg.sender], "Id Deactivated");
        Investor storage investor = investorsMap[msg.sender];
        collect(msg.sender);
        // require(block.timestamp > investor.withdrawalTime.add(10 minutes),"Withdrawal available every 24 hours");

        uint256 profit = investor.totalInvested.mul(MAX_LIMIT).div(100);
        if (isInsuranceTriggered) {
            profit = investor.totalInvested;
        }

        uint256 amount = investor.totalRewards +
            investor.unsettled;

        investor.unsettled = 0;
        if (amount.add(investor.totalWithdrawn) > profit) {
            amount = profit.sub(investor.totalWithdrawn);
        }
        uint256 _maxWithdrawal = maxWithdrawl;
        if (
            block.timestamp >
            withdrawDetails[msg.sender].timestamp.add(24 hours)
        ) {
            withdrawDetails[msg.sender].timestamp = block.timestamp;
            withdrawDetails[msg.sender].amount = 0;
        } else {
            if (withdrawDetails[msg.sender].amount.add(amount) > maxWithdrawl) {
                _maxWithdrawal = maxWithdrawl.sub(
                    withdrawDetails[msg.sender].amount
                );
            }
        }

        if (amount > _maxWithdrawal) {
            investor.unsettled = amount.sub(_maxWithdrawal);
            amount = _maxWithdrawal;
        }

        require(amount > 0, "Nothing to withdraw");
        withdrawDetails[msg.sender].amount += amount;
        investor.totalRewards = 0;
        investor.totalBonus = 0;
        investor.totalWithdrawn += amount;
        if (investor.totalWithdrawn >= MAX_EARNING) {
            idDeactivated[msg.sender] = true;
            if (!bonusLevels[msg.sender].isAdded) {
                royaltyUsers.push(msg.sender);
                bonusLevels[msg.sender].isAdded = true;
            }
            bonusLevels[msg.sender].level = 3;
        }
        investor.withdrawalTime = block.timestamp;
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        if (amount > balance) {
            IERC20(tokenAddress).transfer(msg.sender, balance);
            contractWithdrawn += balance;
        } else {
            IERC20(tokenAddress).transfer(msg.sender, amount);
            contractWithdrawn += amount;
        }

        _insuranceTrigger();

        if (IERC20(tokenAddress).balanceOf(address(this)) == 0) {
            IIPFSDeployer(roiDeployerAddress).deploy(
                owner,
                dev,
                marketing,
                payable(address(this))
            );
        }
    }

    function getRoiPer(address _user) public view returns (uint256) {
        if (investorsMap[_user].totalWithdrawn.add(investorsMap[_user].unsettled) >= 1000 * 1e18) {
            return 25;
        } else if (investorsMap[_user].totalWithdrawn.add(investorsMap[_user].unsettled) >= 500 * 1e18) {
            return 50;
        }
        return Daily_ROI_Per;
    }

    function collect(address _addr) public {
        Investor storage investor = investorsMap[_addr];
        uint256 per = getRoiPer(msg.sender);

        for (uint256 i = 0; i < investor.deposits.length; i++) {
            DepositStruct storage dep = investor.deposits[i];
            uint256 share = dep.amount.mul(per).div(percentDividerROI);
            uint256 from = dep.time > investor.time ? dep.time : investor.time;
            uint256 to = block.timestamp;
            uint256 dividends = 0;
            uint256 profit = dep.amount.mul(MAX_LIMIT).div(percentDivider);
            if (from < to) {
                dividends = share.mul(to.sub(from)).div(TIME_STEP);
                if (
                    dep.withdrawn.add(dividends) > profit
                ) {
                    dividends = dep
                        .amount
                        .mul(MAX_LIMIT)
                        .div(percentDivider)
                        .sub(dep.withdrawn);
                }
                else if(investor.totalBonus>0){
                    uint256 pendingProfit = profit.sub(dep.withdrawn.add(dividends));
                    if(investor.totalBonus>pendingProfit)
                    {
                        dividends = dividends.add(pendingProfit);
                        investor.totalBonus = investor.totalBonus.sub(pendingProfit);
                    }
                    else{
                        dividends = dividends.add(investor.totalBonus);
                        investor.totalBonus = 0;
                    }
                }
                investor.totalRewards = investor.totalRewards.add(dividends);
                dep.withdrawn = dep.withdrawn.add(dividends);
            }
        }
        investor.totalBonus = 0;
        investor.time = block.timestamp;
    }

    function _distributeRoyaltyLevel1() public {
        if (royaltyFunds > 5 ether) {
        uint256 globalCount;
        for (uint256 i = 0; i < royaltyUsers.length; i++) {
            if (bonusLevels[royaltyUsers[i]].level == 1) {
                globalCount = globalCount.add(1);
            }
        }
        if (globalCount > 0) {
            uint256 reward = royaltyFunds.div(globalCount);
            for (uint256 i = 0; i < royaltyUsers.length; i++) {
                if (bonusLevels[royaltyUsers[i]].level == 1) {
                    investorsMap[royaltyUsers[i]].totalBonus = investorsMap[
                        royaltyUsers[i]
                    ].totalBonus.add(reward);
                    earningUsers[royaltyUsers[i]].royaltyIncome += reward;
                }
            }
            royaltyFunds = 0;
        }
        }
    }

    function _distributeRoyaltyLevel2() public {
        if (royaltyFundsLevel2 > 5 ether) {
        uint256 globalCount;
        for (uint256 i = 0; i < royaltyUsers.length; i++) {
            if (bonusLevels[royaltyUsers[i]].level == 2) {
                globalCount = globalCount.add(1);
            }
        }
        if (globalCount > 0) {
            uint256 reward = royaltyFundsLevel2.div(globalCount);
            for (uint256 i = 0; i < royaltyUsers.length; i++) {
                if (bonusLevels[royaltyUsers[i]].level == 2) {
                    investorsMap[royaltyUsers[i]].totalBonus = investorsMap[
                        royaltyUsers[i]
                    ].totalBonus.add(reward);
                    earningUsers[royaltyUsers[i]].royaltyIncome1 += reward;
                }
            }
            royaltyFundsLevel2 = 0;
        }
        }
    }

    function _distributePension() public {
        if (pensionFunds > 5 ether) {
        uint256 globalCount;
        for (uint256 i = 0; i < royaltyUsers.length; i++) {
            if (bonusLevels[royaltyUsers[i]].level == 3) {
                globalCount = globalCount.add(1);
            }
        }
        if (globalCount > 0) {
            uint256 reward = pensionFunds.div(globalCount);
            for (uint256 i = 0; i < royaltyUsers.length; i++) {
                if (bonusLevels[royaltyUsers[i]].level == 3) {
                    earningUsers[royaltyUsers[i]].pensionIncomeAvailable += reward;
                    earningUsers[royaltyUsers[i]].pensionIncome += reward;
                }
            }
            pensionFunds = 0;
        }
        }
    }

    function withdrawPension() external{
        require(earningUsers[msg.sender].pensionIncomeAvailable>0,"Nothing to withdraw");
         IERC20(tokenAddress).transfer(msg.sender, earningUsers[msg.sender].pensionIncomeAvailable);
        emit Withdraw(msg.sender,earningUsers[msg.sender].pensionIncomeAvailable);
        earningUsers[msg.sender].pensionIncomeAvailable = 0;
    }

    function distributePool() internal {
        if (royaltyFunds > 5 ether) {
            _distributeRoyaltyLevel1();
        }
        if (royaltyFundsLevel2 > 5 ether) {
            _distributeRoyaltyLevel2();
        }
        if (pensionFunds > 5 ether) {
            _distributePension();
        }
    }

    function calcPayout(address _addr) public view returns (uint256) {
        Investor storage investor = investorsMap[_addr];
        uint256 per = getRoiPer(_addr);
        uint256 totalAmount;

        for (uint256 i = 0; i < investor.deposits.length; i++) {
            DepositStruct memory dep = investor.deposits[i];
            uint256 share = dep.amount.mul(per).div(percentDividerROI);
            uint256 from = dep.time > investor.time ? dep.time : investor.time;
            uint256 profit = dep.amount.mul(MAX_LIMIT).div(percentDivider);
            uint256 dividends = 0;
            if (from < block.timestamp) {
                dividends = share.mul((block.timestamp).sub(from)).div(TIME_STEP);
                if (
                    dep.withdrawn.add(dividends) >
                    profit
                ) {
                    dividends = dep
                        .amount
                        .mul(MAX_LIMIT)
                        .div(percentDivider)
                        .sub(dep.withdrawn);
                }
                else if(investor.totalBonus>0){
                    uint256 pendingProfit = profit.sub(dep.withdrawn.add(dividends));
                    if(investor.totalBonus>pendingProfit)
                    {
                        dividends = dividends.add(pendingProfit);
                    }
                    else{
                        dividends = dividends.add(investor.totalBonus);
                    }
                }
                totalAmount = totalAmount.add(dividends);
            }
        }

        return totalAmount;
    }

    function getAvailabel(address _addr) public view returns (uint256) {
        Investor storage investor = investorsMap[_addr];
        uint256 payout = this.calcPayout(_addr);
        uint256 amount = investor.totalRewards.add(payout).add(
            investor.unsettled
        );
        uint256 profit = investor.totalInvested.mul(MAX_LIMIT).div(
            percentDivider
        );
        if (isInsuranceTriggered) {
            profit = investor.totalInvested;
        }

        if (amount.add(investor.totalWithdrawn) > profit) {
            amount = profit.sub(investor.totalWithdrawn);
        }
        return amount;
    }

    


    function _userInfo(address _addr)
        external
        view
        returns (
            uint256 for_withdraw,
            uint256 totalInvested,
            uint256 totalWithdrawn,
            uint256 totalBonus,
            uint256 totalRewards,
            uint256 totalReferralInvested,
            uint256[BonusLinesCount] memory structure,
            uint256[BonusLinesCount] memory referralEarningsL,
            DepositStruct[] memory deposits
        )
    {
        Investor storage investor = investorsMap[_addr];

        uint256 payout = this.calcPayout(_addr);

        for (uint8 i = 0; i < BonusLinesCount; i++) {
            structure[i] = investor.structure[i];
            referralEarningsL[i] = investor.referralEarningsL[i];
        }

        return (
            payout,
            investor.totalInvested,
            investor.totalWithdrawn,
            investor.totalBonus,
            investor.totalRewards,
            investor.totalReferralInvested,
            structure,
            referralEarningsL,
            investor.deposits
        );
    }


     function _userEarningInfo(address _addr)
        external
        view
        returns (
            uint256 dividendIncome,
            uint256 roayltyIncome,
            uint256 royaltyIncome1,
            uint256 pensionIncome,
            uint256 joinedTime
        )
    {
        userEarning storage investor = earningUsers[_addr];

        return (
            investor.dividendIncome,
            investor.royaltyIncome,
            investor.royaltyIncome1,
            investor.pensionIncome,
            investor.joinedTime
            );
    }

    function contractInfo()
        external
        view
        returns (
            uint256 _invested,
            uint256 _withdrawn,
            uint256 _match_bonus,
            uint256 _totalUsers,
            uint256 latestDeposits
        )
    {
        return (contractInvested, contractWithdrawn, matchBonus, totalUsers,_latestDeposits.length);
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function setReferral(address _user, address _upline) external returns(bool) {
        require(
            IIPFSDeployer(roiDeployerAddress).isWhitelisted(msg.sender),
            "Invalid user"
        );
        investorsMap[_user].isExist = true;
        if(earningUsers[_user].joinedTime==0){
        earningUsers[_user].joinedTime = block.timestamp;
        }
        if (_upline == address(0) || !investorsMap[_upline].isExist) {
            _upline = owner;
        }
         if (
            investorsMap[_user].daddy == address(0) &&
            investorsMap[_upline].isExist &&
            _user != _upline  && _upline!=address(0)
        ) {
            investorsMap[_user].daddy = _upline;
            emit regLevelEvent(_user,_upline,block.timestamp);
            return true;
        }
        return false;
    }

    function getReferral(address _user) external view returns (address) {
        require(
            IIPFSDeployer(roiDeployerAddress).isWhitelisted(msg.sender),
            "Invalid user"
        );
        return investorsMap[_user].daddy;
    }
}