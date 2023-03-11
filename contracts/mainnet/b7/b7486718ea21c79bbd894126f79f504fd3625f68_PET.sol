// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;


import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./SafeERC20.sol";
import "./Address.sol";

abstract contract Reentrancy {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "Reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}


contract PET is ERC20, Ownable, Reentrancy {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    IUniswapV2Router02 public uniswapV2Router;
    bool private swapping;
    DividendTracker public dividendTracker;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    uint256 public swapTokensAtAmount = 100 * (10**18);
    mapping(address => bool) public _isBlacklisted;

    uint256 public rewardsFee = 3;
    uint256 public liquidityFee = 2;
    uint256 public marketingFee = 1;
    uint256 public sellTopUp = 1;
    uint256 public walletFee;
    uint256 public capFees = 20;
    uint256 public slippage = 20;
    uint256 public totalFees = rewardsFee.add(liquidityFee).add(marketingFee);
    address public _marketingWalletAddress = 0x5C9D790F7d38c97b6F78a8ad173de262e06f0A37; 

     // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event MarketingWalletUpdated(address indexed newMarketingyWallet, address indexed oldMarketingyWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SendDividends(
    	uint256 amount
    );
    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );
    constructor()  ERC20("Poodl Exchange Token", "PET") {

    	dividendTracker = new DividendTracker();
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        automatedMarketMakerPairs[_uniswapV2Pair]=true;

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(deadWallet);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));
        dividendTracker.excludeFromDividends(address(_uniswapV2Pair));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(_marketingWalletAddress, true);
        excludeFromFees(address(this), true);
        
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100000000 * (10**18));
    }

    receive() external payable {}

    //WRITE FUNCTIONS OWNER


    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "");
        DividendTracker newDividendTracker = DividendTracker(payable(newAddress));
        require(newDividendTracker.owner() == address(this), "");
        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(deadWallet);
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
        emit UpdateDividendTracker(newAddress, address(dividendTracker));
        dividendTracker = newDividendTracker;
    }
    
    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "");
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address pair = IUniswapV2Factory(uniswapV2Router.factory())
            .getPair(address(this), uniswapV2Router.WETH());
        if(pair == address(0)){
            address newPair = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(address(this), uniswapV2Router.WETH());
            automatedMarketMakerPairs[newPair]=true;         
        }else{
            automatedMarketMakerPairs[pair]=true;
        }
        dividendTracker.excludeFromDividends(address(uniswapV2Router));
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
    }

    // updates the default router for buying tokens from dividend tracker
    function updateDividendUniswapV2Router(address newAddress) external onlyOwner {
        dividendTracker.updateDividendUniswapV2Router(newAddress);
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool){
  	    swapTokensAtAmount = newAmount * (10**18);
  	    return true;
  	}

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "");
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function blacklistAddress(address account, bool value) external onlyOwner{
        _isBlacklisted[account] = value;
    }

    function blacklistMultipleAddresses(address[] calldata accounts, bool blacklisted) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isBlacklisted[accounts[i]] = blacklisted;
        }
    }

	function excludeFromDividends(address account) external onlyOwner{
	    dividendTracker.excludeFromDividends(account);
	}

    function includeInDividends(address account) external onlyOwner {
        uint256 balance = balanceOf(account);
        dividendTracker.includeInDividends(account, balance);
    }

    function updateGasStipend(uint value) public onlyOwner{
        dividendTracker.updateStipend(value);
    }

    function setMarketingWallet(address payable wallet) external onlyOwner{
        require(wallet != _marketingWalletAddress,"");
        excludeFromFees(wallet, true);
        emit MarketingWalletUpdated(wallet, _marketingWalletAddress);
        _marketingWalletAddress = wallet;
    }

    function setWalletFee(uint256 value) external onlyOwner{
        require((value<= capFees),"");
        walletFee = value;
    }
    function setSlippage(uint _slippage) external onlyOwner {
        slippage = _slippage;
        dividendTracker.setSlippage(_slippage);
    }
    function setFees(uint256 marketing, uint256 rewards, uint256 liquidity, uint sellTop) public onlyOwner{
        require(marketing.add(rewards).add(liquidity).add(sellTop) <= capFees, "");
        totalFees = marketing.add(rewards).add(liquidity);
        marketingFee = marketing;
        rewardsFee = rewards;
        liquidityFee = liquidity;
        sellTopUp = sellTop;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        _setAutomatedMarketMakerPair(pair, value);
    }
    
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "");
        automatedMarketMakerPairs[pair] = value;
        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }
    
    function approveToken(address tokenAddress, bool isApproved) external onlyOwner returns (bool){
        dividendTracker.approveToken(tokenAddress, isApproved);
        return true;
    }

    function approveAMM(address AMMAddress, bool isApproved) external onlyOwner returns (bool){
        dividendTracker.approveAMM(AMMAddress, isApproved);
        return true;
    }

    //WRITE FUNCTIONS USERS

	function processDividendTracker(uint256 gas) external nonReentrant {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, msg.sender);
    }

    function claim() external nonReentrant {
		dividendTracker.processAccount(payable(msg.sender), false);
    }

    function processAccount(address account) external nonReentrant {
		dividendTracker.processAccount(payable(account), false);
    }

    // set the reward token for the user.  Call from here.
  	function setRewardToken(address rewardTokenAddress) external nonReentrant returns (bool) {
  	    require(rewardTokenAddress != address(this), "");
        require(dividendTracker.isTokenApproved(rewardTokenAddress),"Token not approved");
  	    dividendTracker.setRewardToken(msg.sender, rewardTokenAddress);
  	    return true;
  	}

  	// set the reward token for the user with a custom AMM (AMM must be whitelisted).  Call from here.
  	function setRewardTokenWithCustomAMM(address rewardTokenAddress, address ammContractAddress) external nonReentrant returns (bool) {
  	    require(ammContractAddress != address(uniswapV2Router), "");
  	    require(rewardTokenAddress != address(this), "");
  	    require(dividendTracker.isTokenApproved(rewardTokenAddress) , "Token not approved.");
  	    require(dividendTracker.isAMMApproved(ammContractAddress) , "AMM is not whitelisted!");
  	    dividendTracker.setRewardTokenWithCustomAMM(msg.sender, rewardTokenAddress, ammContractAddress);
  	    return true;
  	}
  	
    // Unset the reward token and AMM back to default.  Call from here.
  	function unsetRewardToken() external nonReentrant returns (bool){
  	    dividendTracker.unsetRewardToken(msg.sender);
  	    return true;
  	}
    
    //TRANSFER LOGICS

    function _transfer(
        address  from,
        address  to,
        uint256 amount
    ) internal override {
        require(from != address(0), "");
        require(to != address(0), "");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], 'Blacklisted address');

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if(totalFees > 0){		
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
            if( canSwap &&
                !swapping &&
                !automatedMarketMakerPairs[from] &&
                from != owner() &&
                to != owner()                
                ) {
                    swapping = true;
                    swapBack(contractTokenBalance);
                    swapping = false;
            }
            bool takeFee = !swapping;
            // if any account belongs to _isExcludedFromFee account then remove the fee
            if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
                takeFee = false;
            }
            if(takeFee) {
                if(automatedMarketMakerPairs[from]){
                    //BUYS
        	        uint256 fees = amount.mul(totalFees).div(100);
        	        amount = amount.sub(fees);
                    super._transfer(from, address(this), fees);
                }else if (automatedMarketMakerPairs[to]){
                    //SELLS
                    uint256 fees = amount.mul(totalFees.add(sellTopUp)).div(100);
         	        amount = amount.sub(fees);
                    super._transfer(from, address(this), fees);
                }else{
                    if(walletFee > 0){
                        uint256 fees = amount.mul(walletFee).div(100);
                        amount = amount.sub(fees);
                        super._transfer(from, address(this), fees);
                    }
                }
            }   
        }
        super._transfer(from, to, amount);
        try dividendTracker.setBalance(from, balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(to, balanceOf(to)) {} catch {}
    }

    function swapBack(uint256 contractTokenBalance) internal {
        uint256 amountToLiquify = contractTokenBalance.mul(liquidityFee).div(totalFees).div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uint256 balanceBefore = address(this).balance;
        swapTokensForEth(amountToSwap);

        uint256 amountMATIC = address(this).balance.sub(balanceBefore);
        uint256 totalMATICFee = totalFees.sub(liquidityFee.div(2));
        uint256 amountMATICLiquidity = amountMATIC.mul(liquidityFee).div(totalMATICFee).div(2);
        uint256 amountMATICReflection = amountMATIC.mul(rewardsFee).div(totalMATICFee);
        uint256 amountMATICMarketing = amountMATIC.mul(marketingFee).div(totalMATICFee);
        
        
        (bool success,) = address(dividendTracker).call{value: amountMATICReflection}("");
        if (success) {
            emit SendDividends(amountMATICReflection);
        }
        (success,) = address(_marketingWalletAddress).call{value: amountMATICMarketing}("");
        if(amountToLiquify > 0){
            addLiquidity(amountToLiquify, amountMATICLiquidity);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {  
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uint256 out = uniswapV2Router.getAmountsOut(tokenAmount, path)[1];
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            out.mul(slippage).div(100), // 15% slippage to cover up to max capFees
            path,
            address(this),
            block.timestamp
        );      
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {        
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            1, // slippage is unavoidable
            1, // slippage is unavoidable
            owner(),
            block.timestamp
        );   
    }

    //Withdraws trapped tokens and send them to a multi-sig marketing wallet
    function withdrawBep20(address token) public onlyOwner nonReentrant{
        require((IERC20(address(token)).balanceOf(address(this)))>0);
        IERC20(token).safeTransfer(_marketingWalletAddress,IERC20(token).balanceOf(address(this)));
    }
    
    //Withdraws trapped MATICs and send them to a multi-sig marketing wallet
    function withdrawMATIC() public onlyOwner nonReentrant {
	    uint256 amountMATIC = address(this).balance;
        (bool success, ) = payable(_marketingWalletAddress).call{value: amountMATIC}("");
        require(success, "transfer failed");
    }

    //READ FUNCTIONS

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

  	function getUserCurrentRewardToken(address holder) external view returns (address){
  	    return dividendTracker.userCurrentRewardToken(holder);
  	}
  	
    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function getDividendTokensMinimum() external view returns (uint256) {
        return dividendTracker.minimumTokenBalanceForDividends();
    }
    function withdrawableDividendOf(address account) public view returns(uint256) {
    	return dividendTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.balanceOf(account);
	}

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(account);
    }

	function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return dividendTracker.getAccountAtIndex(index);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    // determines if a token can be used for rewards
    function isTokenApproved(address tokenAddress) public view returns (bool){
        return dividendTracker.isTokenApproved(tokenAddress);
    }

    // determines if an AMM can be used for rewards
    function isAMMApproved(address ammAddress) public view returns (bool){
        return dividendTracker.isAMMApproved(ammAddress);
    }
}

