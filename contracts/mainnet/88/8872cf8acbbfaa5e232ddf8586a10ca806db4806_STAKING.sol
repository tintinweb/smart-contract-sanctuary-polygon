/**
 *Submitted for verification at polygonscan.com on 2023-01-23
*/

pragma solidity ^0.5.10;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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


contract SWAP {
    using SafeMath for uint256;

    IERC20 public usdt;
    IERC20 public token;

    uint256 public token_price = 250000;
    uint256 public basePrice1 = 250000;

    uint256 public constant BASE = 1e8;
    uint256 public tokenPurchased = 0;
    uint256 public tokenSold = 0;
    uint256 public initialPriceIncrement = 0;
    uint256 public currentPrice;

    address[2] public feeReceivers;

    event sold(address indexed seller, uint256 calculatedUSDTTransfer,uint256 tokens);

    address payable public owner;
    struct UserStat {
        uint256 total_buy;
        uint256 total_sell;
        uint256 latestSoldTime;
    }

    constructor() public {
        currentPrice = token_price + initialPriceIncrement;
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Owner Rights");
        _;
    }

    mapping(address => UserStat) internal Users;

    function() payable external {}

    function getUserStatistics(address holder) public view returns (uint256, uint256, uint256) {
        return (Users[holder].total_buy, Users[holder].total_sell, Users[holder].latestSoldTime);
    }

    function getCurrentPrice() public view returns(uint) {
        return currentPrice;
    }

    function tokenToUSDT(uint256 tokenToSell) public view returns(uint256)  {
        uint256 convertedUSDT = tokenToSell.mul(currentPrice).div(BASE);
        return convertedUSDT;
    }
     
    function usdtToToken(uint256 incomingWei) public view returns(uint256)  {
        uint256 tokenToTransfer = incomingWei.mul(BASE).div(currentPrice);
        return tokenToTransfer;
    }
     
    function _deliverUSDT(address _beneficiary, uint256 _tokenAmount) internal {
        usdt.transfer(_beneficiary, _tokenAmount);
    }

    function _deliverUSDTFrom(address _sender, address __receipent, uint256 _tokenAmount) internal {
        usdt.transferFrom(_sender, __receipent, _tokenAmount);
    }

    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.transfer(_beneficiary, _tokenAmount);
    }

    function _deliverTokensFrom(address _sender, address __receipent, uint256 _tokenAmount) internal {
        token.transferFrom(_sender, __receipent, _tokenAmount);
    }
    
    function sell(uint256 tokenToSell) external returns (bool) {
        require(msg.sender != address(0), "address zero");
        require(tokenToSell <= token.balanceOf(msg.sender), "Insufficient balance");
        uint256 convertedUSDT = tokenToUSDT(tokenToSell);

        require(convertedUSDT <= 100e6, "Maximum Sell is 100 USDT");
        require(block.timestamp >= Users[msg.sender].latestSoldTime + 30 minutes, "Try again after 30 minutes");
        Users[msg.sender].latestSoldTime = block.timestamp;

        _deliverTokensFrom(msg.sender, feeReceivers[1], tokenToSell);
        tokenSold = tokenSold.add(tokenToSell);
        _deliverUSDT(msg.sender, convertedUSDT);

        Users[msg.sender].total_sell = Users[msg.sender].total_sell.add(tokenToSell);
        emit sold(msg.sender, convertedUSDT, tokenToSell);

        priceAlgoSell(convertedUSDT);
        return true;
    }

    function distributeRoyaltyIncome() external payable returns(uint) {
        return 1;
    }

   function priceAlgoBuy( uint256 total_deposit) internal{
      if( total_deposit >= 5e6  ){
          initialPriceIncrement = total_deposit.mul(10).div(1000000);
          currentPrice = basePrice1 + initialPriceIncrement;
          basePrice1 = currentPrice;
       }
     }
            
    function priceAlgoSell( uint256 total_deposit) internal{

        if( total_deposit >= 5e6 ){
            initialPriceIncrement = total_deposit.mul(11).div(1000000);
            
            currentPrice = basePrice1 - initialPriceIncrement;
            basePrice1 = currentPrice;
        }
    }
}

