/**
 *Submitted for verification at polygonscan.com on 2023-04-22
*/

/**
 *Submitted for verification at polygonscan.com on 2022-02-03
*/

pragma solidity ^0.4.20;

/*

The new blockchain technology facilitates peer-to-peer transactions without any intermediary 
such as a bank or governing body. Keeping the user's information anonymous, the blockchain 
validates and keeps a permanent public record of all transactions.


*/

contract FFINetwork {
    /*=================================
    =            MODIFIERS            =
    =================================*/

    // only people with tokens
    modifier onlybelievers () {
        require(myTokens() > 0);
        _;
    }
    
    // only people with profits
    modifier onlyholder() {
        require(myDividends() > 0 || myReferralBonus()>0 || myCommmunityBonus()>0);
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
    
    // PLOY20

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

    uint8 constant internal investmentTotalFee_ = 15;
    uint8 constant internal investmentDividend_ = 10;
    uint8 constant internal investmentReferral_ = 5;
    //uint8 constant internal investmentTax_ = 1;

    uint8 constant internal reInvestmentTotalFee_ = 10;
    uint8 constant internal reInvestmentDividend_ = 8;
    uint8 constant internal reInvestmentCommunity_ = 2;
    //uint8 constant internal reInvestmentTax_ = 1;

    uint8 constant internal sellTotalFee_ = 10;
    uint8 constant internal sellDividend_ = 8;
    uint8 constant internal sellCommunity_ = 2;
    //uint8 constant internal sellTax_ = 1;

    uint8 constant internal withdrawalCommunity_ = 10;

    uint256 constant internal tokenPriceInitial_ = 0.000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;

    address constant internal comminityBuildingAddress=0xA1aCbE59c1C31f636345f198C65c367d118E9D5D;

    /*================================
    =            DATASETS            =
    ================================*/

    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => uint256) internal communityBuildingBalance_;
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
    function FFINetwork() public
    {
        // add administrators here
        administrators[keccak256(0xA1aCbE59c1C31f636345f198C65c367d118E9D5D)] = true;
		               
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
        uint256 _dividends = myDividends(); // retrieve ref. bonus later in the code
        
        // pay out the dividends virtually
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        
        // retrieve ref. bonus
        _dividends += referralBalance_[_customerAddress];
        _dividends += communityBuildingBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        communityBuildingBalance_[_customerAddress]=0;
        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = repurchaseTokens(_dividends, 0x0000000000000000000000000000000000000000);

        // fire event
        onReinvestment(_customerAddress, _dividends, _tokens);
    }
    
    /**
     * Alias of sell() and withdraw().
     */
    function exitFFINetwork()
        public
    {
        // get token count for caller & sell them all
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
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
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(); // get ref. bonus later in the code
        
        // update dividend tracker
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        
        // add ref. bonus
        _dividends += referralBalance_[_customerAddress];
        _dividends += communityBuildingBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        communityBuildingBalance_[_customerAddress]=0;

        uint256 _communitydividends = calculateFee(_dividends,withdrawalCommunity_);

        //update Community Building Balance
        communityBuildingBalance_[comminityBuildingAddress] = SafeMath.add(communityBuildingBalance_[comminityBuildingAddress], _communitydividends);

        //delivery service
        _customerAddress.transfer(SafeMath.sub(_dividends, _communitydividends));
        
        // fire event
        onWithdraw(_customerAddress, _communitydividends);
    }
    
    /**
     * Liquifies tokens to matic.
     */
    function sell(uint256 _amountOfTokens)
        onlybelievers ()
        public
    {
      
        address _customerAddress = msg.sender;
       
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _matic = tokensToMatic_(_tokens);

        uint256 _dividends = calculateFee(_matic,sellDividend_);
        uint256 _communitydividends = calculateFee(_matic,sellCommunity_);
        uint256 _tax = 0;//calculateFee(_matic,sellTax_);
        uint256 _taxedMatic = SafeMath.sub(SafeMath.sub(SafeMath.sub(_matic, _dividends),_communitydividends),_tax);
        
        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        
        // update dividends tracker
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedMatic * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;       
        
        // dividing by zero is a bad idea
        if (tokenSupply_ > 0) {
            // update the amount of dividends per token
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

        //update Community Building Balance
        communityBuildingBalance_[comminityBuildingAddress] = SafeMath.add(communityBuildingBalance_[comminityBuildingAddress], _communitydividends);

        // fire event
        onTokenSell(_customerAddress, _tokens, _taxedMatic);
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
        // setup
        address _customerAddress = msg.sender;
        
        // make sure we have the requested tokens
     
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
        // withdraw all outstanding dividends first
        if(myDividends() > 0 || myReferralBonus()>0 || myCommmunityBonus()>0) withdraw();
        
        // liquify 10% of the tokens that are transfered
        // these are dispersed to shareholders
        uint256 _tokenFee = calculateFee(_amountOfTokens,withdrawalCommunity_);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _communitydividends = tokensToMatic_(_tokenFee);
  
        // burn the fee tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);
        
        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);
        
        //update Community Building Balance
        communityBuildingBalance_[comminityBuildingAddress] = SafeMath.add(communityBuildingBalance_[comminityBuildingAddress], _communitydividends);

        // fire event
        Transfer(_customerAddress, _toAddress, _taxedTokens);
        
        // POLY20
        return true;
       
    }
    
    
    function setCoinName(string _name)
        onlyAdministrator()
        public
    {
        name = _name;
    }
    
   
    function setCoinSymbol(string _symbol)
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
        return this.balance;
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
    function myTokens()
        internal
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }
    
    /**
     * Retrieve the dividends owned by the caller.
       */ 
    function myDividends() 
        internal 
        view 
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return dividendsOf(_customerAddress);
    }

    /**
     * Retrieve the referral bonus owned by the caller.
       */ 
    function myReferralBonus() 
        internal 
        view 
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return referralBalance_[_customerAddress];
    }

    /**
     * Retrieve the community building wallet balance owned by the caller.
    */ 
    function myCommmunityBonus() 
        internal 
        view 
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return communityBuildingBalance_[_customerAddress];
    }
    
    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }
    
    /**
     * Retrieve the dividend balance of any single address.
     */
    function dividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

    /**
     * Retrieve the referral balance of any single address.
     */
    function referralOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return referralBalance_[_customerAddress];
    }

    /**
     * Retrieve the community building balance of any single address.
     */
    function communityBuildingOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return communityBuildingBalance_[_customerAddress];
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
            uint256 _dividends = calculateFee(_matic,sellDividend_);
            uint256 _communitybuilding = calculateFee(_matic, sellCommunity_);
            uint256 _selltax = 0;//calculateFee(_matic, sellTax_);
            uint256 _taxedMatic = SafeMath.sub(SafeMath.sub(SafeMath.sub(_matic, _dividends),_communitybuilding),_selltax);
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
            uint256 _dividends = calculateFee(_matic,investmentDividend_);
            uint256 _communitybuilding = calculateFee(_matic,investmentReferral_);
            uint256 _tax = 0;//calculateFee(_matic,investmentTax_);
            uint256 _taxedMatic = SafeMath.add(SafeMath.add(SafeMath.add(_matic, _dividends),_communitybuilding),_tax);
            return _taxedMatic;
        }
    }
    
   
    function calculateTokensReceived(uint256 _maticToSpend) 
        public 
        view 
        returns(uint256)
    {
        uint256 _dividends = calculateFee(_maticToSpend,investmentDividend_);
        uint256 _comminityBuilding = calculateFee(_maticToSpend,investmentReferral_);
        uint256 _tax = 0;//calculateFee(_maticToSpend,investmentTax_);
        uint256 _taxedMatic = SafeMath.sub(SafeMath.sub(SafeMath.sub(_maticToSpend, _dividends),_comminityBuilding),_tax);
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
        uint256 _dividends = calculateFee(_matic, sellDividend_);
        uint256 _communityBuilding = calculateFee(_matic, sellCommunity_);
        uint256 _tax = 0;//calculateFee(_matic, sellTax_);
        uint256 _taxedMatic = SafeMath.sub(SafeMath.sub(SafeMath.sub(_matic, _dividends),_communityBuilding),_tax);
        return _taxedMatic;
    }
    
    function calculateFee(uint256 _amount,uint256 _taxFee) private view returns (uint256) {
        return SafeMath.div(SafeMath.mul(_amount,_taxFee),10**2);
    }
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function purchaseTokens(uint256 _incomingMatic, address _referredBy)
        internal
        returns(uint256)
    {
        // data setup
        address _customerAddress = msg.sender;
        uint256 _referralBonus = calculateFee(_incomingMatic,investmentReferral_);
        uint256 _dividends = calculateFee(_incomingMatic,investmentDividend_);
        uint256 _tax = 0;//calculateFee(_incomingMatic,investmentTax_);
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
            communityBuildingBalance_[comminityBuildingAddress] = SafeMath.add(communityBuildingBalance_[comminityBuildingAddress], _referralBonus);
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
        uint256 _communityBuildingBonus = calculateFee(_incomingMatic,reInvestmentCommunity_);
        uint256 _dividends = calculateFee(_incomingMatic,reInvestmentDividend_);
        uint256 _tax = 0;//calculateFee(_incomingMatic,reInvestmentTax_);
        uint256 _amountOfTokens = maticToTokens_(SafeMath.sub(SafeMath.sub(SafeMath.sub(_incomingMatic,_communityBuildingBonus),_dividends),_tax));
        uint256 _fee = _dividends * magnitude;
      
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));

        // is the user referred by a karmalink?
        if(
            // is this a referred purchase?
            _referredBy != 0x0000000000000000000000000000000000000000 &&

            // no cheating!
            _referredBy != _customerAddress
        ){
            //update Community Building Balance
            communityBuildingBalance_[comminityBuildingAddress] = SafeMath.add(communityBuildingBalance_[comminityBuildingAddress], _communityBuildingBonus);
        } else {
            
            //update Community Building Balance
            communityBuildingBalance_[comminityBuildingAddress] = SafeMath.add(communityBuildingBalance_[comminityBuildingAddress], _communityBuildingBonus);
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