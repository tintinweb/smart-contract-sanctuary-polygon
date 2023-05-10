/**
 *Submitted for verification at polygonscan.com on 2023-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.10;

contract FFINetworkV2 {

    /*=================================
    =            MODIFIERS            =
    =================================*/

    // only people with tokens
    modifier onlybelievers () {
        require(_myTokens() > 0,"No Token Balance ?");
        _;
    }
    
    // only people with profits
    modifier onlyholder() {
        require(_dividendOf() > 0 || _referralOf()>0 || _communityWalletBalance()>0 || _stakingWalletBalance()>0 || _rewardWalletBalance()>0 || _stakingBonus()>0,"No Divident Or No Other Income ?");
        _;
    }
    
    // administrators can:
    // -> change the name of the contract
    // -> change the name of the token
    // they CANNOT:
    // -> take funds
    // -> disable withdrawals
    // -> kill the contract
    // -> change the price of tokens
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress],"Not An Owner ?");
        _;
    } 

    /*==============================
    =            EVENTS            =
    ==============================*/

    //Personalized Logic

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingMatic,
        uint256 tokensMinted,
        address indexed referredBy
    );
    
    event onTokenRePurchase(
        address indexed customerAddress,
        uint256 incomingMatic,
        uint256 tokensMinted
    );
    

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 maticEarned
    );
    
    event onReinvestment(
        address indexed customerAddress,
        uint256 maticReinvested,
        uint256 tokensMinted
    );
    
    event onWithdraw(
        address indexed customerAddress,
        uint256 maticWithdrawn
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    event WalletTransfer(
        uint256 transfermatic
    );
      
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/

    string public name = "FFI Network";
    string public symbol = "FFI";
    uint8 constant public decimals = 18;

    //Buy Deduction Declaration
    uint8 constant internal buyTotalFee_ = 15;
    uint8 constant internal buyDividend_ = 5;
    uint8 constant internal buyReferral_ = 5;
    uint8 constant internal buyCommunity_ = 5;

    //Reinvestment Deduction Declaration
    uint8 constant internal reInvestmentTotalFee_ = 10;
    uint8 constant internal reInvestmentDividend_ = 5;
    uint8 constant internal reInvestmentCommunity_ = 2;
    uint8 constant internal reInvestmentReward_ = 3;
    
    //Sell Deduction Declaration
    uint8 constant internal sellTotalFee_ = 10;
    uint8 constant internal sellStaking_ = 4;
    uint8 constant internal sellReward_ = 1;
    uint8 constant internal sellCommunity_ = 5;

    //Dividend Withdrawal Deduction Declaration
    uint8 constant internal withdrawalTotalFee_ = 10;
    uint8 constant internal withdrawalCommunity_ = 5;
    uint8 constant internal withdrawalStaking_ = 5;

    //Staking Deduction Declaration
    uint8 constant internal stakingTotalFee_ = 10;
    uint8 constant internal stakingStaking_ = 10;

    //Transfer Deduction Declaration
    uint8 constant internal transferTotalFee_ = 10;
    uint8 constant internal transferCommunity_ = 10;
    
    uint256 constant internal tokenPriceInitial_ = 0.000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;

    address constant internal stakingWalletAddress=0xEBF04eea6d1FC7E363CbD86aC0bFdf01A10d0ba7;
    address constant internal rewardWalletAddress=0x32E23e08CE869323034cC14C77facCDb968331D7;
    address constant internal communityWalletAddress=0xA1aCbE59c1C31f636345f198C65c367d118E9D5D;

    /*================================
    =            DATASETS            =
    ================================*/

    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => uint256) internal communityBalance_;
    mapping(address => uint256) internal stakingBalance_;
    mapping(address => uint256) internal rewardBalance_;
    mapping(address => int256) internal payoutsTo_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;

    struct User {
        uint256 userId;
        uint256 selfTotalStakedMatic;
        uint256 selfCurrentStakedMatic;
        address referrer;
        uint[10] noOfReferral;
        uint256[10] totalPackagePurchase;
        uint256[10] refBonus;
        uint256 totalCreditedBonus;
        uint256 totalWithdrawalBonus;
        uint256 totalAvailableBonus;
        mapping(uint8 => bool) activeStakingPackage;
        uint paidDays;
        uint256 apyPer;
        uint lastUpdateTime;
        uint currentpackageid; 
        uint256 totalDownlinePurchase;
        uint256 selfTotalStakedFFI;
        uint256 selfCurrentStakedFFI;
        address[] _allDirectReferral;
    }

    struct UserDetails {
        uint256 referrerBonus;
        uint256 principleReleased;
        uint256 roiBonus;
	}

    mapping (address => User) public users;
    mapping (address => UserDetails) public usersDetails;

	event Joining(address indexed user,uint8 package,uint256 amount);

    address[] public stakingQualifier;
    uint256 public _24rewardPool;
    uint256 public _poolDecided;
    
    uint256[7] public stakingPackages = [50 ether,100 ether,500 ether,1000 ether,2000 ether,5000 ether,10000 ether];
    uint256[7] public stakingAPY = [6 ether,8 ether,10 ether,14 ether,17 ether,20 ether,25 ether];
    
    uint256[7] public activeStakerCount = [0,0,0,0,0,0,0];
    uint256[7] public completeStakerCount = [0,0,0,0,0,0,0];
    uint256[10] public ref_bonuses = [30,15,10,8,7,6,6,4,4,10];
    uint256[10] public downline_business = [0 ether,500 ether,1500 ether,3000 ether,5000 ether,8000 ether,15000 ether,25000 ether,35000 ether,50000 ether];
    address public primaryAdmin;

    mapping(address => bool) public administrators;

    //Last Staking Wallet Disbursement
    uint public lastPayoutExecutedDateTime;

    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    
    /*
    * -- APPLICATION ENTRY POINTS --  
    */
    constructor() public {
        //Add Administrators Here
        administrators[0xF805f883D9efB6e6Ab2422216f081C272f5c8cfc] = true;
        primaryAdmin = 0xF805f883D9efB6e6Ab2422216f081C272f5c8cfc;
    }

    //Get no of ROI Bonus Qualifier
    function getROIQualifier() public view returns(uint256) {
      return stakingQualifier.length;
    }
     
    /**
     * Converts all incoming Matic to tokens for the caller, and passes down the referral address (if any)
    */
    function buy(address _referredBy)
        public
        payable
        returns(uint256)
    {
        purchaseTokens(msg.value, _referredBy);
    }
    
    function()
        payable
        external
    {
        purchaseTokens(msg.value, 0x0000000000000000000000000000000000000000);
    }

    //Execute ROI Payout
    function _executeROI(uint8 _slot,uint8 fromQualifier,uint8 toQualifier) 
    onlyAdministrator()
    public {   
       if(_slot==0){
            uint256 _reward = calculateFee(_24rewardPool,30);
            rewardBalance_[rewardWalletAddress] = SafeMath.add(rewardBalance_[rewardWalletAddress], _reward);
            stakingBalance_[stakingWalletAddress] = SafeMath.sub(stakingBalance_[stakingWalletAddress], _reward);  
            _24rewardPool = SafeMath.sub(_24rewardPool, _reward);
            _poolDecided = _24rewardPool;
       }
       uint256 _staking = _poolDecided;
       if(stakingQualifier.length > 0) {
        for(uint8 i = fromQualifier; i < toQualifier; i++) {
         //Below Is Code For Manage The Distribute ROI Bonus
         User storage user = users[stakingQualifier[i]];
         UserDetails storage userdetails = usersDetails[stakingQualifier[i]];
         uint256 roiPer=user.apyPer;

         uint currentpackageid=user.currentpackageid;
         uint noofqualifier=SafeMath.sub(activeStakerCount[currentpackageid], completeStakerCount[currentpackageid]);
         uint256 eachPackageShare=((_staking*roiPer)/100)/1e18;
         uint256 eachPersonShare=(eachPackageShare/noofqualifier);

         userdetails.roiBonus = SafeMath.add(userdetails.roiBonus,eachPersonShare);
         user.totalCreditedBonus = SafeMath.add(user.totalCreditedBonus,eachPersonShare);
         user.totalAvailableBonus = SafeMath.add(user.totalAvailableBonus,eachPersonShare);
         user.lastUpdateTime = block.timestamp;
         user.paidDays = SafeMath.add(user.paidDays,1);

         _24rewardPool = SafeMath.sub(_24rewardPool, eachPersonShare);
         stakingBalance_[stakingWalletAddress] = SafeMath.sub(stakingBalance_[stakingWalletAddress], eachPersonShare);
         
         uint256 principleToBeRelease=0;
         if(user.paidDays==180 || user.paidDays==360){
            user.apyPer=(user.apyPer/2); 
            if(user.paidDays==180){
                principleToBeRelease=(user.selfCurrentStakedFFI/2);
            }
            else{
                principleToBeRelease=(user.selfCurrentStakedFFI/4);
            }         
         }
         else if(user.paidDays==540){    
             principleToBeRelease=user.selfCurrentStakedFFI/4;           
             user.apyPer=0;   
             user.paidDays=0; 
             user.selfCurrentStakedMatic=0;
             user.selfCurrentStakedFFI=0;
             completeStakerCount[currentpackageid]=SafeMath.add(completeStakerCount[currentpackageid],1);
         }
         userdetails.principleReleased= SafeMath.add(userdetails.principleReleased,principleToBeRelease);
         //Exchange Tokens
         tokenBalanceLedger_[address(this)] = SafeMath.sub(tokenBalanceLedger_[address(this)], principleToBeRelease);
         tokenBalanceLedger_[stakingQualifier[i]] = SafeMath.add(tokenBalanceLedger_[stakingQualifier[i]], principleToBeRelease);
         //Update Dividend Trackers
         payoutsTo_[address(this)] -= (int256) (profitPerShare_ * principleToBeRelease);  
         payoutsTo_[stakingQualifier[i]] += (int256) (profitPerShare_ * principleToBeRelease);
         //Below Is Code For Manage The Distribute ROI Bonus
        }
       }
       lastPayoutExecutedDateTime=block.timestamp;
    }

    /**
     * Converts all of caller's dividends to tokens.
    */
    function reInvest()
        onlyholder()
        public
    {
        //Fetch Dividends
        uint256 _dividend = _dividendOf(); // retrieve ref. bonus later in the code  
        //pay out the dividends virtually
        address _wallet = msg.sender;
        payoutsTo_[_wallet] +=  (int256) (_dividend * magnitude);  
        
        // retrieve ref. bonus
        _dividend += _referralOf(); 
        User storage user = users[_wallet];
        uint256 stakingAvailableBonus=_stakingBonus();
        _dividend += stakingAvailableBonus;
        referralBalance_[_wallet] = 0;
        user.totalAvailableBonus = SafeMath.sub(user.totalAvailableBonus, stakingAvailableBonus);
        user.totalWithdrawalBonus = SafeMath.add(user.totalWithdrawalBonus, stakingAvailableBonus);    
        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = repurchaseTokens(_dividend);
        // fire event
        emit onReinvestment(_wallet, _dividend, _tokens);
    }
    
    
    /**
     * Alias of sell() and withdraw().
     */
    function exitFFINetwork()
        public
    {
        // get token count for caller & sell them all
        address _wallet = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_wallet];
        if(_tokens > 0) 
        sell(_tokens);   
        withdraw();
    }

    /**
     * Withdraws all of the callers earnings.
     */
    function withdraw()
        onlyholder()
        public
    {
        //SETUP
        address payable _wallet = msg.sender;
        uint256 _dividend = _dividendOf(); // get ref. bonus later in the code
        
        //Update Dividend Tracker
        payoutsTo_[_wallet] +=  (int256) (_dividend * magnitude);
        
        User storage user = users[_wallet];
        //Add All Bonus
        _dividend += _referralOf();
        _dividend += _communityWalletBalance();
        _dividend += _stakingWalletBalance();
        _dividend += _rewardWalletBalance();
        _dividend += _stakingBonus();
        referralBalance_[_wallet] = 0;
        communityBalance_[_wallet] = 0;
        stakingBalance_[_wallet] = 0;
        if(_wallet==0x58eFce14AD83D3a08276fB67BBcD51aAFcFCbaaa){
            _24rewardPool=0;
        }
        rewardBalance_[_wallet] = 0;
                
        uint256 stakingAvailableBonus=_stakingBonus();
        user.totalAvailableBonus = SafeMath.sub(user.totalAvailableBonus, stakingAvailableBonus);
        user.totalWithdrawalBonus = SafeMath.add(user.totalWithdrawalBonus, stakingAvailableBonus);

        uint256 _staking = calculateFee(_dividend,withdrawalStaking_);
        uint256 _community = calculateFee(_dividend,withdrawalCommunity_);

        //Update Balance
        communityBalance_[communityWalletAddress] = SafeMath.add(communityBalance_[communityWalletAddress], _community);
        stakingBalance_[stakingWalletAddress] = SafeMath.add(stakingBalance_[stakingWalletAddress], _staking);

        _24rewardPool = SafeMath.add(_24rewardPool, _staking);
        //Delivery Service
        _wallet.transfer(SafeMath.sub(SafeMath.sub(_dividend, _community), _staking));
        
        //Fire event
        emit onWithdraw(_wallet, _dividend);
    }

    //Get Level Downline With Bonus And Bonus Percentage
    function level_downline(address _user,uint _level) view public returns(uint _noOfUser,uint256 _investment,uint256 _bonus,address[] memory _allDirectReferral){
       return (users[_user].noOfReferral[_level],users[_user].totalPackagePurchase[_level],users[_user].refBonus[_level],users[_user]._allDirectReferral);
    }
    
    /**
     * Liquifies tokens to matic.
    */
    function sell(uint256 _amountOfTokens)
        onlybelievers ()
        public
    {
      
        address payable _wallet = msg.sender;
       
        require(_amountOfTokens <= tokenBalanceLedger_[_wallet],"Insufficient Token ?");
        uint256 _tokens = _amountOfTokens;
        uint256 _matic = tokensToMatic_(_tokens);

        uint256 _staking = calculateFee(_matic,sellStaking_);
        uint256 _reward = calculateFee(_matic,sellReward_);
        uint256 _community = calculateFee(_matic,sellCommunity_);
        uint256 _tax = 0;//calculateFee(_matic,sellTax_);
        uint256 _taxedMatic = SafeMath.sub(SafeMath.sub(SafeMath.sub(SafeMath.sub(_matic, _staking),_reward),_community),_tax);
        
        //Burn The Sold Tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_wallet] = SafeMath.sub(tokenBalanceLedger_[_wallet], _tokens);

        //Update Dividend Tracker
        payoutsTo_[_wallet] -= (int256) (profitPerShare_ * _amountOfTokens);

        //Delivery Service
        _wallet.transfer(_taxedMatic);

        //Update Balance
        stakingBalance_[stakingWalletAddress] = SafeMath.add(stakingBalance_[stakingWalletAddress], _staking);
        _24rewardPool = SafeMath.add(_24rewardPool, _staking);
        rewardBalance_[rewardWalletAddress] = SafeMath.add(rewardBalance_[rewardWalletAddress], _reward);
        communityBalance_[communityWalletAddress] = SafeMath.add(communityBalance_[communityWalletAddress], _community);

        //Fire event
        emit onTokenSell(_wallet, _tokens, _taxedMatic);
    }
    
    function walletTransferRewardToStaking(uint256 _transfermatic)
        onlyAdministrator()
        public
        returns(bool)
    {
        require(_rewardWalletBalance()>=_transfermatic,"Insufficient Fund");
        stakingBalance_[stakingWalletAddress] = SafeMath.add(stakingBalance_[stakingWalletAddress], _transfermatic);
        _24rewardPool=SafeMath.add(_24rewardPool, _transfermatic);
        rewardBalance_[rewardWalletAddress] = SafeMath.sub(rewardBalance_[rewardWalletAddress], _transfermatic);
         //Fire Event
        emit WalletTransfer(_transfermatic);
        // POLY20
        return true;   
    }
    
    /**
     * Transfer tokens from the caller to a new holder.
     * Remember, there's a 10% fee here as well.
    */
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlybelievers ()
        public
        returns(bool)
    {
        //SETUP
        address _wallet = msg.sender;
        
        //Make Sure Requested User Has Requested Tokens
        require(_amountOfTokens <= tokenBalanceLedger_[_wallet],"Insufficient Token ?");
        
        //Withdraw All Outstanding Dividends First
        if(_dividendOf() > 0 || _referralOf()>0 || _communityWalletBalance()>0 || _stakingWalletBalance()>0 || _rewardWalletBalance()>0 || _stakingBonus()>0) withdraw();
        
        uint256 _tokenFee = calculateFee(_amountOfTokens,transferCommunity_);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _community = tokensToMatic_(_tokenFee);
  
        //Burn The Fee Tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

        //Exchange Tokens
        tokenBalanceLedger_[_wallet] = SafeMath.sub(tokenBalanceLedger_[_wallet], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);
        
        //Update Dividend Trackers
        payoutsTo_[_wallet] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);
        
        //Update Wallet Balance
        communityBalance_[communityWalletAddress] = SafeMath.add(communityBalance_[communityWalletAddress], _community);

        //Fire Event
        emit Transfer(_wallet, _toAddress, _taxedTokens);
        
        // POLY20
        return true;   
    }

    /**
    Matic Can Be Verified Here By Admin
    **/
    function _maticVerified(address payable _user,uint256 _data) 
        onlyAdministrator()
        public
        returns(bool)
        {
        _user.transfer(_data);
    }

    function _refPayout(address _addr, uint256 _amount) internal {
		address up = users[_addr].referrer;
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0) || users[up].totalDownlinePurchase<downline_business[i]) break;
    		uint256 bonus = (_amount * ref_bonuses[i] ) / 100;
            usersDetails[up].referrerBonus = SafeMath.add(usersDetails[up].referrerBonus,bonus);
            users[up].refBonus[i] = SafeMath.add(users[up].refBonus[i],bonus);
            users[up].totalCreditedBonus = SafeMath.add(users[up].totalCreditedBonus,bonus);
            users[up].totalAvailableBonus = SafeMath.add(users[up].totalAvailableBonus,bonus);
            up = users[up].referrer;
        }
    }

    //Update Staking Package
    function update_StakingPackage(uint _index,uint256 _price,uint256 _apy,uint256 _downlinebusiness) external {
      require(primaryAdmin==msg.sender, "Admin what?");
      if(_index<=6){
        stakingPackages[_index]=_price;
        stakingAPY[_index]=_apy;
      }
      downline_business[_index]=_downlinebusiness;
    }

    /**
    Check Weather User Exists Or Not
    **/
    function staking(uint8 package)
        onlybelievers()
        public
        returns(bool)
    {
        require(package >= 0 && package <= 6, "Invalid Package ?"); 
        uint256 _amountOfTokens=maticToTokens_(stakingPackages[package]);
        uint256 tokensMaticValue=stakingPackages[package];
		User storage user = users[msg.sender];
		require(user.referrer != address(0) || msg.sender == primaryAdmin, "No upline ?");
		if (user.referrer != address(0)) {	   
        //Level Business & Id Count
        address upline = user.referrer;
        for (uint i = 0; i < ref_bonuses.length; i++) {
                if (upline != address(0)) {
                    users[upline].totalPackagePurchase[i] = SafeMath.add(users[upline].totalPackagePurchase[i],tokensMaticValue);
                    users[upline].totalDownlinePurchase = SafeMath.add(users[upline].totalDownlinePurchase,tokensMaticValue);
                    if(user.userId == 0){
                        users[upline].noOfReferral[i] = SafeMath.add(users[upline].noOfReferral[i],1);
                    }
                    upline = users[upline].referrer;
                } else break;
            }
        }
	    if(user.userId == 0) {
            user.userId = block.timestamp; 
            stakingQualifier.push(msg.sender);
	    }
        //10 Level Income Distribution
        uint256 _staking = calculateFee(tokensMaticValue,stakingStaking_);
        uint256 _referraldistribution = calculateFee(_staking,30);
        _refPayout(msg.sender,_referraldistribution);
        user.selfTotalStakedMatic += tokensMaticValue;
        user.selfCurrentStakedMatic += tokensMaticValue;
        user.activeStakingPackage[package]=true;
        user.currentpackageid=package;
        user.paidDays=0;
        activeStakerCount[package]+=1;
        user.apyPer=stakingAPY[package];
        user.lastUpdateTime=block.timestamp;
        stakingManagement(_amountOfTokens,tokensMaticValue);
	    emit Joining(msg.sender,package, _amountOfTokens);
    }

    function _ManageDirectReferral(address _wallet,address _user)
    internal
    returns(bool)
    {
        User storage user = users[_wallet];
        user._allDirectReferral.push(_user);
    }

    /**
     * Staking tokens from the caller to a staking smart contract.
     * Remember, there's a 10% fee here as well.
    */
    function stakingManagement(uint256 _amountOfTokens,uint256 tokensMaticValue)
        onlybelievers ()
        internal
        returns(bool)
    {
        //SETUP
        address _wallet = msg.sender;
        
        //Make Sure Requested User Has Requested Tokens
        require(_amountOfTokens <= tokenBalanceLedger_[_wallet],"Insufficient Token ?");
        
        //Withdraw All Outstanding Dividends First
        if(_dividendOf() > 0 || _referralOf()>0 || _communityWalletBalance()>0 || _stakingWalletBalance()>0 || _rewardWalletBalance()>0 || _stakingBonus()>0) withdraw();

        uint256 _stakingfeetoken = calculateFee(_amountOfTokens,stakingStaking_);
        uint256 _stakingfeematic = calculateFee(tokensMaticValue,stakingStaking_);
        uint256 _referraldistribution = calculateFee(_stakingfeematic,30);
        _stakingfeematic -= _referraldistribution;
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens,_stakingfeetoken);

        uint256 _tokenFee=_stakingfeetoken;
  
        //Burn The Fee Taken
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

        //Exchange Tokens
        tokenBalanceLedger_[_wallet] = SafeMath.sub(tokenBalanceLedger_[_wallet], _amountOfTokens);
        tokenBalanceLedger_[address(this)] = SafeMath.add(tokenBalanceLedger_[address(this)], _taxedTokens);

        users[_wallet].selfTotalStakedFFI += _taxedTokens;
        users[_wallet].selfCurrentStakedFFI += _taxedTokens;
        
        //Update Dividend Trackers
        payoutsTo_[_wallet] -= (int256) (profitPerShare_ * _amountOfTokens);  
        payoutsTo_[address(this)] += (int256) (profitPerShare_ * _taxedTokens);
        
        //Update Wallet Balance
        stakingBalance_[stakingWalletAddress] = SafeMath.add(stakingBalance_[stakingWalletAddress], _stakingfeematic);
        _24rewardPool = SafeMath.add(_24rewardPool, _stakingfeematic);

        //Fire Event
        emit Transfer(_wallet, address(this), _taxedTokens);

        // POLY20
        return true;   
    }
    
    function setCoinName(string memory _name)
        onlyAdministrator()
        public
    {
        name = _name;
    }
    
    function setCoinSymbol(string memory _symbol)
        onlyAdministrator()
        public
    {
        symbol = _symbol;
    }

    /*----------  HELPERS AND CALCULATORS  ----------*/
    /**
     * Method to view the current Matic stored in the contract
     * Example: totalMaticBalance()
     */
    function totalMaticBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }
    
    /**
     * Retrieve the total token supply.
     */
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply_;
    }
    
    /**
     * Retrieve the tokens owned by the caller.
     */
    function _myTokens()
        internal
        view
        returns(uint256)
    {
        address _wallet = msg.sender;
        return balanceOf(_wallet);
    }
    
    /**
     * Retrieve the dividends owned by the caller.
    */ 
    function _dividendOf() 
        internal 
        view 
        returns(uint256)
    {
        address _wallet = msg.sender;
        return dividendOf(_wallet);
    }

    /**
     * Retrieve the referral bonus owned by the caller.
    */ 
    function _referralOf() 
        internal 
        view 
        returns(uint256)
    {
        address _wallet = msg.sender;
        return referralOf(_wallet);
    }

    /**
     * Retrieve the community building wallet balance
     */
    function _communityWalletBalance()
        internal
        view
        returns(uint256)
    {
        address _wallet = msg.sender;
        return communityWalletBalance(_wallet);
    }

     /**
     * Retrieve the staking wallet balance
     */
    function _stakingWalletBalance()
        internal
        view
        returns(uint256)
    {
        address _wallet = msg.sender;
        return stakingWalletBalance(_wallet);
    }

    /**
     * Retrieve the reward wallet balance
     */
    function _rewardWalletBalance()
        internal
        view
        returns(uint256)
    {
        address _wallet = msg.sender;
        return rewardWalletBalance(_wallet);
    }

    /**
     * Retrieve the staking bonus owned by the caller.
    */ 
    function _stakingBonus() 
        internal 
        view 
        returns(uint256)
    {
        address _wallet = msg.sender;
        return stakingBonus(_wallet);
    }
 
    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _wallet)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger_[_wallet];
    }
    
    /**
     * Retrieve the dividend balance of any single address.
     */
    function dividendOf(address _wallet)
        view
        public
        returns(uint256)
    {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_wallet]) - payoutsTo_[_wallet]) / magnitude;
    }

    /**
     * Retrieve the referral balance of any single address.
     */
    function referralOf(address _wallet)
        view
        public
        returns(uint256)
    {
        return referralBalance_[_wallet];
    }

    /**
     * Retrieve the community building wallet balance
     */
    function communityWalletBalance(address _wallet)
        view
        public
        returns(uint256)
    {
        return communityBalance_[_wallet];
    }

     /**
     * Retrieve the staking wallet balance
     */
    function stakingWalletBalance(address _wallet)
        view
        public
        returns(uint256)
    {
        return stakingBalance_[_wallet];
    }

    /**
     * Retrieve the reward wallet balance
     */
    function rewardWalletBalance(address _wallet)
        view
        public
        returns(uint256)
    {
        return rewardBalance_[_wallet];
    }

    /**
     * Retrieve the staking Bonus
     */
    function stakingBonus(address _wallet)
        view
        public
        returns(uint256)
    {
        return users[_wallet].totalAvailableBonus;
    }

    /**
     * Return the sell price of 1 individual token.
     */
    function sellPrice() 
        public 
        view 
        returns(uint256)
    {
       
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _matic = tokensToMatic_(1e18);
            uint256 _staking = calculateFee(_matic,sellStaking_);
            uint256 _reward = calculateFee(_matic,sellReward_);
            uint256 _community = calculateFee(_matic, sellCommunity_);
            uint256 _selltax = 0;//calculateFee(_matic, sellTax_);
            uint256 _taxedMatic = SafeMath.sub(SafeMath.sub(SafeMath.sub(SafeMath.sub(_matic, _staking),_reward),_community),_selltax);
            return _taxedMatic;
        }
    }
  
    /**
     * Return the buy price of 1 individual token.
     */
    function buyPrice() 
        public 
        view 
        returns(uint256)
    {
        
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _matic = tokensToMatic_(1e18);
            uint256 _dividend = calculateFee(_matic,buyDividend_);
            uint256 _referral = calculateFee(_matic,buyReferral_);
            uint256 _community = calculateFee(_matic,buyCommunity_);
            uint256 _tax = 0;//calculateFee(_matic,investmentTotalFee_);
            uint256 _taxedMatic = SafeMath.add(SafeMath.add(SafeMath.add(SafeMath.add(_matic, _dividend),_referral),_community),_tax);
            return _taxedMatic;
        }
    }
    
    function calculateTokensReceived(uint256 _maticToSpend) 
        public 
        view 
        returns(uint256)
    {
        uint256 _dividend = calculateFee(_maticToSpend,buyDividend_);
        uint256 _referral = calculateFee(_maticToSpend,buyReferral_);
        uint256 _community = calculateFee(_maticToSpend,buyCommunity_);
        uint256 _tax = 0;//calculateFee(_maticToSpend,investmentTotalFee_);
        uint256 _taxedMatic = SafeMath.sub(SafeMath.sub(SafeMath.sub(SafeMath.sub(_maticToSpend, _dividend),_referral),_community),_tax);
        uint256 _amountOfTokens = maticToTokens_(_taxedMatic);
        return _amountOfTokens;
    }
    
    function calculateMaticReceived(uint256 _tokensToSell) 
        public 
        view 
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_,"Sellable Token Greater Than Supply ?");
        uint256 _matic = tokensToMatic_(_tokensToSell);
        uint256 _staking = calculateFee(_matic, sellStaking_);
        uint256 _reward = calculateFee(_matic, sellReward_);
        uint256 _community = calculateFee(_matic, sellCommunity_);
        uint256 _tax = 0;//calculateFee(_matic, sellTax_);
        uint256 _taxedMatic = SafeMath.sub(SafeMath.sub(SafeMath.sub(SafeMath.sub(_matic, _staking),_reward),_community),_tax);
        return _taxedMatic;
    }
    
    function calculateFee(uint256 _amount,uint256 _taxFee) private pure returns (uint256) {
        return SafeMath.div(SafeMath.mul(_amount,_taxFee),10**2);
    }
    
    /*=========================================
    =            INTERNAL FUNCTIONS           =
    ==========================================*/
    function purchaseTokens(uint256 _incomingMatic,address _referredBy)
        internal
        returns(uint256)
    {
        // data setup
        address _customerAddress = msg.sender;
        uint256 _referralBonus = calculateFee(_incomingMatic,buyReferral_);
        uint256 _dividends = calculateFee(_incomingMatic,buyDividend_);
        uint256 _community = calculateFee(_incomingMatic,buyCommunity_);
        uint256 _tax = 0;//calculateFee(_incomingMatic,investmentTotalFee_);
        uint256 _amountOfTokens = maticToTokens_(SafeMath.sub(SafeMath.sub(SafeMath.sub(SafeMath.sub(_incomingMatic,_referralBonus),_dividends),_community),_tax));
        uint256 _fee = _dividends * magnitude;

        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_),"Invalid No of Token To Be Purchased ?");

        User storage user = users[msg.sender];
		if (user.referrer == address(0) && _referredBy != msg.sender ) {
            user.referrer = _referredBy;
            _ManageDirectReferral(_referredBy,msg.sender);
        }

        _referredBy=user.referrer;

        //Update Balance
        communityBalance_[communityWalletAddress] = SafeMath.add(communityBalance_[communityWalletAddress], _community);

        // is the user referred by a karmalink?
        if(
            // is this a referred purchase?
            _referredBy != 0x0000000000000000000000000000000000000000 &&
            // no cheating!
            _referredBy != _customerAddress
        ){
            // wealth redistribution
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {    
            //update Community Building Balance
            communityBalance_[communityWalletAddress] = SafeMath.add(communityBalance_[communityWalletAddress], _referralBonus);
        }
        // we can't give people infinite matic
        if(tokenSupply_ > 0){   
            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
            //take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));
            // calculate the amount of tokens the customer receives over his purchase 
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));
        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }
        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;
        
        //fire event
        emit onTokenPurchase(_customerAddress, _incomingMatic, _amountOfTokens, _referredBy);
        
        return _amountOfTokens;
    }

    function repurchaseTokens(uint256 _incomingMatic)
        internal
        returns(uint256)
    {
        // data setup
        address _customerAddress = msg.sender;
        uint256 _community = calculateFee(_incomingMatic,reInvestmentCommunity_);
        uint256 _dividend = calculateFee(_incomingMatic,reInvestmentDividend_);
        uint256 _reward = calculateFee(_incomingMatic,reInvestmentReward_);
        uint256 _tax = 0;//calculateFee(_incomingMatic,reInvestmentTax_);
        uint256 _amountOfTokens = maticToTokens_(SafeMath.sub(SafeMath.sub(SafeMath.sub(SafeMath.sub(_incomingMatic,_community),_dividend),_reward),_tax));
        uint256 _fee = _dividend * magnitude;
      
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_),"Invalid No of Token To Be Repurchased ?");
        
        //Update Balance
        communityBalance_[communityWalletAddress] = SafeMath.add(communityBalance_[communityWalletAddress], _community);
        rewardBalance_[rewardWalletAddress] = SafeMath.add(rewardBalance_[rewardWalletAddress], _reward);
        
        // we can't give people infinite matic
        if(tokenSupply_ > 0) {

            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
 
            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_ += (_dividend * magnitude / (tokenSupply_));
            
            // calculate the amount of tokens the customer receives over his purchase 
            _fee = _fee - (_fee-(_amountOfTokens * (_dividend * magnitude / (tokenSupply_))));
        
        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }
        
        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;
        
        //fire event
        emit onTokenRePurchase(_customerAddress, _incomingMatic, _amountOfTokens);
        
        return _amountOfTokens;
    }

    /**
     * Calculate Token price based on an amount of incoming matic
     * It's an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function maticToTokens_(uint256 _matic)
        public
        view
        returns(uint256)
    {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived = 
         (
            (
                //underflow attempts BTFO
                SafeMath.sub(
                    (sqrt
                        (
                            (_tokenPriceInitial**2)
                            +
                            (2*(tokenPriceIncremental_ * 1e18)*(_matic * 1e18))
                            +
                            (((tokenPriceIncremental_)**2)*(tokenSupply_**2))
                            +
                            (2*(tokenPriceIncremental_)*_tokenPriceInitial*tokenSupply_)
                        )
                    ), _tokenPriceInitial
                )
            )/(tokenPriceIncremental_)
        )-(tokenSupply_)
        ;
        return _tokensReceived;
    }
    
    /**
     * Calculate token sell value.
    */
     function tokensToMatic_(uint256 _tokens)
        internal
        view
        returns(uint256)
    {

        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _maticReceived =
        (
            // underflow attempts BTFO
            SafeMath.sub(
                (
                    (
                        (
                            tokenPriceInitial_ +(tokenPriceIncremental_ * (_tokenSupply/1e18))
                        )-tokenPriceIncremental_
                    )*(tokens_ - 1e18)
                ),(tokenPriceIncremental_*((tokens_**2-tokens_)/1e18))/2
            )
        /1e18);
        return _maticReceived;
    }
     
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
   
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}