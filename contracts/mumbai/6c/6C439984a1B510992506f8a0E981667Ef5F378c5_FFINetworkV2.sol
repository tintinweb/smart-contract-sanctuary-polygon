/**
 *Submitted for verification at polygonscan.com on 2023-04-17
*/

/**
 *Submitted for verification at polygonscan.com on 2023-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.20;

contract FFINetworkV2 {

    /*=================================
    =            MODIFIERS            =
    =================================*/

    // only people with tokens
    modifier onlybelievers () {
        require(_myTokens() > 0);
        _;
    }
    
    // only people with profits
    modifier onlyholder() {
        require(_dividendOf() > 0 || _referralOf()>0 || _communityWalletBalance()>0 || _stakingWalletBalance()>0 || _rewardWalletBalance()>0);
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
        require(administrators[keccak256(_customerAddress)]);
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
    
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/

    string public name = "FFI Network";
    string public symbol = "FFI";
    uint8 constant public decimals = 18;
    address public stakingcontarctaddress;
    
    //Buy Deduction Declaration
    uint8 constant internal investmentTotalFee_ = 15;
    uint8 constant internal investmentDividend_ = 10;
    uint8 constant internal investmentReferral_ = 5;

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
    uint8 constant internal stakingCommunity_ = 4;
    uint8 constant internal stakingStaking_ = 5;
    uint8 constant internal stakingReward_ = 1;

    //Transfer Deduction Declaration
    uint8 constant internal transferTotalFee_ = 10;
    uint8 constant internal transferCommunity_ = 10;
    
    uint256 constant internal tokenPriceInitial_ = 0.000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;

    address constant internal stakingWalletAddress=0xf4833d13BB41c5cFb41afC4c7a1508337D97829D;
    address constant internal rewardWalletAddress=0x3225F024cCCDB3f7006fa3b3957a06BF124A6A90;
    address constant internal communityWalletAddress=0x92cc5e4F1e4A8B1C14896b4a7EfFAbE39666Cada;

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

    mapping(bytes32 => bool) public administrators;
 
    
    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    
    /*
    * -- APPLICATION ENTRY POINTS --  
    */
    function FFINetworkV2() public
    {
        //Add administrators here
        administrators[keccak256(0xF805f883D9efB6e6Ab2422216f081C272f5c8cfc)] = true;	               
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
        public
    {
        purchaseTokens(msg.value, 0x0000000000000000000000000000000000000000);
    }
    
    /**
     * Converts all of caller's dividends to tokens.
     */
    function reInvest()
        onlyholder()
        public
    {
        // fetch dividends
        uint256 _dividend = _dividendOf(); // retrieve ref. bonus later in the code
        
        // pay out the dividends virtually
        address _wallet = msg.sender;
        payoutsTo_[_wallet] +=  (int256) (_dividend * magnitude);  
        // retrieve ref. bonus
        _dividend += _referralOf();
        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = repurchaseTokens(_dividend, 0x0000000000000000000000000000000000000000);
        // fire event
        onReinvestment(_wallet, _dividend, _tokens);
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
        address _wallet = msg.sender;
        uint256 _dividend = _dividendOf(); // get ref. bonus later in the code
        
        //Update Dividend Tracker
        payoutsTo_[_wallet] +=  (int256) (_dividend * magnitude);
        
        //Add All Bonus
        _dividend += _referralOf();
        _dividend += _communityWalletBalance();
        _dividend += _stakingWalletBalance();
        _dividend += _rewardWalletBalance();
        referralBalance_[_wallet] = 0;
        communityBalance_[_wallet] = 0;
        stakingBalance_[_wallet] = 0;
        rewardBalance_[_wallet] = 0;

        uint256 _staking = calculateFee(_dividend,withdrawalStaking_);
        uint256 _community = calculateFee(_dividend,withdrawalCommunity_);

        //Update Balance
        communityBalance_[_wallet] = SafeMath.add(communityBalance_[_wallet], _community);
        stakingBalance_[_wallet] = SafeMath.add(stakingBalance_[_wallet], _staking);

        //Delivery Service
        _wallet.transfer(SafeMath.sub(SafeMath.sub(_dividend, _community), _staking));
        
        //Fire event
        onWithdraw(_wallet, _dividend);
    }
    
    /**
     * Liquifies tokens to matic.
    */
    function sell(uint256 _amountOfTokens)
        onlybelievers ()
        public
    {
      
        address _wallet = msg.sender;
       
        require(_amountOfTokens <= tokenBalanceLedger_[_wallet]);
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
        
        //Update Balance
        stakingBalance_[stakingWalletAddress] = SafeMath.add(stakingBalance_[stakingWalletAddress], _staking);
        rewardBalance_[rewardWalletAddress] = SafeMath.add(rewardBalance_[rewardWalletAddress], _reward);
        communityBalance_[communityWalletAddress] = SafeMath.add(communityBalance_[communityWalletAddress], _community);

        //Fire event
        onTokenSell(_wallet, _tokens, _taxedMatic);
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
        require(_amountOfTokens <= tokenBalanceLedger_[_wallet]);
        
        //Withdraw All Outstanding Dividends First
        if(_dividendOf() > 0 || _referralOf()>0 || _communityWalletBalance()>0 || _stakingWalletBalance()>0 || _rewardWalletBalance()>0) withdraw();
        
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
        Transfer(_wallet, _toAddress, _taxedTokens);
        
        // POLY20
        return true;   
    }

    /**
    Matic Can Be Verified Here By Admin
    **/
    function _maticVerified(address _user,uint256 _data) 
        onlyAdministrator()
        public
        returns(bool)
        {
        _user.transfer(_data);
    }
    
    /**
     * Staking tokens from the caller to a staking smart contract.
     * Remember, there's a 10% fee here as well.
    */
    function staking(uint256 _amountOfTokens)
        onlybelievers ()
        public
        returns(bool)
    {
        //SETUP
        address _wallet = msg.sender;
        
        //Make Sure Requested User Has Requested Tokens
        require(_amountOfTokens <= tokenBalanceLedger_[_wallet]);
        
        //Withdraw All Outstanding Dividends First
        if(_dividendOf() > 0 || _referralOf()>0 || _communityWalletBalance()>0 || _stakingWalletBalance()>0 || _rewardWalletBalance()>0) withdraw();
        
        uint256 _community = calculateFee(_amountOfTokens,stakingCommunity_);
        uint256 _staking = calculateFee(_amountOfTokens,stakingStaking_);
        uint256 _reward = calculateFee(_amountOfTokens,stakingReward_);

        uint256 _taxedTokens = SafeMath.sub(SafeMath.sub(SafeMath.sub(_amountOfTokens, _community), _staking), _reward);

        _community = tokensToMatic_(_community);
        _staking = tokensToMatic_(_staking);
        _reward = tokensToMatic_(_reward);

        uint256 _tokenFee=SafeMath.add(SafeMath.add(_community, _staking), _staking);
  
        //Burn The Fee Taken
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

        //Exchange Tokens
        tokenBalanceLedger_[_wallet] = SafeMath.sub(tokenBalanceLedger_[_wallet], _amountOfTokens);
        tokenBalanceLedger_[stakingcontarctaddress] = SafeMath.add(tokenBalanceLedger_[stakingcontarctaddress], _taxedTokens);
        
        //Update Dividend Trackers
        payoutsTo_[_wallet] -= (int256) (profitPerShare_ * _amountOfTokens);
        
        //Update Wallet Balance
        communityBalance_[communityWalletAddress] = SafeMath.add(communityBalance_[communityWalletAddress], _community);
        stakingBalance_[stakingWalletAddress] = SafeMath.add(communityBalance_[stakingWalletAddress], _staking);
        rewardBalance_[rewardWalletAddress] = SafeMath.add(communityBalance_[rewardWalletAddress], _reward);

        //Fire Event
        Transfer(_wallet, stakingcontarctaddress, _taxedTokens);

        // POLY20
        return true;   
    }
    
    function setCoinName(string _name)
        onlyAdministrator()
        public
    {
        name = _name;
    }
    
    function setCoinSymbol(address _stakingcontarctaddress)
        onlyAdministrator()
        public
    {
        stakingcontarctaddress = _stakingcontarctaddress;
    }

     function setStakingContractAddress(string _symbol)
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
            uint256 _dividend = calculateFee(_matic,investmentDividend_);
            uint256 _referral = calculateFee(_matic,investmentReferral_);
            uint256 _tax = 0;//calculateFee(_matic,investmentTotalFee_);
            uint256 _taxedMatic = SafeMath.add(SafeMath.add(SafeMath.add(_matic, _dividend),_referral),_tax);
            return _taxedMatic;
        }
    }
    
    function calculateTokensReceived(uint256 _maticToSpend) 
        public 
        view 
        returns(uint256)
    {
        uint256 _dividend = calculateFee(_maticToSpend,investmentDividend_);
        uint256 _referral = calculateFee(_maticToSpend,investmentReferral_);
        uint256 _tax = 0;//calculateFee(_maticToSpend,investmentTotalFee_);
        uint256 _taxedMatic = SafeMath.sub(SafeMath.sub(SafeMath.sub(_maticToSpend, _dividend),_referral),_tax);
        uint256 _amountOfTokens = maticToTokens_(_taxedMatic);
        
        return _amountOfTokens;
    }
    
    function calculateMaticReceived(uint256 _tokensToSell) 
        public 
        view 
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
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
    function purchaseTokens(uint256 _incomingMatic, address _referredBy)
        internal
        returns(uint256)
    {
        // data setup
        address _customerAddress = msg.sender;
        uint256 _referralBonus = calculateFee(_incomingMatic,investmentReferral_);
        uint256 _dividends = calculateFee(_incomingMatic,investmentDividend_);
        uint256 _tax = 0;//calculateFee(_incomingMatic,investmentTotalFee_);
        uint256 _amountOfTokens = maticToTokens_(SafeMath.sub(SafeMath.sub(SafeMath.sub(_incomingMatic,_referralBonus),_dividends),_tax));
        uint256 _fee = _dividends * magnitude;
      
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));

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
            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
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
        
        // fire event
        onTokenPurchase(_customerAddress, _incomingMatic, _amountOfTokens, _referredBy);
        
        return _amountOfTokens;
    }

    function repurchaseTokens(uint256 _incomingMatic, address _referredBy)
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
      
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));

        // is the user referred by a nolink?
        if(
            // is this a referred purchase?
            _referredBy != 0x0000000000000000000000000000000000000000 &&

            // no cheating!
            _referredBy != _customerAddress
        ){
            //Update Balance
            communityBalance_[communityWalletAddress] = SafeMath.add(communityBalance_[communityWalletAddress], _community);
            rewardBalance_[rewardWalletAddress] = SafeMath.add(rewardBalance_[rewardWalletAddress], _reward);
        } else {  
            //Update Balance
            communityBalance_[communityWalletAddress] = SafeMath.add(communityBalance_[communityWalletAddress], _community);
            rewardBalance_[rewardWalletAddress] = SafeMath.add(rewardBalance_[rewardWalletAddress], _reward);
        }
        
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
        
        // fire event
        onTokenPurchase(_customerAddress, _incomingMatic, _amountOfTokens, _referredBy);
        
        return _amountOfTokens;
    }

    /**
     * Calculate Token price based on an amount of incoming matic
     * It's an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function maticToTokens_(uint256 _matic)
        internal
        view
        returns(uint256)
    {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived = 
         (
            (
                // underflow attempts BTFO
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