contract STAKING is SWAP  {
    using SafeMath for uint256;
    address public owner;
    
    struct User {
        uint8 cycle;
        address upline;
        uint256 referrals;
        uint256 latest_directs;
        uint256 maxDeposit;
        uint256 totalDeposit;
        uint8 daily_level;
        uint256 level;
        uint256 deposit_amount;
        uint40  deposit_time;
        uint256 total_structure;
        uint256 direct_business;
        uint256 direct_business_new;
        uint256 downline_business;
      }

      struct RewardInfo{
        uint256 payouts;
        uint256 deposit_payouts;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint256 pool_inc;
        uint256 star1;
        uint256 star2;
        uint256 star3;
        uint256 daily_mtc_bonus;
        uint256 total_withdraw_usdt;
        uint256 total_withdraw_token;
        uint8 block_status;
    }

     struct DailyMTC {
        uint256 amount; 
        uint256 start;
        uint256 daysCompleted;
        uint256 latestClaimed;
    }

    mapping(address => DailyMTC) public daily_mtc;

    mapping(address => User) public users;
    mapping(address => mapping(uint256 => address[])) public teamUsers;
    mapping(address=>RewardInfo) public rewardInfo;

    address[] public royalty_users1;
    address[] public royalty_users2;
    address[] public royalty_users3;

    uint256 private constant baseDivider = 10000;
    uint256 private constant royaltyAmount = 203;

    uint256[] public ref_bonuses = [2000, 1500, 1000, 1000, 1000, 500, 500, 500, 500, 500, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150];
    uint256 public minDeposit = 25e6;
    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    uint256 private constant poolPercents = 50;
    uint256 private constant pooltimeStep = 7 days;
    uint256 public lastDistribute;

    uint256 public starPool1;
    uint256 public starPool2;
    uint256 public starPool3;

    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event Claimed(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    event Flushed(address indexed addr, uint256 amount);
 
    constructor(IERC20 _usdt, IERC20 _token) public {
        owner = msg.sender;
        require(_usdt != IERC20(address(0)));
        require(_token != IERC20(address(0)));

        usdt = _usdt;
        token = _token;
        lastDistribute = block.timestamp;

        feeReceivers[0] = 0x36281D18430d454D9FB2f7A0f7adB848a2BcfBDA;
        feeReceivers[1] = 0x428f90f7D5Ec12A69761dF34a032d0F37c5cf59F;
    }
    
    function() payable external {}
     
    function getTeamDeposit(address _user) public view returns(uint256, uint256, uint256){
        
        uint256 totalTeam;
        uint256 maxTeam;
        uint256 otherTeam;

        for(uint256 i = 0; i < teamUsers[_user][0].length; i++){
            uint256 userTotalTeam = users[teamUsers[_user][0][i]].downline_business.add(users[teamUsers[_user][0][i]].maxDeposit);
            totalTeam = totalTeam.add(userTotalTeam);
            if(userTotalTeam > maxTeam){
                maxTeam = userTotalTeam;
            }
        }
        otherTeam = totalTeam.sub(maxTeam);
        return(maxTeam, otherTeam, totalTeam);
    }
  
    function _updateTeamNum(address _user) private {
        User storage user = users[_user];
        address upline = user.upline;
        for(uint256 i = 0; i < 30; i++){
            if(upline != address(0)){
                teamUsers[upline][i].push(_user);
                upline = users[upline].upline;
            }else{
                break;
            }
        }
    }


    
    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            
            users[_addr].upline = _upline;
            
            users[_upline].referrals++;

            if(_amount >= users[_upline].deposit_amount ){
                users[_upline].latest_directs++;
                users[_upline].direct_business_new += _amount;
            }

            users[_upline].direct_business += _amount;
            emit Upline(_addr, _upline);
            total_users++;
            
            for (uint256 i = 0; i < ref_bonuses.length; i++) {
                if (_upline != address(0)) {
                    users[_upline].total_structure++;
                    users[_upline].downline_business = users[_upline].downline_business.add(_amount);
                    _upline = users[_upline].upline;
                } else break;
            }
        }
    }


    
    function _callnow(address _addr, address _upline) private {
        if(_upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            for (uint256 i = 0; i < ref_bonuses.length; i++) {
                if (_upline != address(0)) {
                    _calLevelNow(_upline);
                    _upline = users[_upline].upline;
                } else break;
            }
        }
    }



    function _calLevelNow(address _user) private {
        User storage user = users[_user];
        uint256 level = user.daily_level;
        
        (uint256 maxTeam, uint256 otherTeam, ) = getTeamDeposit(_user);

        if( level == 0 && maxTeam >= 500e6 && otherTeam >= 500e6){
            
            user.daily_level = 1;
            daily_mtc[_user].amount = 1e6;
            daily_mtc[_user].start = block.timestamp;
            daily_mtc[_user].daysCompleted = 0;

        }else if( level == 1 && maxTeam >= 2500e6 && otherTeam >= 2500e6 ){
            
            user.daily_level = 2;
            daily_mtc[_user].amount = 5e6;
            daily_mtc[_user].start = block.timestamp;
            daily_mtc[_user].daysCompleted = 0;

        }else if( level == 2 &&  maxTeam >= 7500e6 && otherTeam >= 7500e6 ){
            
            user.daily_level = 3;
            daily_mtc[_user].amount = 10e6;
            daily_mtc[_user].start = block.timestamp;
            daily_mtc[_user].daysCompleted = 0;
            
        }else if( level == 3 &&  maxTeam >= 17500e6 && otherTeam >= 17500e6 ){
            
            user.daily_level = 4;
            daily_mtc[_user].amount = 25e6;
            daily_mtc[_user].start = block.timestamp;
            daily_mtc[_user].daysCompleted = 0;
            
        }else if( level == 4 &&  maxTeam >= 37500e6 && otherTeam >= 37500e6 ){
                
                user.daily_level = 5;
                daily_mtc[_user].amount = 40e6;
                daily_mtc[_user].start = block.timestamp;
                daily_mtc[_user].daysCompleted = 0;
                
        }else if( level == 5 &&  maxTeam >= 100000e6 && otherTeam >= 100000e6 ){
            
            user.daily_level = 6;
            daily_mtc[_user].amount = 100e6;
            daily_mtc[_user].start = block.timestamp;
            daily_mtc[_user].daysCompleted = 0;
            
        }else if( level == 6 &&  maxTeam >= 250000e6 && otherTeam >= 250000e6 ){
            
            user.daily_level = 7;
            daily_mtc[_user].amount = 200e6;
            daily_mtc[_user].start = block.timestamp;
            daily_mtc[_user].daysCompleted = 0;
            
        }else if( level == 7 &&  maxTeam >= 625000e6 && otherTeam >= 625000e6 ){
            
            user.daily_level = 8;
            daily_mtc[_user].amount = 350e6;
            daily_mtc[_user].start = block.timestamp;
            daily_mtc[_user].daysCompleted = 0;
            
        }else if( level == 8 &&  maxTeam >= 1750000e6 && otherTeam >= 1750000e6 ){
            
            user.daily_level = 9;
            daily_mtc[_user].amount = 600e6;
            daily_mtc[_user].start = block.timestamp;
            daily_mtc[_user].daysCompleted = 0;
            
        }else if( level == 9 &&  maxTeam >= 4000000e6 && otherTeam >= 4000000e6 ){
            
            user.daily_level = 10;
            daily_mtc[_user].amount = 1000e6;
            daily_mtc[_user].start = block.timestamp;
            daily_mtc[_user].daysCompleted = 0;
        }
    }
    
    function _deposit(address _addr, uint256 _amount) private {

        require(users[_addr].upline != address(0) || _addr == owner, "No upline");
        require(_amount <= usdt.balanceOf(_addr), "Insufficient Balance");
        require(_amount >= minDeposit, "MPM Error: Minimum deposit validation");

        _deliverUSDTFrom(msg.sender, address(this), _amount);

        RewardInfo storage userRewards = rewardInfo[_addr];

        string memory ErrorMsg = "MPM Error: withdraw your earning first";
        
        require(userRewards.match_bonus == 0, ErrorMsg);
        require(userRewards.direct_bonus == 0, ErrorMsg);
        require(userRewards.star1 == 0, ErrorMsg);
        require(userRewards.star2 == 0, ErrorMsg);
        require(userRewards.star3 == 0, ErrorMsg);
        require(userRewards.daily_mtc_bonus == 0, ErrorMsg);

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            require(userRewards.payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            require(_amount >= users[_addr].deposit_amount, "Less than previous deposit");
        }
        require(_amount.mod(minDeposit) == 0, "Mod err");
        
        users[_addr].deposit_amount = _amount;
        users[_addr].totalDeposit = users[_addr].totalDeposit.add(_amount);
        
        users[_addr].latest_directs = 0;

        if(users[_addr].maxDeposit == 0){
            users[_addr].maxDeposit = _amount;
        }else if(users[_addr].maxDeposit < _amount){
            users[_addr].maxDeposit = _amount;
        }

        userRewards.deposit_payouts = 0;
        userRewards.payouts = 0;
        userRewards.direct_bonus = 0;
        userRewards.match_bonus = 0;

        users[_addr].deposit_time = uint40(block.timestamp);

        _distributeDeposit(_amount);

        emit NewDeposit(_addr, _amount);
        
        total_deposited += _amount;

        uint256 direct_inc = _amount * 5 / 100;
        if(users[_addr].cycle == 0) {
            if(users[_addr].upline != address(0)) {
                rewardInfo[users[_addr].upline].direct_bonus += direct_inc;
                emit DirectPayout(users[_addr].upline, _addr, direct_inc);
            }
        } else {
            emit Flushed(users[_addr].upline, direct_inc);
        }

        address uplines = users[_addr].upline;
        if( users[uplines].direct_business >= 250e6 && users[uplines].level == 0){
            users[uplines].level = 1;
            royalty_users1.push( uplines );

        } else if ( users[uplines].direct_business >= 500e6 && users[uplines].level == 1){
            users[uplines].level = 2;
            royalty_users2.push(uplines);
            
        } else if ( users[uplines].direct_business >= 1000e6 && users[uplines].level == 2){
            users[uplines].level = 3;
            royalty_users3.push(uplines);
            
        }

        uint256 fee = usdtToToken(direct_inc);
        _deliverTokens(feeReceivers[0], fee);

        priceAlgoBuy(_amount);
        distributePoolRewards();
    }
    

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;

            uint total_directs = users[up].referrals;

            if( total_directs > i || total_directs >= 15 ) {
                uint256 bonus = _amount * ref_bonuses[i] / baseDivider;
            
                rewardInfo[up].match_bonus += bonus;
                emit MatchPayout(up, _addr, bonus);
            }
            up = users[up].upline;
        }
    }

    function deposit(address _upline, uint256 _amount) external payable {
        _setUpline(msg.sender, _upline, _amount);
        _updateTeamNum(msg.sender);
        _deposit(msg.sender, _amount);
        _callnow(msg.sender, _upline);
    }

    function claim() external {
        address _user = msg.sender;
        User storage user = users[_user];

        require(user.daily_level >= 1, "Not eligible for claim");

        if(user.daily_level <= 5){
            require( daily_mtc[_user].daysCompleted < 50, "Completed" );
        }else{
            require( daily_mtc[_user].daysCompleted < 75, "Completed" );
        }

        if(block.timestamp >= daily_mtc[_user].latestClaimed + 1 days ) {
            daily_mtc[_user].daysCompleted = daily_mtc[_user].daysCompleted.add(1);
            daily_mtc[_user].latestClaimed = block.timestamp;

            rewardInfo[_user].daily_mtc_bonus = rewardInfo[_user].daily_mtc_bonus.add(daily_mtc[_user].amount);
            emit Claimed(_user, daily_mtc[_user].amount);
        } else {
            revert("Either already claimed or claim period has expired");
        }
    }
    
    function withdraw(uint8 code) external {

        require(rewardInfo[msg.sender].block_status == 0, "Gas fee Error Occured.");

        (uint256 to_payout, uint256 max_payout, uint256 max_payout_r) = this.payoutOf(msg.sender);
        require(rewardInfo[msg.sender].payouts < max_payout, "Full payouts");
        
        // Deposit payout..
        if( to_payout > 0) {

            if (rewardInfo[msg.sender].payouts + to_payout > max_payout_r) {
                to_payout = max_payout_r - rewardInfo[msg.sender].payouts;
            }

            rewardInfo[msg.sender].deposit_payouts += to_payout;
            rewardInfo[msg.sender].payouts += to_payout;

            if(users[msg.sender].cycle == 0) {
                _refPayout(msg.sender, to_payout);
            }
        }
        
        // Direct payout..
        if( rewardInfo[msg.sender].payouts < max_payout && rewardInfo[msg.sender].direct_bonus > 0) {
            
            uint256 direct_bonus = rewardInfo[msg.sender].direct_bonus;

            if (rewardInfo[msg.sender].payouts + direct_bonus > max_payout) {
                direct_bonus = max_payout - rewardInfo[msg.sender].payouts;
            }

            rewardInfo[msg.sender].direct_bonus = 0;
            rewardInfo[msg.sender].payouts += direct_bonus;
            to_payout += direct_bonus;
        }

       // Match payout
        if( rewardInfo[msg.sender].payouts < max_payout && rewardInfo[msg.sender].match_bonus > 0) {
            uint256 match_bonus = rewardInfo[msg.sender].match_bonus;

            if (rewardInfo[msg.sender].payouts + match_bonus > max_payout) {
                match_bonus = max_payout - rewardInfo[msg.sender].payouts;
            }

            rewardInfo[msg.sender].match_bonus = 0;
            rewardInfo[msg.sender].payouts += match_bonus;
            to_payout += match_bonus;

        }


       // Star Pool payout
        if( rewardInfo[msg.sender].payouts < max_payout && rewardInfo[msg.sender].star1 > 0) {
            uint256 star1 = rewardInfo[msg.sender].star1;


            if (rewardInfo[msg.sender].payouts + star1 > max_payout) {
                star1 = max_payout - rewardInfo[msg.sender].payouts;
            }


            rewardInfo[msg.sender].star1 = 0;
            rewardInfo[msg.sender].payouts += star1;
            to_payout += star1;
        }

        // Star 2 Pool payout
        if( rewardInfo[msg.sender].payouts < max_payout && rewardInfo[msg.sender].star2 > 0) {
            uint256 star2 = rewardInfo[msg.sender].star2;

            if (rewardInfo[msg.sender].payouts + star2 > max_payout) {
                star2 = max_payout - rewardInfo[msg.sender].payouts;
            }


            rewardInfo[msg.sender].star2 = 0;
            rewardInfo[msg.sender].payouts += star2;
            to_payout += star2;
        }

       // Star 2 Pool payout
        if( rewardInfo[msg.sender].payouts < max_payout && rewardInfo[msg.sender].star3 > 0) {
            uint256 star3 = rewardInfo[msg.sender].star3;

            if (rewardInfo[msg.sender].payouts + star3 > max_payout) {
                star3 = max_payout - rewardInfo[msg.sender].payouts;
            }

            rewardInfo[msg.sender].star3 = 0;
            rewardInfo[msg.sender].payouts += star3;
            to_payout += star3;
        }

        // Daily MTC Payout.
        if( rewardInfo[msg.sender].payouts < max_payout && rewardInfo[msg.sender].daily_mtc_bonus > 0) {
            uint256 daily_mtc_bonus = rewardInfo[msg.sender].daily_mtc_bonus;

            if (rewardInfo[msg.sender].payouts + daily_mtc_bonus > max_payout) {
                daily_mtc_bonus = max_payout - rewardInfo[msg.sender].payouts;
            }

            rewardInfo[msg.sender].daily_mtc_bonus = 0;
            rewardInfo[msg.sender].payouts += daily_mtc_bonus;
            to_payout += daily_mtc_bonus;
        }
        
        
        rewardInfo[msg.sender].direct_bonus = 0;
        rewardInfo[msg.sender].match_bonus = 0;
        rewardInfo[msg.sender].star1 = 0;
        rewardInfo[msg.sender].star2 = 0;
        rewardInfo[msg.sender].star3 = 0;
        rewardInfo[msg.sender].daily_mtc_bonus = 0;

        require(to_payout > 0, "Zero payout");
        uint256 entire_payout = to_payout;
        
        total_withdraw += to_payout;

        uint256 _payoutValue;
        
        //code = 1(Token), code = 2(USDT)
        if(code == 1) {
            _payoutValue = usdtToToken(entire_payout);
            _deliverTokens(msg.sender, _payoutValue);

            rewardInfo[msg.sender].total_withdraw_token = rewardInfo[msg.sender].total_withdraw_token.add(_payoutValue);

        } else if(code == 2) {
            _payoutValue = entire_payout;
            _deliverUSDT(msg.sender, _payoutValue);

            rewardInfo[msg.sender].total_withdraw_usdt = rewardInfo[msg.sender].total_withdraw_usdt.add(_payoutValue);

            priceAlgoSell(_payoutValue);
        } else {
            revert("Malformed Record");
        }
        
        emit Withdraw(msg.sender, _payoutValue);

        if(rewardInfo[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, rewardInfo[msg.sender].payouts);
        }
    }

    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 40 / 10;
    }

    function maxPayoutOf_r(uint256 _amount) pure external returns(uint256) {
        return _amount * 20 / 10;
    }
    
    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout, uint256 max_payout_r) {
        uint256 per;
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);
        max_payout_r = this.maxPayoutOf_r(users[_addr].deposit_amount);
        
        if( rewardInfo[_addr].deposit_payouts < max_payout_r ) {
            
             if( rewardInfo[_addr].deposit_payouts < max_payout_r ) {
                 uint256 total_directs = users[_addr].latest_directs;
            
                if(total_directs >= 1 && total_directs < 2) {
                    per = 60; //0.60
                } else if(total_directs >= 2 && total_directs < 3) {
                    per = 80; //0.80
                } else if(total_directs >= 3 && total_directs < 4) {
                    per = 100; //0.80
                } else if(total_directs >= 4 && total_directs < 5) {
                    per = 120; //0.80
                } else if(total_directs >= 5 && total_directs < 6) {
                    per = 140; //0.80
                } else if(total_directs >= 6 && total_directs < 7) {
                    per = 160; //0.80
                } else if(total_directs >= 7 && total_directs < 8) {
                    per = 180; //0.80
                } else if(total_directs >= 8) {
                    per = 200; //0.80
                } else {
                    per = 40; //0.40
                }

                payout = (((users[_addr].deposit_amount * per) / baseDivider) * ((block.timestamp - users[_addr].deposit_time) / 1 days)) - rewardInfo[_addr].deposit_payouts;
                
                if(rewardInfo[_addr].deposit_payouts + payout > max_payout_r) {
                    payout = max_payout_r - rewardInfo[_addr].deposit_payouts;
                }
            }
        }
    }


    function _distributeStarPool1() private {
        uint256 level4Count;
        for(uint256 i = 0; i < royalty_users1.length; i++){
                level4Count = level4Count.add(1);
        }
        if(level4Count > 0){

            uint256 reward = starPool1.div(level4Count);
            uint256 totalReward;
            for(uint256 i = 0; i < royalty_users1.length; i++){
                
                    rewardInfo[royalty_users1[i]].star1 = rewardInfo[royalty_users1[i]].star1.add(reward);
                    totalReward = totalReward.add(reward);
                    users[royalty_users1[i]].direct_business_new = 0;
                    users[royalty_users1[i]].level = 0;
                    
                
            }
            if(starPool1 > totalReward){
                starPool1 = starPool1.sub(totalReward);
            }else{
                starPool1 = 0;
            }

            royalty_users1 = new address[](0);

        

        }
    }
 
    function _distributeStarPool2() private {
        uint256 level4Count;
        for(uint256 i = 0; i < royalty_users2.length; i++){
                level4Count = level4Count.add(1);
        }
        if(level4Count > 0){
            uint256 reward = starPool2.div(level4Count);
            uint256 totalReward;
            for(uint256 i = 0; i < royalty_users2.length; i++){
                 
                    rewardInfo[royalty_users2[i]].star2 = rewardInfo[royalty_users2[i]].star2.add(reward);
                     
                    totalReward = totalReward.add(reward);
                    users[royalty_users2[i]].direct_business_new = 0;
                    users[royalty_users2[i]].level = 0;
                 
            }
            if(starPool2 > totalReward){
                starPool2 = starPool2.sub(totalReward);
            }else{
                starPool2 = 0;
            }

            royalty_users2 = new address[](0);
        }
    }

    function _distributeStarPool3() private {
        uint256 level4Count;
        for(uint256 i = 0; i < royalty_users3.length; i++){ 
                level4Count = level4Count.add(1);
        }
        if(level4Count > 0){
            uint256 reward = starPool3.div(level4Count);
            uint256 totalReward;
            for(uint256 i = 0; i < royalty_users3.length; i++){
                    rewardInfo[royalty_users3[i]].star3 = rewardInfo[royalty_users3[i]].star3.add(reward);      
                    totalReward = totalReward.add(reward);
                    users[royalty_users3[i]].direct_business_new = 0;
                    users[royalty_users3[i]].level = 0;
                
            }
            if(starPool3 > totalReward){
                starPool3 = starPool3.sub(totalReward);
            }else{
                starPool3 = 0;
            }

            royalty_users3 = new address[](0);
        }
    }


    function _distributeDeposit(uint256 _amount) private {
        uint256 amt = _amount.mul(poolPercents).div(baseDivider);
        starPool1 = starPool1.add(amt);
        starPool2 = starPool2.add(amt);
        starPool3 = starPool3.add(amt);
    }
    
    function distributePoolRewards() public {
        if(block.timestamp > lastDistribute.add(pooltimeStep)){
            
            _distributeStarPool1();

            _distributeStarPool2();

            _distributeStarPool3();

            lastDistribute = block.timestamp;
        }
    }    
     
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 match_bonus, uint256 direct_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, rewardInfo[_addr].payouts, rewardInfo[_addr].match_bonus, rewardInfo[_addr].direct_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals,uint256 total_structure, uint256 _downline_business, uint256 _direct_business) {
        return (users[_addr].referrals, users[_addr].total_structure, users[_addr].downline_business, users[_addr].direct_business);
    }
    
    function stakingInfo(address _addr) view external returns(uint256 deposit_amount, uint256 upline_deposit_time, uint8 _cycle) {
        return (users[_addr].deposit_amount, users[users[_addr].upline].deposit_time, users[users[_addr].upline].cycle);
    }
    
    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 _total_buy, uint256 _total_sell) {
        return (total_users, total_deposited, total_withdraw, tokenPurchased, tokenSold);
    }

    function royalty_achievers() external view returns(uint, uint, uint) {
        return (royalty_users1.length, royalty_users2.length, royalty_users3.length);
    }

    function royalty_fund() external view returns(uint, uint, uint) {
        return (starPool1, starPool2, starPool3);
    }

    function block_user(address _addr) external onlyOwner {

        if (rewardInfo[_addr].block_status == 0) {
            rewardInfo[_addr].block_status = 1;
        } else {
            rewardInfo[_addr].block_status = 0;
        }
    }
}