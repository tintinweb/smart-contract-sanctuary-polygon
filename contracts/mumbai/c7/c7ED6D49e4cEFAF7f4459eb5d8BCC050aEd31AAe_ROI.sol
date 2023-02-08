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

interface IROIDeployer {
    function deploy(address payable owner,address payable dev,address payable mainContract) external;
    function isWhitelisted(address _user) external view returns(bool);
}

interface IInsuranceContract {
    function initiate() external;

    function getBalance() external view returns (uint256);

    function getMainContract() external view returns (address);
}

contract INSURANCE {
    IERC20 public tokenAddress =
        IERC20(0xFf35D956CE6aAf76b893677CE9f52AB10F78380F);

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
    uint256 matrixIncome;
    bool isInvestedRestart;
    uint256 unsettled;
    bool isExist;
}

contract ROI {
    using SafeMath for uint256;
    using SafeMath for uint40;

    IERC20 public tokenAddress =
        IERC20(0xFf35D956CE6aAf76b893677CE9f52AB10F78380F);
    address restartAddress;

    uint256 public contractInvested;
    uint256 public contractWithdrawn;
    uint256 public matchBonus;
    uint256 public totalUsers;
    address defaultReferralAddress = 0xc7EDf5Ef5a04Df3b0B25dbd8016BcEA9c357eb87;

    uint8 constant BonusLinesCount = 5;
    uint16 constant percentDivider = 100;
    uint16 constant percentDividerROI = 10000;
    uint256 public minWithdrawl = 1 ether;
    uint256 public maxWithdrawl = 100 ether;
    

    uint256 referralBonus = 0;

    uint256 public MAX_LIMIT = 200;
    //uint40 public TIME_STEP = 86400;
    uint40 public TIME_STEP = 1;
    uint8 public Daily_ROI_Per = 100;

    uint256 MinimumDiposit = 1 * 1e18;
    uint256 MaximumDiposit = 100 * 1e18;
    uint256 CreatorsPercentage = 3;
    uint256 referralBonusPer = 40;
    uint256 public EgaleFund = 0;
    uint256 EgaleFundPer = 1;
    uint256 public royaltyFunds = 0;
    uint256 public pensionFunds;

    uint256[BonusLinesCount] RefferalPer = [40, 1, 1, 2, 3];

    mapping(address => Investor) public investorsMap;
    address[] public eagleFundUsers;
    address[] public royaltyUsers;
    address[] public pensionUsers;

    address payable public owner;
    address payable public dev;

    address payable public INSURANCE_CONTRACT;
    mapping(uint256 => uint256) public INSURANCE_MAXBALANCE;
    uint256 public constant INSURANCE_PERCENT = 20; // insurance fee 10% of claim
    uint256 public constant INSURANCE_LOWBALANCE_PERCENT = 5; // protection kicks in at 25% or lower
    uint256 public INSURANCE_TRIGGER_BALANCE;
    bool public isInsuranceTriggered;
   
    // Matrix
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

    struct BonusLevels{
        uint40 level;
        uint256 index;
    }
    mapping(address => UserStruct) public matrixUsers;
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
        uint256 _userId,
        uint256 _referralID,
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

    constructor(address payable CreatorAddr, address payable DevAddr) {
        INSURANCE_CONTRACT = payable(new INSURANCE());
        owner = CreatorAddr;
        dev = DevAddr;
        LEVEL_PRICE[1] = 1 ether;
        LEVEL_PRICE[2] = 2 ether;

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({activeLevel: 6, planbactivatedround: 10});

        matrixUsers[owner] = userStruct;

        userInfo memory UserInfo;

        UserInfo = userInfo({
            id: 1,
            referrerID: 0,
            childCount: 0,
            userAddress: owner,
            noofpayments: 0,
            activeLevel: 8
        });

        for (uint256 cnt = 1; cnt <= 2; cnt++) {
            userInfos[cnt][1] = UserInfo;
            lastIDCount[cnt] = 1;
            lastFreeParent[cnt] = 1;
            userAddressByID[cnt][1] = owner;
        }
    }

    function setRestartAddress(address _restart) external
    {
        require(msg.sender==owner,"invalid to set restart");
        restartAddress = _restart;
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = investorsMap[_addr].daddy;
        uint256 i = 0;
        
        uint256 bonus = 0;
        for (i = 0; i < BonusLinesCount; i++) {
            if (up == address(0)) break;
            bool flag = false;
            uint256 _sendAmount = investorsMap[up].lastInvestedAmount > _amount
                ? _amount
                : investorsMap[up].lastInvestedAmount;
            bonus = (_sendAmount * RefferalPer[i]) / percentDivider;

            if (i == 0) {
                flag = true;
            }
            else if (
                (i == 1 || i == 2) &&
                investorsMap[up].structure[0] >= 3 &&
                investorsMap[up].totalReferralInvested >= 500 * 1e18
            ) {
                flag = true;
            }
            else if (
                (i == 3 || i == 4) &&
                investorsMap[up].structure[0] >= 5 &&
                investorsMap[up].totalReferralInvested >= 1000 * 1e18
            ) {
                flag = true;
            }

            if (flag) {
                investorsMap[up].referralEarningsL[i] = investorsMap[up]
                    .referralEarningsL[i]
                    .add(bonus);
                investorsMap[up].totalBonus += bonus;
                investorsMap[up].totalRewards += bonus;
                matchBonus += bonus;
                emit MatchPayout(up, _addr, bonus);

                if(investorsMap[up].structure[0]>=6 && investorsMap[up].totalReferralInvested>=1500 ether && bonusLevels[up].level==0){//15
                    eagleFundUsers.push(up);
                   bonusLevels[up].level++;
                }
                if(investorsMap[up].structure[0]>=7 && investorsMap[up].totalReferralInvested>=10000 ether && bonusLevels[up].level==1){//100
                    bonusLevels[up].index=royaltyUsers.length;
                    royaltyUsers.push(up);
                     bonusLevels[up].level++;
                }
                if(investorsMap[up].totalReferralInvested>=100000 ether){
                    if(bonusLevels[up].level==2){
                        delete royaltyUsers[bonusLevels[up].index];
                    }
                    pensionUsers.push(up);
                     bonusLevels[up].level++;
                }
            }

            up = investorsMap[up].daddy;
        }
    }

    function _setUpdaddy(address _addr, address _upline) private {
        if (
            investorsMap[_addr].daddy == address(0) &&
            investorsMap[_upline].isExist
        ) {
            investorsMap[_addr].daddy = _upline;

            for (uint256 i = 0; i < BonusLinesCount; i++) {
                investorsMap[_upline].structure[i]++;

                _upline = investorsMap[_upline].daddy;

                if (_upline == address(0)) break;
            }
        }
    }

    

    function deposit(uint256 _amount, address _upline) public payable {
        uint256 amount = _amount;
        require(!isInsuranceTriggered, "Insurance payment started");
        collect(msg.sender);
        if (investorsMap[msg.sender].deposits.length == 0) {
            require(
                amount >= MinimumDiposit && amount <= MaximumDiposit,
                "You can deposite min 10$ or max 100$"
            );
        } else {
            require(
                amount >= 100 ether &&
                    amount >= investorsMap[msg.sender].lastInvestedAmount,
                "Deposite must be greater than 100$"
            );
        }
        require(
            amount >= investorsMap[msg.sender].lastInvestedAmount,
            "Invested amount should be greater than previous amount"
        );

        Investor storage investor = investorsMap[msg.sender];
        require(investor.deposits.length < 100, "Max 100 deposits per address");

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);

        if (_upline == address(0)) {
            _upline = defaultReferralAddress;
        }

        uint256 cfee = amount.mul(CreatorsPercentage).div(percentDivider).div(
            2
        );
        IERC20(tokenAddress).transfer(owner, cfee);
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

        investor.lastInvestedAmount = amount;
        if (investor.deposits.length == 1) {
            totalUsers++;
        }

        investor.totalInvested += amount;
        investorsMap[_upline].totalReferralInvested += amount;
        investorsMap[msg.sender].time = block.timestamp;
        contractInvested += amount;
        EgaleFund += _amount.mul(EgaleFundPer).div(percentDivider);
        royaltyFunds = royaltyFunds.add(_amount.mul(25).div(10000));
        pensionFunds = pensionFunds.add(_amount.mul(5).div(1000));

        _refPayout(msg.sender, amount);
        if (investorsMap[_upline].deposits.length == 1) {
            regUserPlanB(payable(msg.sender));
        }

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

    /*********Matrix */
    function regUserPlanB(address payable userAddress) internal {
        matrixUsers[userAddress].planbactivatedround++;
        uint256 _roundid = matrixUsers[userAddress].planbactivatedround;
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
        matrixUsers[userAddress].activeLevel = 1;

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

    function _buyLevel(
        uint256 _level,
        uint256 user,
        uint256 _roundid
    ) internal returns (bool) {
        address payable useradd = userAddressByID[_roundid][user];
        emit buyLevelEvent(
            useradd,
            _level,
            block.timestamp,
            LEVEL_PRICE[_level],
            _roundid
        );
        distributeBonus(user, _level, _roundid);
        userInfos[_roundid][user].activeLevel = _level;
        return true;
    }

    function distributeBonus(
        uint256 _addr,
        uint256 _level,
        uint256 _roundid
    ) internal {
        uint256 up = userInfos[_roundid][_addr].referrerID;
        uint256 amt = LEVEL_PRICE[_level];

        for (uint256 i = 0; i < _level; i++) {
            if (up == 0) break;
            up = userInfos[_roundid][up].referrerID;
        }
        if (up == 0) {
            up = 1;
        }
        address payable receiver = userAddressByID[_roundid][up];
        noofPayments[receiver][_level]++;

        if (_level == 1 && noofPayments[receiver][_level] == 2) {
            _buyLevel(userInfos[_roundid][up].activeLevel + 1, up, _roundid);
        }
        if (_level == 2 && noofPayments[receiver][_level] == 4) {
            investorsMap[receiver].matrixIncome += LEVEL_PRICE[2].div(2);
            noofPayments[receiver][1] = 0;
            noofPayments[receiver][2] = 0;
            regUserPlanB(userAddressByID[_roundid][up]);
        } else if (_level == 2) {
            investorsMap[receiver].matrixIncome += amt;
        }
    }

    /*******************Matrix end */

    function withdraw() external {
        Investor storage investor = investorsMap[msg.sender];
        collect(msg.sender);
        require(block.timestamp > investor.withdrawalTime.add(10 minutes),"Withdrawal available every 24 hours");
        require(
            (investor.totalRewards + investor.totalBonus + investor.unsettled) > minWithdrawl,
            "You dont have any amount to withdraw"
        );
        uint256 profit = investor.totalInvested.mul(MAX_LIMIT).div(100);
        if (isInsuranceTriggered) {
            profit = investor.totalInvested;
        }

        uint256 amount = investor.totalRewards + investor.totalBonus + investor.unsettled;
        investor.unsettled = 0;
        if (amount.add(investor.totalWithdrawn) > profit) {
            amount = profit.sub(investor.totalWithdrawn);
        }
        if(amount> maxWithdrawl){
            investor.unsettled = amount.sub(maxWithdrawl);
            amount = maxWithdrawl;
        }
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        if(amount>balance){
            investor.unsettled = investor.unsettled.add(amount.sub(balance));
            amount = balance;
        }
        investor.totalRewards = 0;
        investor.totalWithdrawn += amount;
        contractWithdrawn += amount;
        investor.withdrawalTime = block.timestamp;
        IERC20(tokenAddress).transfer(msg.sender, amount);
        _insuranceTrigger();
        if (IERC20(tokenAddress).balanceOf(address(this)) == 0) {
            IROIDeployer(restartAddress).deploy(owner,dev,payable(address(this)));
        }
    }

    function getRoiPer(address _user) public view returns (uint256) {
        if (
            investorsMap[_user].structure[0] >= 6 &&
            investorsMap[_user].totalReferralInvested >= 10000 * 1e18
        ) {
            return 25;
        } else if (
            investorsMap[_user].structure[0] >= 7 &&
            investorsMap[_user].totalReferralInvested >= 5000 * 1e18
        ) {
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
            if (from < to) {
                dividends = share.mul(to.sub(from)).div(TIME_STEP);
                if (
                    dep.withdrawn.add(dividends) >
                    dep.amount.mul(MAX_LIMIT).div(percentDivider)
                ) {
                    dividends = dep
                        .amount
                        .mul(MAX_LIMIT)
                        .div(percentDivider)
                        .sub(dep.withdrawn);
                }
                investor.totalRewards = investor.totalRewards.add(dividends);
                dep.withdrawn = dep.withdrawn.add(dividends);
            }
        }
        investor.time = block.timestamp;
    }

    //when to distribute
    function _distributeEagleFund() private {
        if (eagleFundUsers.length > 0) {
            uint256 reward = EgaleFund.div(eagleFundUsers.length);
            for (uint256 i = 0; i < eagleFundUsers.length; i++) {
                investorsMap[eagleFundUsers[i]].totalRewards = investorsMap[
                    eagleFundUsers[i]
                ].totalRewards.add(reward);
            }
            EgaleFund = 0;
        }
    }

    function _distributeRoyalty() private {
        if (royaltyUsers.length > 0) {
            uint256 reward = royaltyFunds.div(royaltyUsers.length);
            for (uint256 i = 0; i < royaltyUsers.length; i++) {
                investorsMap[royaltyUsers[i]].totalRewards = investorsMap[
                    royaltyUsers[i]
                ].totalRewards.add(reward);
            }
            royaltyFunds = 0;
        }
    }

    function _distributePension() private {
        if (pensionUsers.length > 0) {
            uint256 reward = pensionFunds.div(pensionUsers.length);
            for (uint256 i = 0; i < pensionUsers.length; i++) {
                investorsMap[pensionUsers[i]].totalRewards = investorsMap[
                    pensionUsers[i]
                ].totalRewards.add(reward);
            }
            pensionFunds = 0;
        }
    }

    function distributePool() internal
    {
        if(EgaleFund>50 ether){
            _distributeEagleFund();
        }
        if(royaltyFunds>50 ether){
            _distributeRoyalty();
        }
        if(pensionFunds>50 ether){
            _distributePension();
        }
    }

    function calcPayout(address _addr) public view returns (uint256) {
        Investor storage investor = investorsMap[_addr];
        uint256 per = getRoiPer(msg.sender);
        uint256 totalAmount;

        for (uint256 i = 0; i < investor.deposits.length; i++) {
            DepositStruct memory dep = investor.deposits[i];
            uint256 share = dep.amount.mul(per).div(percentDividerROI);
            uint256 from = dep.time > investor.time ? dep.time : investor.time;
            uint256 to = block.timestamp;
            uint256 dividends = 0;
            if (from < to) {
                dividends = share.mul(to.sub(from)).div(TIME_STEP);
                if (
                    dep.withdrawn.add(dividends) >
                    dep.amount.mul(MAX_LIMIT).div(percentDivider)
                ) {
                    dividends = dep
                        .amount
                        .mul(MAX_LIMIT)
                        .div(percentDivider)
                        .sub(dep.withdrawn);
                }
                totalAmount = totalAmount.add(dividends);
            }
        }

        return totalAmount;
    }

    function getAvailabel(address _addr) external view returns (uint256) {
        Investor storage investor = investorsMap[_addr];
        uint256 payout = this.calcPayout(_addr);
        uint256 amount = investor.totalRewards.add(payout).add(investor.unsettled);
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
            DepositStruct[] memory deposits,
            uint256 matrixIncome
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
            investor.deposits,
            investor.matrixIncome
        );
    }

    function contractInfo()
        external
        view
        returns (
            uint256 _invested,
            uint256 _withdrawn,
            uint256 _match_bonus,
            uint256 _totalUsers
        )
    {
        return (contractInvested, contractWithdrawn, matchBonus, totalUsers);
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function setReferral(address _user,address _upline) external
    {
        require(isWhitelisted[msg.sender],"Invalid user");
        investorsMap[_user].isExist = true;
        _setUpdaddy(_user, _upline);
    }

    function getReferral(address _user) external view returns(address)
    {
        require(IROIDeployer(restartAddress).isWhitelisted(msg.sender),"Invalid user");
        return investorsMap[_user].daddy;
    }
}