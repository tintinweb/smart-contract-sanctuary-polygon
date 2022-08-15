// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniSwapPair.sol";
import "./IReferralAccountsManager.sol";

contract MinerioNormalTokensPresaleImmediate is Ownable {
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////                                                                                    ////////////////
    ////////////////     .88b  d88.   d888888b   d8b   db   d88888b   d8888b.   d888888b    .d88b.      ////////////////
    ////////////////     88'YbdP`88     `88'     888o  88   88'       88  `8D     `88'     .8P  Y8.     ////////////////
    ////////////////     88  88  88      88      88V8o 88   88ooooo   88oobY'      88      88    88     ////////////////
    ////////////////     88  88  88      88      88 V8o88   88~~~~~   88`8b        88      88    88     ////////////////
    ////////////////     88  88  88     .88.     88  V888   88.       88 `88.     .88.     `8b  d8'     ////////////////
    ////////////////     YP  YP  YP   Y888888P   VP   V8P   Y88888P   88   YD   Y888888P    `Y88P'      ////////////////
    ////////////////                                                                                    ////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////
    //////////////////////////\     VARIABLES      /////////////////////
    ////////////////////////////////////////////////////////////////////

    //the price of each token
    uint256 private tokenPrice;
    //the max amount of token that each wallet can buy
    uint256 private maxTokenBuyAmount;
    uint256 private minTokenBuyAmount;

    //total ammount of tokens that will be sold
    uint256 private totalSupply;
    uint256 private remainingTokens;

    //reefrral values
    uint256 private referralRioBonusPerGwei;
    uint256 private referralMaticBonusPerGwei;


    bool private presaleActive;

    WalletBuyAmount[] private walletBuyAmounts;

    address[] private usdStableCoinsAddress;
    address private uniswapMaticUsdPair;
    address private WMATICAddress;
    
    address private referralAccountsManagerContractAddress;

    //after token release and start payments
    address private RIOTokenContractAddress;

    // for static Matic Price
    bool private staticMaticPrice;
    uint256 private staticMaticPriceValue;


    constructor(address _referralAccountsManagerContractAddress) {
        referralAccountsManagerContractAddress = _referralAccountsManagerContractAddress;
        presaleActive = true;

        //uniswap Factory for Polygon mainnet
        uniswapMaticUsdPair = 0x604229c960e5CACF2aaEAc8Be68Ac07BA9dF81c3;
        //setting WMATIC token address
        WMATICAddress = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
        //default value of max buy amount and token price
        maxTokenBuyAmount = 1_000 * 10**18;
        minTokenBuyAmount = 50 * 10**18;
        tokenPrice = 30_000_000_000_000_000; // $0.03
        //setting the count of all tokens
        totalSupply = 3_000_000 * (10**18);
        // totalSupply = 250 * (10**18);//TEST
        remainingTokens = totalSupply;

        // setting the referral amount per GWEI ==> total: 5%
        // setting the rio referral amount ==> 10% 
        referralRioBonusPerGwei = 10 * 10**7;
        // setting the Matic referral amount ==> 1.5% 
        referralMaticBonusPerGwei = 0 * 10**7;

        //setting he rio token address to null 
        RIOTokenContractAddress=address(0);

    }

    ////////////////////////////////////////////////////////////////////
    ///////////////////////////\     STRUCTS      //////////////////////
    ////////////////////////////////////////////////////////////////////

    struct WalletBuyAmount {
        address wallet;
        uint256 amount;
    }

    ////////////////////////////////////////////////////////////////////
    //////////////////////////\     MODIFIERS      /////////////////////
    ////////////////////////////////////////////////////////////////////

    modifier WhenPresaleIsActive() {
        require(presaleActive, "The presale is not Active");
        _;
    }

    ////////////////////////////////////////////////////////////////////
    //////////////////////////\     SETTEERS      //////////////////////
    ////////////////////////////////////////////////////////////////////

    function addWalletBuyAmount(address _wallet, uint256 _amount) public onlyOwner {
        //reducing from the remaining amount of tokens
        remainingTokens -= _amount;

        AddTokenToWallet(_wallet, _amount);
    }

    function addWalletBuyAmountBatch(address[] memory _wallet, uint256[] memory _amount) public onlyOwner {
        require(_wallet.length == _amount.length, "The length of the arrays must be equal");

        for(uint256 i = 0; i < _wallet.length; i++) {
            //reducing from the remaining amount of tokens
            remainingTokens -= _amount[i];

            AddTokenToWallet(_wallet[i], _amount[i]);
        }
    }

    //add USD stable coin
    function addUSDStableCoin(address _stableCoin) public onlyOwner {
        //check if already exists
        for (uint256 i = 0; i < usdStableCoinsAddress.length; i++) {
            if (usdStableCoinsAddress[i] == _stableCoin) {
                revert("This stable coin is already added");
            }
        }
        usdStableCoinsAddress.push(_stableCoin);
    }



    function removeUSDStableCoin(address _stableCoin) public onlyOwner {
        //check if exists
        bool found = false;
        for (uint256 i = 0; i < usdStableCoinsAddress.length; i++) {
            if (usdStableCoinsAddress[i] == _stableCoin) {
                usdStableCoinsAddress[i] = usdStableCoinsAddress[
                    usdStableCoinsAddress.length - 1
                ];
                usdStableCoinsAddress.pop();
                found = true;
                return;
            }
        }

        require(found, "This address is not added");
    }

    //set token price
    function setTokenPrice(uint256 _price) public onlyOwner {
        tokenPrice = _price;
    }

    function setUniswapMaticUsdtPair(address _pair) public onlyOwner {
        uniswapMaticUsdPair = _pair;
    }

    function setWMATICAddress(address _wmatic) public onlyOwner {
        WMATICAddress = _wmatic;
    }

    function setMinTokenBuyAmount(uint256 _minTokenBuyAmount) public onlyOwner {
        minTokenBuyAmount = _minTokenBuyAmount;
    }

    function setStaticMaticPrice(bool _staticMaticPrice) public onlyOwner {
        staticMaticPrice = _staticMaticPrice;
    }

    function setStaticMaticPriceValue(uint256 _staticmaticPriceValue) public onlyOwner {
        staticMaticPriceValue = _staticmaticPriceValue;
    }

    function setMaxTokenBuyAmount(uint256 _maxTokenBuyAmount) public onlyOwner {
        maxTokenBuyAmount = _maxTokenBuyAmount;
    }

    function setPresaleActive(bool _presaleActive) public onlyOwner {
        presaleActive = _presaleActive;
    }

    function setReferralRioBonusPerGwei(uint256 _referralBonusPerGwei) public onlyOwner {
        referralRioBonusPerGwei = _referralBonusPerGwei;
    }

    function setReferralMaticBonusPerGwei(uint256 _referralBonusPerGwei) public onlyOwner {
        referralMaticBonusPerGwei = _referralBonusPerGwei;
    }

    function setTotalSupply(uint256 _totalSupply) public onlyOwner {
        require(_totalSupply > totalSupply, "New total supply should be greater than current total supply");
        remainingTokens = _totalSupply - totalSupply;
        totalSupply = _totalSupply;
    }

    function setRioTokenContractAddress(address _rioTokenContractAddress) public onlyOwner {
        RIOTokenContractAddress = _rioTokenContractAddress;
    }

    function setReferralAccountsManagerContractAddress(address _referralAccountsManagerContractAddress) public onlyOwner {
        referralAccountsManagerContractAddress = _referralAccountsManagerContractAddress;
    }

    ////////////////////////////////////////////////////////////////////
    //////////////////////\     MAIN FUNCTIONS      ////////////////////
    ////////////////////////////////////////////////////////////////////

    function BuyWithMatic(uint256 _tokensCount, address _referralAddress)
        public
        payable
        WhenPresaleIsActive
    {
        require(
            _tokensCount >= minTokenBuyAmount,
            "You can't buy less than minTokenBuyAmount"
        );
        require(
            getWalletBuyAmount(msg.sender) + _tokensCount <= maxTokenBuyAmount,
            "You can't buy more than maxTokenBuyAmount"
        );

        require(
            _tokensCount <= remainingTokens,
            "You can't buy more than totalSupply"
        );

        require(RIOTokenContractAddress != address(0), "RIO token contract address is not set");

        uint256 price = CalculateAmountOfMatic(_tokensCount);
        require(msg.value >= price, "Wrong Price");

        //returning the additional value to user
        payable(msg.sender).transfer(msg.value - price);

        //calculating the referral values
        calculateReferral(_tokensCount,_referralAddress);

        //reducing from the remaining amount of tokens
        remainingTokens -= _tokensCount;
        // adding the tokens to user wallet
        AddTokenToWallet(msg.sender, _tokensCount);

        //adding the sender wallet address to the referrent list
        IReferralAccountsManager(referralAccountsManagerContractAddress).safeAddReferrent(msg.sender);

        // Transfer token to user wallet
        IERC20(RIOTokenContractAddress).transfer(msg.sender, _tokensCount);
    }

    function BuyWithUSD(
        uint256 _tokensCount,
        address _USDtokenAddress,
        address _referralAddress
    ) public WhenPresaleIsActive {
        //check if the stable coin exists in the list
        bool found = false;
        for (uint256 i = 0; i < usdStableCoinsAddress.length; i++) {
            if (usdStableCoinsAddress[i] == _USDtokenAddress) {
                found = true;
                break;
            }
        }

        require(found, "This stable coin is not added");

        require(
            _tokensCount >= minTokenBuyAmount,
            "You can't buy less than minTokenBuyAmount"
        );
        require(
            getWalletBuyAmount(msg.sender) + _tokensCount <= maxTokenBuyAmount,
            "You can't buy more than maxTokenBuyAmount"
        );

        require(RIOTokenContractAddress != address(0), "RIO token contract address is not set");

        require(
            _tokensCount <= remainingTokens,
            "You can't buy more than totalSupply"
        );


        uint256 price = CalculateAmountOfUSD(_tokensCount);

        uint256 usdTokenDecimals= IERC20(_USDtokenAddress).decimals();
        if(usdTokenDecimals < 18){
            price /= (10**(18 - usdTokenDecimals));
        }

        //transfreing the tokens
        IERC20(_USDtokenAddress).transferFrom(msg.sender, address(this), price);

        //calculating the referral values
        calculateReferral(_tokensCount,_referralAddress);

        //reducing from the remaining amount of tokens
        remainingTokens -= _tokensCount;
        // adding the tokens to user wallet
        AddTokenToWallet(msg.sender, _tokensCount);

        //adding the sender wallet address to the referrent list
        IReferralAccountsManager(referralAccountsManagerContractAddress).safeAddReferrent(msg.sender);

        // Transfer token to user wallet
        IERC20(RIOTokenContractAddress).transfer(msg.sender, _tokensCount);
    }

    function transferAllMatic() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    function transferMatic(uint256 _amount, address _to) public onlyOwner {
        require(_amount<=address(this).balance);
        payable(_to).transfer(_amount);
    }

    function transferCustomToken(address _tokenAddress, uint256 _amount, address _to) public onlyOwner{
        //check if token exists in the list
        bool found = false;
        for (uint256 i = 0; i < usdStableCoinsAddress.length; i++) {
            if (usdStableCoinsAddress[i] == _tokenAddress) {
                found = true;
                break;
            }
        }
        require(found, "This address is not added");


        require(IERC20(_tokenAddress).balanceOf(address(this))>=_amount);

        IERC20(_tokenAddress).transfer(_to, _amount);
    }
    ////////////////////////////////////////////////////////////////////
    /////////////////////////\     INTERNALS      //////////////////////
    ////////////////////////////////////////////////////////////////////

    function calculateReferral(uint256 _tokensCount, address _referralAddress)
        internal
    {

        //// Calculating RIO 
        
        if (_referralAddress == address(0)) {
            return;
        }

        //if the referral account is not a referrent, the referral amount is 0
        if(!IReferralAccountsManager(referralAccountsManagerContractAddress).isReferrent(_referralAddress))
            return;

        require (_referralAddress != msg.sender ,"cannot give referral to self");

        uint256 referralBonus = ((_tokensCount * 10**9) *
            referralRioBonusPerGwei) / 10**18;

        //finding the wallet index from wallets address
        //transferring RIO to the referral account
        IERC20(RIOTokenContractAddress).transfer(_referralAddress, referralBonus);
        
        //// Calculating MATIC 

        uint256 referralMaticBonus = ((_tokensCount * 10**9) *
            referralMaticBonusPerGwei) / 10**18;
        
        payable(_referralAddress).transfer(CalculateAmountOfMatic(referralMaticBonus));
        
    }

    function CalculateAmountOfMatic(uint256 _tokensCount)
        public
        view
        returns (uint256)
    {
        uint256 maxUsdPrice = CalculateAmountOfUSD(_tokensCount);
        maxUsdPrice *= 10**18;
        return maxUsdPrice / getMaticPrice();
    }

    function CalculateAmountOfUSD(uint256 _tokensCount)
        public
        view
        returns (uint256)
    {
        uint256 maxUsdPrice = tokenPrice * _tokensCount;
        return maxUsdPrice / 10**18;
    }

    function AddTokenToWallet(address _wallet, uint256 _tokensCount) internal {
        //finding the wallet index from wallets address
        for (uint256 index = 0; index < walletBuyAmounts.length; index++) {
            if (walletBuyAmounts[index].wallet == _wallet) {
                walletBuyAmounts[index].amount += _tokensCount;
                return;
            }
        }
        //if wallet not found, adding new wallet
        walletBuyAmounts.push(WalletBuyAmount(_wallet, _tokensCount));
    }

    ////////////////////////////////////////////////////////////////////
    //////////////////////////\     GETTEERS      //////////////////////
    ////////////////////////////////////////////////////////////////////
    
    //receiver
    receive() external payable {}

    function getTokenPrice() public view returns (uint256) {
        return tokenPrice;
    }

    function isPresaleActive() public view returns (bool) {
        return presaleActive;
    }

    function getmaxTokenBuyAmount() public view returns (uint256) {
        return maxTokenBuyAmount;
    }

    function getminTokenBuyAmount() public view returns (uint256) {
        return minTokenBuyAmount;
    }

    //get stable coins
    function getUSDStableCoins() public view returns (address[] memory) {
        return usdStableCoinsAddress;
    }

    //get usd reference stable coin
    function getUniswapMaticUsdtPair() public view returns (address) {
        return uniswapMaticUsdPair;
    }

    function getMaticPrice() public view returns (uint256) {
        if(staticMaticPrice){
            require (staticMaticPriceValue != 0, "static matic price is not set");
            return staticMaticPriceValue;
        }

        (uint112 reserve0, uint112 reserve1, ) = IUniSwapPair(
            uniswapMaticUsdPair
        ).getReserves();

        uint256 token0Decimals = IERC20(
            IUniSwapPair(uniswapMaticUsdPair).token0()
        ).decimals();
        uint256 token1Decimals = IERC20(
            IUniSwapPair(uniswapMaticUsdPair).token1()
        ).decimals();

        uint256 token0Amount = reserve0;
        uint256 token1Amount = reserve1;

        if (token0Decimals < 18 && token0Decimals != 0)
            token0Amount = token0Amount * (10**(18 - token0Decimals));
        if (token1Decimals < 18 && token1Decimals != 0)
            token1Amount = token1Amount * (10**(18 - token1Decimals));

        uint256 price = 0;
        if (IUniSwapPair(uniswapMaticUsdPair).token0() == WMATICAddress)
            price = (token1Amount * (10**18)) / token0Amount;
        else price = (token0Amount * (10**18)) / token1Amount;

        return price;
    }

    function getTokenSupply() public view returns (uint256) {
        return totalSupply;
    }

    function getRemainingTokens() public view returns (uint256) {
        return remainingTokens;
    }

    function getWMaticAddress() public view returns (address) {
        return WMATICAddress;
    }

    //get tokens count in wallet
    function getWalletBuyAmount(address _wallet) public view returns (uint256) {
        for (uint256 i = 0; i < walletBuyAmounts.length; i++) {
            if (walletBuyAmounts[i].wallet == _wallet) {
                return walletBuyAmounts[i].amount;
            }
        }
        return 0;
    }

    function getReferralRioBonusPerGwei() public view returns (uint256) {
        return referralRioBonusPerGwei;
    }

    function getReferralMaticBonusPerGwei() public view returns (uint256) {
        return referralMaticBonusPerGwei;
    }

    function getRioTokenContractAddress() public view returns (address) {
        return RIOTokenContractAddress;
    }

    function allBuyAmounts()
        public
        view
        onlyOwner
        returns (WalletBuyAmount[] memory)
    {
        return walletBuyAmounts;
    }

    function getReferralAccountsManagerContractAddress() public view returns (address) {
        return referralAccountsManagerContractAddress;
    }
    
}