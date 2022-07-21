// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniSwapPair.sol";
import "./IReferralAccountsManager.sol";

contract MinerioVIPTokensPresale is Ownable {
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

    uint256 private profitPerGwei;

    uint256 private claimStartTime;

    uint256 private withdrawTimeInSeconds;

    bool private presaleActive;

    WalletHistory[] private walletHistories;

    address[] private usdStableCoinsAddress;
    address[] private vipWalletsListModifiers;
    address[] private vipWallets;
    address private uniswapMaticUsdPair;
    address private WMATICAddress;
    

    //after token release and start payments
    address private RIOTokenContractAddress;
    
    address private referralAccountsManagerContractAddress;

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
        maxTokenBuyAmount = 25000 * 10**18;
        minTokenBuyAmount = 50 * 10**18;
        tokenPrice = 40_000_000_000_000_000; // $0.04
        //setting the count of all tokens
        totalSupply = 5_000_000 * (10**18);
        // totalSupply = 400 * (10**18);//TEST
        remainingTokens = totalSupply;

        // setting the referral amount per GWEI ==> total: 5%
        // setting the rio referral amount ==> 10% 
        referralRioBonusPerGwei = 10 * 10**7;
        // setting the Matic referral amount ==> 0% 
        referralMaticBonusPerGwei = 0 * 10**7;


        //setting the profit per gweis
        profitPerGwei = 100 * 10**7; // => 100%

        withdrawTimeInSeconds = 31_536_000; // 1 Year

        //setting he rio token address to null 
        RIOTokenContractAddress = address(0);

        staticMaticPrice = false;
    }

    ////////////////////////////////////////////////////////////////////
    ///////////////////////////\     STRUCTS      //////////////////////
    ////////////////////////////////////////////////////////////////////

    struct WalletBuyAmount {
        uint256 buyTime;
        uint256 rawAmount;
        uint256 amountWithProfit;
        uint256 claimedAmount;
    }
    
    struct WalletHistory{
        address wallet;
        WalletBuyAmount[] buyAmounts;
    }

    ////////////////////////////////////////////////////////////////////
    //////////////////////////\     MODIFIERS      /////////////////////
    ////////////////////////////////////////////////////////////////////

    modifier WhenPresaleIsActive() {
        require(presaleActive, "The presale is not Active");
        _;
    }
    
    modifier OnlyVIP() {
        require(isVip(msg.sender), "You are not in VIP list");
        _;
    }

    modifier isVipWalletsListModifier{
        require(msg.sender == owner() || isVipWalletModifier(msg.sender), "You are not in VIP list");
        _;
    }

    ////////////////////////////////////////////////////////////////////
    //////////////////////////\     SETTEERS      //////////////////////
    ////////////////////////////////////////////////////////////////////

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

    function addVipWalletBatch(address[] memory _vipLists) public isVipWalletsListModifier{
        for (uint256 i = 0; i < _vipLists.length; i++) {
            vipWallets.push(_vipLists[i]);
        }
    }

    function addVipWallet(address _wallet) public isVipWalletsListModifier{
        vipWallets.push(_wallet);
    }
    function removeVipWallet(address _wallet)public isVipWalletsListModifier{
        require(vipWallets.length > 0, "There is no VIP wallet list modifiers");
        
        for (uint256 i = 0; i < vipWallets.length; i++) {
            if (vipWallets[i] == _wallet) {
                vipWallets[i] = vipWallets[vipWallets.length - 1];
                vipWallets.pop();
                return;
            }
        }

    }

    function addVipWalletListModifiers(address _wallet) public onlyOwner {
        vipWalletsListModifiers.push(_wallet);
    }

    function removeVipWalletsListModifiers(address _wallet) public onlyOwner {
        require(vipWalletsListModifiers.length > 0, "There is no VIP wallet list modifiers");
        
        for (uint256 i = 0; i < vipWalletsListModifiers.length; i++) {
            if (vipWalletsListModifiers[i] == _wallet) {
                vipWalletsListModifiers[i] = vipWalletsListModifiers[vipWalletsListModifiers.length - 1];
                vipWalletsListModifiers.pop();
            }
        }
    }
    
    function removeVipWalletsBatch(address[] memory _vipLists) public isVipWalletsListModifier {
        require(vipWallets.length > 0, "There is no VIP wallets");
        
        for (uint256 i = _vipLists.length-1; i >=0; i--) {
            //check if already exists
            if (isVip(_vipLists[i])){
                removeVipWallet(_vipLists[i]);
                continue;

            }

        }
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

    //set profit per gwei for 12 months
    function setProfitPerGwei(uint256 _profitPerGwei) public onlyOwner {
        profitPerGwei = _profitPerGwei;
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

    function setWithdrawTimeInSeconds(uint256 _withdrawTimeInSeconds) public onlyOwner {
        withdrawTimeInSeconds = _withdrawTimeInSeconds;
    }

    function setStaticMaticPrice(bool _staticMaticPrice) public onlyOwner {
        staticMaticPrice = _staticMaticPrice;
    }

    function setStaticMaticPriceValue(uint256 _staticmaticPriceValue) public onlyOwner {
        staticMaticPriceValue = _staticmaticPriceValue;
    }

    function setMinTokenBuyAmount(uint256 _minTokenBuyAmount) public onlyOwner {
        minTokenBuyAmount = _minTokenBuyAmount;
    }

    function setClaimStartTime(uint256 _claimStartTime) public onlyOwner {
        claimStartTime = _claimStartTime;
    }

    function setMaxTokenBuyAmount(uint256 _maxTokenBuyAmount) public onlyOwner {
        maxTokenBuyAmount = _maxTokenBuyAmount;
    }

    function setPresaleActive(bool _presaleActive) public onlyOwner {
        presaleActive = _presaleActive;
    }

    function setTotalSupply(uint256 _totalSupply) public onlyOwner {
        require(_totalSupply > totalSupply, "New total supply should be greater than current total supply");
        remainingTokens += _totalSupply - totalSupply;
        totalSupply = _totalSupply;
    }

    function setReferralRioBonusPerGwei(uint256 _referralBonusPerGwei) public onlyOwner {
        referralRioBonusPerGwei = _referralBonusPerGwei;
    }

    function setReferralMaticBonusPerGwei(uint256 _referralBonusPerGwei) public onlyOwner {
        referralMaticBonusPerGwei = _referralBonusPerGwei;
    }

    function setRioTokenContractAddress(address _rioTokenContractAddress) public onlyOwner {
        RIOTokenContractAddress = _rioTokenContractAddress;
    }

    ////////////////////////////////////////////////////////////////////
    //////////////////////\     MAIN FUNCTIONS      ////////////////////
    ////////////////////////////////////////////////////////////////////

    function BuyWithMatic(uint256 _tokensCount, address _referralAddress)
        public
        payable
        WhenPresaleIsActive
        OnlyVIP
    {
        require(
            _tokensCount >= minTokenBuyAmount,
            "You can't buy less than minTokenBuyAmount"
        );

        require(
            _tokensCount <= remainingTokens,
            "You can't buy more than totalSupply"
        );

        require(
            getAllWalletsRawBuyAmounts(msg.sender) + _tokensCount <= getmaxTokenBuyAmountForWallet(msg.sender),
            "You can't buy more than maxTokenBuyAmount"
        );

        uint256 price = CalculateAmountOfMatic(_tokensCount);
        require(msg.value >= price, "Wrong Price");

        //returning the additional value to user
        payable(msg.sender).transfer(msg.value - price);

        //calculating the referral values
        calculateRefferal(_tokensCount,_referralAddress);

        //reducing from the remaining amount of tokens
        remainingTokens -= _tokensCount;
        // adding the tokens to user wallet
        AddTokenToWallet(msg.sender, _tokensCount);

        
        //adding the sender wallet address to the referrent list 
        IReferralAccountsManager(referralAccountsManagerContractAddress).safeAddReferrent(msg.sender);
    }

    function BuyWithUSD(
        uint256 _tokensCount,
        address _USDtokenAddress,
        address _referralAddress
    ) public WhenPresaleIsActive OnlyVIP{
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
            _tokensCount <= remainingTokens,
            "You can't buy more than totalSupply"
        );
        

        require(
            getAllWalletsRawBuyAmounts(msg.sender) + _tokensCount <= getmaxTokenBuyAmountForWallet(msg.sender),
            "You can't buy more than maxTokenBuyAmount"
        );

        uint256 price = CalculateAmountOfUSD(_tokensCount);

        uint256 usdTokenDecimals= IERC20(_USDtokenAddress).decimals();
        if(usdTokenDecimals < 18){
            price /= (10**(18 - usdTokenDecimals));
        }

        //transfreing the tokens
        IERC20(_USDtokenAddress).transferFrom(msg.sender, address(this), price);

        //calculating the referral values
        calculateRefferal(_tokensCount, _referralAddress);

        //reducing from the remaining amount of tokens
        remainingTokens -= _tokensCount;
        // adding the tokens to user wallet
        AddTokenToWallet(msg.sender, _tokensCount);

        
        //adding the sender wallet address to the referrent list 
        IReferralAccountsManager(referralAccountsManagerContractAddress).safeAddReferrent(msg.sender);
    }

    function transferAllMatic() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    function transferMatic(uint256 _amount, address _to) public onlyOwner {
        require(_amount<=address(this).balance, "Not enough balance");
        payable(_to).transfer(_amount);
    }

    function transferCustomToken(address _tokenAddress, uint256 _amount, address _to) public onlyOwner{
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= _amount);

        IERC20(_tokenAddress).transfer(_to, _amount);
    }


    //// after token release and tokens are ready to be shared between wallets
    function claimProfit(uint256 _historyIndex) public {
        (uint256 claimableTokens, uint256 tokens) = getClaimableProfitAmount(msg.sender, _historyIndex, block.timestamp);
        require(IERC20(RIOTokenContractAddress).balanceOf(address(this)) >= claimableTokens , "There is not enough token in the pool. Please try again later.");

        //transfering the rio tokens
        IERC20(RIOTokenContractAddress).transfer(msg.sender, claimableTokens);

        //setting the claimed values
        for (uint256 i = 0; i < walletHistories.length; i++) {
            if (walletHistories[i].wallet == msg.sender) {
                walletHistories[i].buyAmounts[_historyIndex].claimedAmount = tokens;
            }
        }
    }

    function claimAllProfits() public {
        require(getAllWalletsRawBuyAmounts(msg.sender) > 0, "You did not buy any tokens");
        require(RIOTokenContractAddress != address(0),"the token is not released yet");
        require(claimStartTime != 0, "time of claim is not started yet");
        require(block.timestamp > claimStartTime, "time of claim is not started yet");

        WalletBuyAmount[] memory _allBuyAmounts = getAllWalletBuyAmounts(msg.sender);

        for (uint256 i = 0; i < _allBuyAmounts.length; i++) {
            claimProfit(i);
        }
    }

    function transferWalletBuyAmount(address _wallet ,uint256 _historyIndex)public{
        require(getAllWalletsRawBuyAmounts(msg.sender) > 0, "You did not buy any tokens");

        for (uint256 i = 0; i < walletHistories.length; i++) {
            if(walletHistories[i].wallet == msg.sender){
                require(walletHistories[i].buyAmounts.length>_historyIndex, "Wrong history index");
                require(walletHistories[i].buyAmounts[_historyIndex].claimedAmount != walletHistories[i].buyAmounts[_historyIndex].amountWithProfit,"You can't transfer the tokens that you already withdrawed");
                WalletBuyAmount memory amnt = walletHistories[i].buyAmounts[_historyIndex];

                //adding the wallet buy info to the receiver's array
                bool found = false;
                for (uint256 j = 0; j < walletHistories.length; j++) {
                    if(walletHistories[j].wallet == _wallet){
                        walletHistories[j].buyAmounts.push(amnt);
                        found = true;
                        break;
                    }
                }

                if(!found){
                    walletHistories.push();
                    walletHistories[walletHistories.length - 1].wallet=_wallet;
                    walletHistories[walletHistories.length - 1].buyAmounts.push(amnt);
                }
                
                //removing the wallet buy info from the sender's array
                walletHistories[i].buyAmounts[_historyIndex] = walletHistories[i].buyAmounts[walletHistories[i].buyAmounts.length-1];
                walletHistories[i].buyAmounts.pop();
            }
        }

    }

    
    function withdrawWalletBuyAmount(uint256 _historyIndex)public{
        require(getAllWalletsRawBuyAmounts(msg.sender) > 0, "You did not buy any tokens");

        
        for (uint256 i = 0; i < walletHistories.length; i++) {
            if(walletHistories[i].wallet == msg.sender){
                require(walletHistories[i].buyAmounts.length>_historyIndex,"Wrong history index");
                //check time
                uint256 startTime = claimStartTime;
                if(walletHistories[i].buyAmounts[_historyIndex].buyTime > startTime)
                    startTime = walletHistories[i].buyAmounts[_historyIndex].buyTime;

                require(block.timestamp > startTime + withdrawTimeInSeconds , "You cannot withdraw yet.");
                require(walletHistories[i].buyAmounts.length > _historyIndex,"Wrong history index");
                require(walletHistories[i].buyAmounts[_historyIndex].claimedAmount != walletHistories[i].buyAmounts[_historyIndex].amountWithProfit,"You can't transfer the tokens that you already withdrawed");
                
                //transfering the rio tokens
                IERC20(RIOTokenContractAddress).transfer(msg.sender, walletHistories[i].buyAmounts[_historyIndex].amountWithProfit - walletHistories[i].buyAmounts[_historyIndex].claimedAmount);
                walletHistories[i].buyAmounts[_historyIndex].claimedAmount = walletHistories[i].buyAmounts[_historyIndex].amountWithProfit;
            }
        }

    }
    
    function withdrawAllWalletBuyAmounts()public{
        require(getAllWalletsRawBuyAmounts(msg.sender) > 0, "You did not buy any tokens");

        
        for (uint256 i = 0; i < walletHistories.length; i++) {
            if(walletHistories[i].wallet == msg.sender){
                for (uint256 j = 0; j < walletHistories[i].buyAmounts.length; j++) {
                    withdrawWalletBuyAmount(j);
                }
            }
        }

    }
    ////////////////////////////////////////////////////////////////////
    /////////////////////////\     INTERNALS      //////////////////////
    ////////////////////////////////////////////////////////////////////

    function calculateRefferal(uint256 _tokensCount, address _referralAddress)
        internal
    {

        
        if (_referralAddress == address(0)) {
            return;
        }
        
        //if the referral account is not a referrent, the referral amount is 0
        if(!IReferralAccountsManager(referralAccountsManagerContractAddress).isReferrent(_referralAddress))
            return;

        require (_referralAddress != msg.sender ,"cannot give referral to self");

        //// Calculating RIO 
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
        /////// 12 months
        uint256 profit = ((_tokensCount * 10**9) *
            profitPerGwei) / 10**18;

        bool found=false;
        //finding the wallet index from wallets address
        for (uint256 index = 0; index < walletHistories.length; index++) {
            if (walletHistories[index].wallet == _wallet) {
                walletHistories[index].buyAmounts.push(WalletBuyAmount(block.timestamp, _tokensCount, _tokensCount + profit, 0));
                found=true;
                break;
            }
        }
        //if wallet not found, adding new wallet
        if(!found){
            walletHistories.push();
            walletHistories[walletHistories.length - 1].wallet = _wallet;
            walletHistories[walletHistories.length - 1].buyAmounts.push(WalletBuyAmount(block.timestamp, _tokensCount, _tokensCount + profit, 0));

        }
    }

    ////////////////////////////////////////////////////////////////////
    //////////////////////////\     GETTEERS      //////////////////////
    ////////////////////////////////////////////////////////////////////

    //receiver
    receive() external payable {}

    function getTokenPrice() public view returns (uint256) {
        return tokenPrice;
    }

    function isVip(address _wallet) public view returns (bool) {
        for (uint256 index = 0; index < vipWallets.length; index++) {
            if (vipWallets[index] == _wallet) {
                return true;
            }
        }
        return false;
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

    function getStaticMaticPriceValue() public view returns (uint256) {
        return staticMaticPriceValue;
    }

    function getStaticmaticPrice() public view returns (bool) {
        return staticMaticPrice;
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
    function getAllWalletsRawBuyAmounts(address _wallet) public view returns (uint256) {
        uint256 sum=0;
        
        for (uint256 i = 0; i < walletHistories.length; i++) {
            if (walletHistories[i].wallet == _wallet) {
                for (uint256 j = 0; j < walletHistories[i].buyAmounts.length; j++) {
                    sum += walletHistories[i].buyAmounts[j].rawAmount;
                }
            }
        }
        return sum;
    }
    
    //get tokens count in wallet
    function getWalletsRawBuyAmountByIndex(address _wallet, uint256 _index) public view returns (uint256) {        
        for (uint256 i = 0; i < walletHistories.length; i++) {
            if (walletHistories[i].wallet == _wallet) {
                return walletHistories[i].buyAmounts[_index].rawAmount;
            }
        }
        return 0;
    }


    function getmaxTokenBuyAmountForWallet(address _wallet) public view returns (uint256) {
        uint256 count;
        for (uint256 i = 0; i < vipWallets.length; i++) {
            if(vipWallets[i] == _wallet){
                count++;
            }
        }
        return maxTokenBuyAmount * count;        
    }

    //get tokens count in wallet
    function getAllWalletBuyAmounts(address _wallet) public view returns (WalletBuyAmount[] memory) {
        for (uint256 i = 0; i < walletHistories.length; i++) {
            if (walletHistories[i].wallet == _wallet) {
                return walletHistories[i].buyAmounts;
            }
        }
        return new WalletBuyAmount[](0);
    }  

    function getWalletBuyAmount(address _wallet, uint256 _index) public view returns (WalletBuyAmount memory) {
        for (uint256 i = 0; i < walletHistories.length; i++) {
            if (walletHistories[i].wallet == _wallet) {
                return walletHistories[i].buyAmounts[_index];
            }
        }
        return WalletBuyAmount(0, 0, 0, 0);
    }


    //get tokens count in wallet
    function getAllWalletBuyClaimedAmounts(address _wallet) public view returns (uint256) {
        uint256 sum=0;
        for (uint256 i = 0; i < walletHistories.length; i++) {
            if (walletHistories[i].wallet == _wallet) {
                for (uint256 j = 0; j < walletHistories[i].buyAmounts.length; j++) {
                    sum += walletHistories[i].buyAmounts[j].claimedAmount;
                }
            }
        }
        return 0;
    } 

    //get tokens count in wallet
    function getWalletBuyClaimedAmount(address _wallet, uint256 _index) public view returns (uint256) {
        for (uint256 i = 0; i < walletHistories.length; i++) {
            if (walletHistories[i].wallet == _wallet) {
                return walletHistories[i].buyAmounts[_index].claimedAmount;
            }
        }
        return 0;
    }    

    

    function getReferralRioBonusPerGwei() public view returns (uint256) {
        return referralRioBonusPerGwei;
    }

    function getClaimStartTime() public view returns (uint256) {
        return claimStartTime;
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
        returns (WalletHistory[] memory)
    {
        return walletHistories;
    }

    
    function allBuyAmountsWithPagination(uint256 _pageNumber, uint256 pageSize)
        public
        view
        returns (WalletHistory[] memory)
    {

        uint256 startIndex = _pageNumber * pageSize;
        uint256 endIndex = startIndex + pageSize;
        if (endIndex > walletHistories.length)
            endIndex = walletHistories.length;
        WalletHistory[] memory result = new WalletHistory[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = walletHistories[i];
        }
        return result;
    }
    
    
    function getClaimableProfitAmount(address _wallet, uint256 _historyIndex, uint256 _timestamp)public view returns (uint256 _claimableTokens, uint256 _totlaClaims){
        require(getAllWalletsRawBuyAmounts(_wallet) > 0, "You did not buy any tokens");
        require(RIOTokenContractAddress != address(0),"the token is not released yet");
        require(claimStartTime != 0, "time of claim is not started yet");
        require(_timestamp > claimStartTime, "time of claim is not started yet");

        WalletBuyAmount memory amount = getWalletBuyAmount(_wallet, _historyIndex);
        

        //calculate the amount of tokens to be transferred based on current time 
        uint256 startTime = claimStartTime;
        if(amount.buyTime > startTime){
            startTime = amount.buyTime;
        }
        if(_timestamp<startTime)
            return (0,0);
        uint256 deltaTime = _timestamp - startTime;
        // uint256 totalTime = startTime + (60 * 60 * 24 * 365); // one year

        uint256 maxTokens = amount.amountWithProfit - amount.rawAmount;
        uint256 tokens = (((maxTokens * 10 ** 9) / withdrawTimeInSeconds) * deltaTime) / 10 ** 9;
        if(tokens > maxTokens)
            tokens = maxTokens;

        uint256 claimed = getWalletBuyClaimedAmount(_wallet, _historyIndex);
        if(tokens < claimed)
            return (0, tokens);
        uint256 claimableTokens = (tokens - claimed);
        return (claimableTokens, tokens);
    }

    function getAllClaimableProfits(address _wallet, uint256 _timestamp)public view returns (uint256){
        require(getAllWalletsRawBuyAmounts(_wallet) > 0, "wallet did not buy any tokens");
        require(RIOTokenContractAddress != address(0),"the token is not released yet");
        require(claimStartTime != 0, "time of claim is not started yet");
        require(_timestamp > claimStartTime, "time of claim is not started yet");

        WalletBuyAmount[] memory _allBuyAmounts = getAllWalletBuyAmounts(_wallet);
        uint256 _totalClaimableTokens = 0;

        for (uint256 i = 0; i < _allBuyAmounts.length; i++) {
            (uint256 claimableProfit,) = getClaimableProfitAmount(_wallet, i, _timestamp);
            _totalClaimableTokens+= claimableProfit;
        }
        return _totalClaimableTokens;
    }

    function isVipWalletModifier(address _wallet) public view returns (bool){
        for (uint256 i = 0; i < vipWalletsListModifiers.length; i++) {
            if (vipWalletsListModifiers[i] == _wallet) {
                return true;
            }
        }
        return false;
    }
    
    function getReferralAccountsManagerContractAddress() public view returns (address) {
        return referralAccountsManagerContractAddress;
    }
    
    function getWithdrawTimeInSeconds() public view returns (uint256) {
        return withdrawTimeInSeconds;
    }

    function getProfitPerGwei() public view returns (uint256) {
        return profitPerGwei;
    }

    function getVipWallets() public view returns (address[] memory) {
        return vipWallets;
    }



    
}