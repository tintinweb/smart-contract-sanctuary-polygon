/**
 *Submitted for verification at polygonscan.com on 2023-04-21
*/

/**
 *Submitted for verification at polygonscan.com on 2023-04-20
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
        require(_dividendOf() > 0 || _referralOf()>0 || _communityWalletBalance()>0  || _stakingBonus()>0,"No Divident Or No Other Income ?");
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
        uint256 tokensBurned
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


    
    //Sell Deduction Declaration
    uint8 constant internal sellTotalFee_ = 3;
    uint8 constant internal sellStaking_ = 3;
    
    //Staking Deduction Declaration
    uint8 constant internal stakingTotalFee_ = 10;
    uint8 constant internal stakingStaking_ = 10;

    //Transfer Deduction Declaration
    uint8 constant internal transferTotalFee_ = 3;
    uint8 constant internal transferCommunity_ = 3;
    
    uint256 constant internal tokenPriceInitial_ = 0.000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;

    address constant internal communityWalletAddress=0x92cc5e4F1e4A8B1C14896b4a7EfFAbE39666Cada;

    /*================================
    =            DATASETS            =
    ================================*/

    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => uint256) internal communityBalance_;
    mapping(address => int256) internal payoutsTo_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;

    struct User {
        uint256 userId;
        uint256 selfTotalPackagePurchase;
        uint256 selfCurrentPackagePurchase;
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
    }

    mapping (address => User) public users;
	event Joining(address indexed user,uint8 package,uint256 amount);


    
    address public primaryAdmin;

    mapping(address => bool) public administrators;

    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    
    /*
    * -- APPLICATION ENTRY POINTS --  
    */
    constructor() public {
        //Add Administrators Here
        administrators[0x18c04e5D6e91C646b3eF447d812E43A368441600] = true;
        primaryAdmin = 0x18c04e5D6e91C646b3eF447d812E43A368441600;
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

    
  
    function sell(uint256 _amountOfTokens)
        onlybelievers ()
        public
    {
      
        address payable _wallet = msg.sender;
       
        require(_amountOfTokens <= tokenBalanceLedger_[_wallet],"Insufficient Token ?");
        uint256 _tokens = _amountOfTokens;
        uint256 _matic = tokensToMatic_(_tokens);

        uint256 _tax = 0;//calculateFee(_matic,sellTax_);
        
        //Burn The Sold Tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_wallet] = SafeMath.sub(tokenBalanceLedger_[_wallet], _tokens);

        //Fire event
        emit onTokenSell(_wallet, _tokens);
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
            uint256 _selltax = 0;//calculateFee(_matic, sellTax_);
            uint256 _taxedMatic = SafeMath.sub(SafeMath.sub(_matic, _staking),_selltax);
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
        uint256 _tax = 0;//calculateFee(_matic, sellTax_);
        uint256 _taxedMatic = SafeMath.sub(SafeMath.sub(_matic, _staking),_tax);

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
        }

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
        
        // fire event
        emit onTokenPurchase(_customerAddress, _incomingMatic, _amountOfTokens, _referredBy);
        
        return _amountOfTokens;
    }

   
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