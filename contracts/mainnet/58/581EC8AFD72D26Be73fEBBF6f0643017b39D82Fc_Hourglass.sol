/**
 *Submitted for verification at polygonscan.com on 2022-08-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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
        uint256 c = a / b;
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

contract Hourglass {

    /*=================================
    =            MODIFIERS            =
    =================================*/

    // only people with tokens
    modifier onlyHolders() {
        require(myTokens() > 0);
        _;
    }
    
    // only people with profits
    modifier onlyStronghands() {
        require(myDividends(true) > 0);
        _;
    }
    
    /*==============================
    =            EVENTS            =
    ==============================*/
    event onDeposit(address indexed addr, uint256 incomingEthereum, uint256 tokensMinted, address indexed referredBy);
    event onWithdraw(address indexed addr, uint256 tokensBurned, uint256 ethereumEarned);
    event onCompound(address indexed addr, uint256 ethereumReinvested, uint256 tokensMinted);
    event onHarvest(address indexed addr, uint256 ethereumWithdrawn);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "Stronghands MATIC3D";
    string public symbol = "MATIC3D";

    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee_ = 10;

    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;
    
   /*================================
    =            DATASETS            =
    ================================*/

    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;

    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    
    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    
    constructor() public {

    }
    
    receive() payable external {
        purchaseTokens(msg.value, address(0));
    }

    function deposit(address _referredBy) public payable returns(uint256) {
        purchaseTokens(msg.value, _referredBy);
    }

    function withdraw(uint256 _amountOfTokens) onlyHolders() public {
        
        // setup data
        address _addr = msg.sender;
        // russian hackers BTFO
        require(_amountOfTokens <= tokenBalanceLedger_[_addr]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        
        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_addr] = SafeMath.sub(tokenBalanceLedger_[_addr], _tokens);
        
        // update dividends tracker
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_addr] -= _updatedPayouts;       
        
        // dividing by zero is a bad idea
        if (tokenSupply_ > 0) {
            // update the amount of dividends per token
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }
        
        // fire event
        emit onWithdraw(_addr, _tokens, _taxedEthereum);
    }

    function compound() onlyStronghands() public {
        
        // fetch dividends
        uint256 _dividends = myDividends(false); // retrieve ref. bonus later in the code
        
        // pay out the dividends virtually
        address _addr = msg.sender;
        payoutsTo_[_addr] +=  (int256) (_dividends * magnitude);
        
        // retrieve ref. bonus
        _dividends += referralBalance_[_addr];
        referralBalance_[_addr] = 0;
        
        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = purchaseTokens(_dividends, address(0));
        
        // fire event
        emit onCompound(_addr, _dividends, _tokens);
    }

    function harvest() onlyStronghands() public {
        // setup data
        address payable _addr = msg.sender;
        uint256 _dividends = myDividends(false); // get ref. bonus later in the code
        
        // update dividend tracker
        payoutsTo_[_addr] +=  (int256) (_dividends * magnitude);
        
        // add ref. bonus
        _dividends += referralBalance_[_addr];
        referralBalance_[_addr] = 0;
        
        // lambo delivery service
        _addr.transfer(_dividends);
        
        // fire event
        emit onHarvest(_addr, _dividends);
    }

    function exit() public {
        // get token count for caller & sell them all
        address _addr = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_addr];
        if(_tokens > 0) withdraw(_tokens);
        
        // lambo delivery service
        harvest();
    }
    
    function transfer(address _toAddress, uint256 _amountOfTokens) onlyHolders() public returns(bool) {
        
        // cant send to 0 address
        require(_toAddress != address(0));
        // setup
        address _addr = msg.sender;

        // make sure we have the requested tokens
        require(_amountOfTokens <= tokenBalanceLedger_[_addr]);

        // withdraw all outstanding dividends first
        if(myDividends(true) > 0) harvest();

        // exchange tokens
        tokenBalanceLedger_[_addr] = SafeMath.sub(tokenBalanceLedger_[_addr], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);

        // update dividend trackers
        payoutsTo_[_addr] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);

        // fire event
        emit Transfer(_addr, _toAddress, _amountOfTokens);

        // ERC20
        return true;
    }
    
    /*----------  HELPERS AND CALCULATORS  ----------*/

    function totalEthereumBalance() public view returns(uint) {
        return address(this).balance;
    }

    function totalSupply() public view returns(uint256) {
        return tokenSupply_;
    }

    function myTokens() public view returns(uint256) {
        address _addr = msg.sender;
        return balanceOf(_addr);
    }
    
    function myDividends(bool _includeReferralBonus) public view returns(uint256) {
        address _addr = msg.sender;
        return dividendsOf(_addr,_includeReferralBonus);
    }

    function balanceOf(address _addr) view public returns(uint256) {
        return tokenBalanceLedger_[_addr];
    }

    function dividendsOf(address _addr, bool _includeReferralBonus) view public returns(uint256) {
        uint256 regularDividends = (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_addr]) - payoutsTo_[_addr]) / magnitude;
        if (_includeReferralBonus){
            return regularDividends + referralBalance_[_addr];
        } else {
            return regularDividends;
        }
    }

    function sellPrice() public view returns(uint256) {
        // our calculation relies on the token supply, so we need supply. Doh.
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(_ethereum, dividendFee_  );
            uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }

    function buyPrice() public view returns(uint256) {
        // our calculation relies on the token supply, so we need supply. Doh.
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(_ethereum, dividendFee_  );
            uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }

    function calculateTokensReceived(uint256 _ethereumToSpend) public view returns(uint256) {
        uint256 _dividends = SafeMath.div(_ethereumToSpend, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        
        return _amountOfTokens;
    }

    function calculateEthereumReceived(uint256 _tokensToSell) public view returns(uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }
    
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/

    function purchaseTokens(uint256 _incomingEthereum, address _referredBy) internal returns(uint256) {
        // data setup
        address _addr = msg.sender;
        uint256 _undividedDividends = SafeMath.div(_incomingEthereum, dividendFee_);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;
 
        // prevents overflow
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        
        if(
            // is this a referred purchase?
            _referredBy != 0x0000000000000000000000000000000000000000
        ){
            // wealth redistribution
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
            // no ref purchase
            // add the referral bonus back to the global dividends cake
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }
        
        // we can't give people infinite ethereum
        if(tokenSupply_ > 0){
            
            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
 
            // take the amount of dividends gained through this transaction, and allocates them evenly to each participant
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));
            
            // calculate the amount of tokens the customer receives over his purchase 
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));
        
        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }
        
        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_addr] = SafeMath.add(tokenBalanceLedger_[_addr], _amountOfTokens);
        
        // Tells the contract that the buyer doesn't deserve dividends for the tokens before they owned them
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_addr] += _updatedPayouts;
        
        // fire event
        onDeposit(_addr, _incomingEthereum, _amountOfTokens, _referredBy);
        
        return _amountOfTokens;
    }

    function ethereumToTokens_(uint256 _ethereum) internal view returns(uint256) {
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
                            (2*(tokenPriceIncremental_ * 1e18)*(_ethereum * 1e18))
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

     function tokensToEthereum_(uint256 _tokens) internal view returns(uint256) {

        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _etherReceived =
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
        return _etherReceived;
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