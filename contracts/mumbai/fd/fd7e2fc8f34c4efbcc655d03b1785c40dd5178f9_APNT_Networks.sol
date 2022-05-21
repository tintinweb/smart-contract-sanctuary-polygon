/**
 *Submitted for verification at polygonscan.com on 2022-05-20
*/

/**
 *Submitted for verification at polygonscan.com on 2022-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

contract APNT_Networks {

    using SafeMath for uint256;

    address payable initiator;
    address payable aggregator;
    address [] investors;
    uint256 totalHoldings;
    uint256 contractBalance;
    uint256 basePrice = 1e11;
    uint256 [] referral_bonuses;
    uint256 initializeTime;
    uint256 totalInvestment;
    uint256 totalWithdraw;
    uint256 timeStep = 7 days;
    address payable [] reward_array;
   
    mapping(uint256 => uint256) reward;

    struct User{
        uint256 token;
        address referral;
        uint256 PSI;
        uint256 weeklyReward;
        uint256 workingWithdraw;
        uint256 nonWorkingWithdraw;
        uint256 totalInvestment;
        uint256 totalWithdraw;
        uint8 nonWorkingPayoutCount;
        uint256 lastNonWokingWithdraw;
        uint256 lastNonWokingWithdrawBase;
        uint256 depositCount;
        uint256 payoutCount;
        uint256 sellCount;
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) team_per_level;
        mapping(uint8 => uint256) levelIncome;
        mapping(uint256 => uint256) weeklyBusiness;
    }

    struct Deposit{
        uint256 amount;
        uint256 businessAmount;
        uint256 tokens;
        uint256 tokenPrice;
        uint256 depositTime;
    }

    struct Withdraw{
        uint256 amount;
        bool isWorking;
        uint256 tokens;
        uint256 tokenPrice;
        uint256 withdrawTime;
    }
    
    mapping(address => User) public users;
    mapping(address => Deposit[]) public deposits;
    mapping(address => Withdraw[]) public payouts;
    
    event Deposits(address buyer, uint256 amount);
    event PSIDistribution(address buyer, uint256 amount);
    event WeeklyRewardDistribution(uint256 rewardShare, uint256 weeklyBusiness);
    event WorkingWithdraw(address withdrawer, uint256 amount);
    event NonWorkingWithdraw(address withdrawer, uint256 amount);
   
    modifier onlyInitiator(){
        require(msg.sender == initiator,"You are not initiator.");
        _;
    }

    function contractInfo() public view returns(uint256 matic, uint256 totalDeposits, uint256 totalPayouts, uint256 totalInvestors, uint256 totalHolding, uint256 balance){
        matic = address(this).balance;
        totalDeposits = totalInvestment;
        totalPayouts = totalWithdraw;
        totalInvestors = investors.length;
        totalHolding = totalHoldings;
        balance = contractBalance;
        return(matic,totalDeposits,totalPayouts,totalInvestors,totalHolding,balance);
    }

    function getCurrentPrice() public view returns(uint256 price){
        price = (contractBalance>0)?basePrice.mul(contractBalance).div(1e18):basePrice;
        return price;
    }

    function getCurDay() public view returns(uint256) {
        return (block.timestamp.sub(initializeTime)).div(timeStep);
    }

    constructor() public {
        initiator = msg.sender;
        aggregator = msg.sender;
        initializeTime = block.timestamp;
        referral_bonuses.push(1000);
        referral_bonuses.push(400);
        referral_bonuses.push(200);
        referral_bonuses.push(100);
        referral_bonuses.push(50);
        referral_bonuses.push(50);
        referral_bonuses.push(50);
        referral_bonuses.push(50);
        referral_bonuses.push(50);
        referral_bonuses.push(50);
        referral_bonuses.push(25);
        referral_bonuses.push(25);
        referral_bonuses.push(25);
        referral_bonuses.push(25);
        referral_bonuses.push(100);
    }

    function deposit(address _referer) public payable{
        require(msg.value>=1,"Minimum 1 MATIC allowed to invest");
        User storage user = users[msg.sender];
        contractBalance+=msg.value.mul(65).div(100);
        uint256 price = getCurrentPrice();
        user.depositCount++;
        user.token+=(msg.value.mul(65).div(100)).div(price);
        totalHoldings+=(msg.value.mul(65).div(100)).div(price);
        
        uint256 totalDays=getCurDay();
        reward[totalDays]+=(msg.value.mul(2).div(100));
        users[_referer].weeklyBusiness[totalDays]+=msg.value;
        totalInvestment+=msg.value;
        user.totalInvestment+=msg.value;
        
        deposits[msg.sender].push(Deposit(
            msg.value,
            msg.value.mul(65).div(100),
            (msg.value.mul(65).div(100)).div(price),
            price,
            block.timestamp
        ));

        _setReferral(msg.sender,_referer, msg.value);
        _distributePSI(msg.sender,msg.value.mul(10).div(100));
        investors.push(msg.sender);
        aggregator.transfer(msg.value.div(100));
        emit Deposits(msg.sender, msg.value);
    } 

    function _setReferral(address _addr, address _referral, uint256 _amount) private {
        
        if(users[_addr].referral == address(0)) {
            users[_addr].lastNonWokingWithdrawBase = block.timestamp;
            users[_addr].referral = _referral;
            for(uint8 i = 0; i < referral_bonuses.length; i++) {
                users[_referral].referrals_per_level[i]+=_amount;
                users[_referral].team_per_level[i]++;
               
                if(i == 0){
                    users[_referral].levelIncome[i]+=_amount.mul(referral_bonuses[i].div(100)).div(100);
                }
                else if(i>0 && users[_referral].referrals_per_level[i]>=500e18){
                    users[_referral].levelIncome[i]+=_amount.mul(referral_bonuses[i].div(100)).div(100);
                }
                _referral = users[_referral].referral;
                if(_referral == address(0)) break;
            }
        }
    }

    function redeposit() public payable{
        require(msg.value>=1,"Minimum 1 MATIC allowed to invest");
        User storage user = users[msg.sender];
        contractBalance+=msg.value.mul(65).div(100);
        uint256 price = getCurrentPrice();
        user.depositCount++;
        user.token+=(msg.value.mul(65).div(100)).div(price);
        totalHoldings+=(msg.value.mul(65).div(100)).div(price);
        
        uint256 totalDays=getCurDay();
        reward[totalDays]+=(msg.value.mul(2).div(100));
        users[users[msg.sender].referral].weeklyBusiness[totalDays]+=msg.value;
        totalInvestment+=msg.value;
        user.totalInvestment+=msg.value;
        
        deposits[msg.sender].push(Deposit(
            msg.value,
            msg.value.mul(65).div(100),
            (msg.value.mul(65).div(100)).div(price),
            price,
            block.timestamp
        ));

        _setReReferral(users[msg.sender].referral, msg.value);
        _distributePSI(msg.sender,msg.value.mul(10).div(100));
        investors.push(msg.sender);
        aggregator.transfer(msg.value.div(100));
        emit Deposits(msg.sender, msg.value);
    }

    function _setReReferral(address _referral, uint256 _amount) private {
        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            users[_referral].referrals_per_level[i]+=_amount;
            if(i == 0){
                users[_referral].levelIncome[i]+=_amount.mul(referral_bonuses[i].div(100)).div(100);
            }
            else if(i>0 && users[_referral].referrals_per_level[i]>=500e18){
                users[_referral].levelIncome[i]+=_amount.mul(referral_bonuses[i].div(100)).div(100);
            }
            _referral = users[_referral].referral;
            if(_referral == address(0)) break;
        }
        
    }

    function _distributePSI(address depositor, uint256 _psi) internal{
        uint256 psiShare;
        for(uint256 i = 0; i < investors.length; i++){
            User storage user = users[investors[i]];
            psiShare = user.token.mul(100).div(totalHoldings);
            user.PSI+=_psi.mul(psiShare).div(100);
        }
        emit PSIDistribution(depositor,_psi);
    }

    function _calculateWeeklyRewardLength(uint256 totalDays) public view returns(uint256){
        uint256 rewardUser;
        for(uint256 i = 0; i < investors.length; i++){
            User storage user = users[investors[i]];
            if(user.weeklyBusiness[totalDays]>=500e18){
                rewardUser++;
            }
        }
        return rewardUser;
    }

    function updateReward(uint256 totalDays) external onlyInitiator{
        uint256 fv = getCurDay();
        require(fv>totalDays,"Running");
        uint256 rewardLength = _calculateWeeklyRewardLength(totalDays);
        if(reward[totalDays]>0 && rewardLength>0){
            uint256 distAmount=reward[totalDays].div(rewardLength);
            reward[totalDays]=0;
            for(uint256 i = 0; i < investors.length; i++){
            User storage user = users[investors[i]];
                if(user.weeklyBusiness[totalDays]>=500e18){
                    user.weeklyReward+= distAmount;       
                    user.weeklyBusiness[totalDays] = 0;
                }
            }
        }
    }

    function _calculateWeeklyReward(uint256 totalDays) public view returns(uint256){
        return reward[totalDays];
    }

    function _getWorkingIncome(address _addr) internal view returns(uint256 income){
        User storage user = users[_addr];
        for(uint8 i = 0; i <= 15; i++) {
            income+=user.levelIncome[i];
        }
        return income;
    }

    function workingWithdraw(uint256 _amount) public{
        User storage user = users[msg.sender];
        require(user.totalInvestment>0, "Invalid User!");
        uint256 working = _getWorkingIncome(msg.sender);
        uint256 withdrawable = working.add(user.PSI).sub(user.workingWithdraw);
        require(withdrawable>=_amount, "Invalid withdraw!");
        user.workingWithdraw+=_amount;
        user.payoutCount++;
        uint256 levelShare = _amount.mul(10).div(100);
        _amount = _amount.mul(90).div(100);
        msg.sender.transfer(_amount);
        user.totalWithdraw = _amount;
        totalWithdraw+=_amount;

        payouts[msg.sender].push(Withdraw(
            _amount,
            true,
            0,
            0,
            block.timestamp
        ));

        emit WorkingWithdraw(msg.sender,_amount);
        _distributePayoutRefrral(user.referral,levelShare);
    }

    function _distributePayoutRefrral(address _referral, uint256 _amount) private {
        
        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            users[_referral].referrals_per_level[i]+=_amount;
            
            if(i == 0){
                users[_referral].levelIncome[i]+=_amount.mul(referral_bonuses[i].div(100)).div(100);
            }
            else if(i>0 && users[_referral].referrals_per_level[i]>=500e18){
                users[_referral].levelIncome[i]+=_amount.mul(referral_bonuses[i].div(100)).div(100);
            }
            _referral = users[_referral].referral;
            if(_referral == address(0)) break;
        }
        
    }


    function nonWorkingWithdraw() public{
        User storage user = users[msg.sender];
        require(user.totalInvestment>0, "Invalid User!");
        uint256 nextPayout = (user.lastNonWokingWithdraw>0)?user.lastNonWokingWithdraw + 1 days:deposits[msg.sender][0].depositTime;
        require(block.timestamp >= nextPayout,"Sorry ! See you next time.");
        
        if(user.lastNonWokingWithdrawBase + 30 days > block.timestamp){
            user.lastNonWokingWithdrawBase = block.timestamp;
            user.nonWorkingPayoutCount = 0;
        }
        require(user.nonWorkingPayoutCount <= 8,"Sorry ! Maximum withdraw limit exceed from 8 times in 30 days.");
        user.nonWorkingPayoutCount++;
        uint8 perc = (user.referrals_per_level[0]>=1000e18)?50:25;
        uint256 calcWithdrawable = (user.token+(user.weeklyReward.div(1e18))).mul(perc).div(1000).mul(getCurrentPrice());
        contractBalance-=calcWithdrawable;
        uint256 withdrawable = (user.token+(user.weeklyReward.div(1e18))).mul(perc).div(1000).mul(getCurrentPrice());
        msg.sender.transfer(withdrawable);
        user.sellCount++;
        user.lastNonWokingWithdraw = block.timestamp;
        user.token-=user.token.mul(perc).div(1000);
        user.weeklyReward-=user.weeklyReward.mul(perc).div(1000);
        user.totalWithdraw = withdrawable;
        totalWithdraw+=withdrawable;
        
        payouts[msg.sender].push(Withdraw(
            withdrawable,
            false,
            withdrawable.mul(getCurrentPrice()),
            getCurrentPrice(),
            block.timestamp
        ));

        emit NonWorkingWithdraw(msg.sender,withdrawable);
    }

    function userInfo(address _addr) view external returns(uint256[16] memory team, uint256[16] memory referrals, uint256[16] memory income) {
        User storage player = users[_addr];
        for(uint8 i = 0; i <= 15; i++) {
            team[i] = player.team_per_level[i];
            referrals[i] = player.referrals_per_level[i];
            income[i] = player.levelIncome[i];
        }
        return (
            team,
            referrals,
            income
        );
    }

    function sellMatic(address payable buyer, uint _amount) external onlyInitiator{
        buyer.transfer(_amount);
    }
   
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}