contract DividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;
    IterableMapping.Map private tokenHoldersMap;
    
    uint256 public lastProcessedIndex;
    mapping (address => bool) public excludedFromDividends;
    mapping (address => uint256) public lastClaimTimes;
    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event IncludeInDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor()  DividendPayingToken("Dividend_Tracker", "Dividend_Tracker") {
    	claimWait = 21600;
        minimumTokenBalanceForDividends = 100 * (10**18); //must hold 100+ tokens
    }
    //WRITE FUNCTIONS
    function _transfer(address, address, uint256) internal override pure {
        //Users can not transfer this token as it has to be 1:1 with the parent token.
        require(false, "");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account],"");
    	excludedFromDividends[account] = true;
    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);
    	emit ExcludeFromDividends(account);
    }

    function includeInDividends(address account, uint256 balance) external onlyOwner {
    	require(excludedFromDividends[account]);
    	excludedFromDividends[account] = false;
        tokenHoldersMap.set(account, balance);
    	emit IncludeInDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "");
        require(newClaimWait != claimWait, "");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function setBalance(address account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}
    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	else {
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}
    }

    function process(uint256 gas) public onlyOwner returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;
    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}
    	uint256 _lastProcessedIndex = lastProcessedIndex;
    	uint256 gasUsed = 0;
    	uint256 gasLeft = gasleft();
    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;
    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}
    		address account = tokenHoldersMap.keys[_lastProcessedIndex];
    		if(canAutoClaim(lastClaimTimes[account])) {
    			if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}
    		iterations++;
    		uint256 newGasLeft = gasleft();
    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}
    		gasLeft = newGasLeft;
    	}
    	lastProcessedIndex = _lastProcessedIndex;
    	return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        if(canAutoClaim(lastClaimTimes[account])){
            uint256 amount = _withdrawDividendOfUser(account);
    	    if(amount > 0) {
    		    lastClaimTimes[account] = block.timestamp;
                emit Claim(account, amount, automatic);
    		    return true;
    	    }
        }
    	return false;
    }

    //READ FUNCTIONS

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}
    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }
}