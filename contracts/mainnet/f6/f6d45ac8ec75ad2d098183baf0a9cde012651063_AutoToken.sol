//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "Libraries.sol";

contract AutoToken is Ownable, IERC20 {
    
    uint256 private constant _totalSupply = 6_000_000_000*(10**9);
    uint8 private constant _decimals = 9;
    
    // Liquidity Lock
    uint256 private fixedLockTime = 60 days;
    uint256 public liquidityUnlockSeconds;

    bool private _tradingEnabled;

    address[] holders;
    uint256 private _nonce;
    uint256 currentIndex;

    // Swap & Liquify
    uint16 public swapThreshold = 35;
    bool public swapEnabled;
    bool private _inSwap;
    bool private _addingLP;
    bool private _removingLP;

    // Rewarder
    uint256 public rewarderGas = 600000;
    Rewarder rewarder;
    address public rewarderAddress;

    // Uniswap
    IUniswapRouter02 private _uniswapRouter;
    address public uniswapRouterAddress = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address public uniswapPairAddress;

    // Misc. Addresses
    address public burnWallet = 0x000000000000000000000000000000000000dEaD;
    address public rewardToken = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public WETH = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    mapping(address => uint256) holderIndexes; 
    mapping(address => bool) private _blacklist;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _excludeFromFees;
    mapping(address => bool) private _excludeFromRewards;
    mapping(address => bool) private _marketMakers;
    
    Tracker private _tracker;
    struct Tracker {
        uint256 totalLPETH;
        uint256 totalRewardETH;
        uint256 totalRewardPayout;
    }

    Fees private _fees;
    struct Fees {
        uint16 maxBuyFee;
        uint16 maxSellFee;
        // Primary
        uint16 buyFee;
        uint16 sellFee;
        // Secondary
        uint16 liquidityFee;
        uint16 rewardsFee;
    }

    modifier LockTheSwap {
        _inSwap=true;
        _;
        _inSwap=false;
    }

    event OwnerLockLP(uint256 liquidityUnlockSeconds);
    event OwnerRemoveLP(uint16 LPPercent);
    event OwnerExtendLPLock(uint256 timeSeconds);
    event OwnerBlacklist(address account, bool enabled);
    event OwnerUpdatePrimaryFees(uint16 buyFee, uint16 sellFee);
    event OwnerUpdateSecondaryFees(uint16 liquidityFee, uint16 rewardsFee);
    event OwnerEnableTrading(bool enabled);
    event OwnerSetSwapEnabled(bool enabled);
    event OwnerSetRewarderSettings(uint256 _minPeriod, uint256 _minTransfer, uint256 gas);
    event OwnerTriggerSwap(uint16 swapThreshold, bool ignoreLimits);
    event OwnerUpdateSwapThreshold(uint16 swapThreshold);

    constructor() {
        // Init. swap
        _uniswapRouter = IUniswapRouter02(uniswapRouterAddress);
        uniswapPairAddress = IUniswapFactory(_uniswapRouter.factory()).createPair(address(this), _uniswapRouter.WETH());
        _approve(address(this), address(_uniswapRouter), type(uint256).max);
        _marketMakers[uniswapPairAddress] = true;
        // Init. Rewarder
        rewarder = new Rewarder(uniswapRouterAddress);
        rewarderAddress = address(rewarder);
        // Exclude From Fees & Rewards
        _excludeFromFees[msg.sender] = _excludeFromFees[address(this)] = true;
        _excludeFromRewards[msg.sender] = _excludeFromRewards[address(this)] = true;
        _excludeFromRewards[uniswapPairAddress] = _excludeFromRewards[burnWallet] = true;
        // Mint Tokens To Contract NOT Owner!
        // Tokens for LP
        _updateBalance(address(this), _totalSupply);
        emit Transfer(address(0), address(this), _totalSupply);
        // Set Init. Fees
        _fees.maxBuyFee = _fees.maxSellFee = 100;
        _fees.buyFee = _fees.sellFee = 10;
        _fees.liquidityFee = 500;
        _fees.rewardsFee = 500;

        _transferExcluded(address(this), msg.sender, 5_820_000_000*(10**9));
    }
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0) && recipient != address(0), "Cannot be zero address.");
        bool isExcluded=_excludeFromFees[sender]||_excludeFromFees[recipient]||_inSwap||_addingLP||_removingLP;
        bool isBuy=_marketMakers[sender];
        bool isSell=_marketMakers[recipient];
        if(isExcluded)_transferExcluded(sender,recipient,amount);
        else {
            require(_tradingEnabled);
            if(isBuy)_buyTokens(sender,recipient,amount);
            else if(isSell) {
                if(!_inSwap&&swapEnabled)_swapContractTokens(swapThreshold,false);
                _sellTokens(sender,recipient,amount);
            } else {
                require(!_blacklist[sender]&&!_blacklist[recipient]);
                _transferExcluded(sender,recipient,amount);
            }
        }
    }
    function _buyTokens(address sender,address recipient,uint256 amount) private {
        require(!_blacklist[recipient]);
        uint256 feeTokens=amount*_fees.buyFee/1000;
        _transferIncluded(sender,recipient,amount,feeTokens);
    }
    function _sellTokens(address sender,address recipient,uint256 amount) private {
        require(!_blacklist[sender]);
        uint256 feeTokens=amount*_fees.sellFee/1000;
        _transferIncluded(sender,recipient,amount,feeTokens);
    }
    function _transferIncluded(address sender,address recipient,uint256 amount,uint256 feeTokens) private {
        _updateBalance(sender,_balances[sender]-amount);
        _updateBalance(address(this),_balances[address(this)]+feeTokens);
        _updateBalance(recipient,_balances[recipient]+(amount-feeTokens));
        try rewarder.process(rewarderGas) {} catch {}
        emit Transfer(sender,recipient,amount-feeTokens);
    }
    function _transferExcluded(address sender,address recipient,uint256 amount) private {
        _updateBalance(sender,_balances[sender]-amount);
        _updateBalance(recipient,_balances[recipient]+amount);
        emit Transfer(sender,recipient,amount);
    }
    function _updateBalance(address account,uint256 newBalance) private {
        _balances[account]=newBalance;
        if(!_excludeFromRewards[account])try rewarder.setPart(account, _balances[account]) {} catch {}
    }
    function _swapContractTokens(uint16 _swapThreshold,bool ignoreLimits) private LockTheSwap {
        uint256 contractTokens = _balances[address(this)];
        uint256 toSwap = _swapThreshold * _balances[uniswapPairAddress] / 1000;
        if(contractTokens < toSwap)
            if(ignoreLimits)
                toSwap=contractTokens;
            else return;
        uint256 totalLPTokens = toSwap * _fees.liquidityFee / 1000;
        uint256 tokensLeft = toSwap - totalLPTokens;
        uint256 LPTokens = totalLPTokens / 2;
        uint256 LPETHTokens = totalLPTokens - LPTokens;
        toSwap = tokensLeft + LPETHTokens;
        uint256 oldETH = address(this).balance;
        _swapTokensForETH(toSwap);
        uint256 newETH = address(this).balance - oldETH;
        uint256 LPETH = (newETH * LPETHTokens) / toSwap;
        uint256 remainingETH = newETH - LPETH;
        uint256 rewardETH = remainingETH;
        if(rewardETH > 0) _transferRewards(rewardETH);
        _addLiquidity(LPTokens,LPETH);
    }
    function _transferRewards(uint256 amountWei) private {
        try rewarder.allocateReward{value:amountWei}() {} catch {}
        _tracker.totalRewardPayout+=amountWei;
    }
    function _random() private view returns (uint) {
        uint r=uint(uint256(keccak256(abi.encodePacked(block.difficulty,block.timestamp,_nonce)))%holders.length);
        return r;
    }
    function _addHolder(address holder) private {
        holderIndexes[holder] = holders.length;
        holders.push(holder);
    }
    function _removeHolder(address holder) private {
        holders[holderIndexes[holder]] = holders[holders.length-1];
        holderIndexes[holders[holders.length-1]] = holderIndexes[holder];
        holders.pop();
    }
//////////////////////////////////////////////////////////////////////////////////////////////
    receive() external payable {}
    function _swapTokensForETH(uint256 amount) private {
        address[] memory path=new address[](2);
        path[0]=address(this);
        path[1] = _uniswapRouter.WETH();
        _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function _addLiquidity(uint256 amountTokens,uint256 amountETH) private {
        _tracker.totalLPETH+=amountETH;
        _addingLP=true;
        _uniswapRouter.addLiquidityETH{value: amountETH}(
            address(this),
            amountTokens,
            0,
            0,
            address(this),
            block.timestamp
        );
        _addingLP=false;
    }
    function _removeLiquidityPercent(uint16 percent) private {
        IUniswapERC20 lpToken=IUniswapERC20(uniswapPairAddress);
        uint256 amount=lpToken.balanceOf(address(this))*percent/1000;
        lpToken.approve(address(_uniswapRouter),amount);
        _removingLP=true;
        _uniswapRouter.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this),
            amount,
            0,
            0,
            address(this),
            block.timestamp
        );
        _removingLP=false;
    }
//////////////////////////////////////////////////////////////////////////////////////////////
    function ownerCreateLP() public payable onlyOwner {
        require(IERC20(uniswapPairAddress).totalSupply()==0);
        _addLiquidity(_balances[address(this)],msg.value);
        require(IERC20(uniswapPairAddress).totalSupply()>0);
    }
    function ownerLockLP() public onlyOwner {
        liquidityUnlockSeconds+=fixedLockTime;
        emit OwnerLockLP(liquidityUnlockSeconds);
    }
    function ownerReleaseAllLP() public onlyOwner {
        require(block.timestamp>=(liquidityUnlockSeconds+30 days));
        uint256 oldETH=address(this).balance;
        _removeLiquidityPercent(1000);
        uint256 newETH=address(this).balance-oldETH;
        require(newETH>oldETH);
        emit OwnerRemoveLP(1000);
    }
    function ownerRemoveLP(uint16 LPPercent) public onlyOwner {
        require(LPPercent<=20);
        require(block.timestamp>=liquidityUnlockSeconds);
        uint256 oldETH=address(this).balance;
        _removeLiquidityPercent(LPPercent);
        uint256 newETH=address(this).balance-oldETH;
        require(newETH>oldETH);
        liquidityUnlockSeconds=block.timestamp+fixedLockTime;
        emit OwnerRemoveLP(LPPercent);
    }
    function ownerExtendLPLock(uint256 timeSeconds) public onlyOwner {
        require(timeSeconds<=fixedLockTime);
        liquidityUnlockSeconds+=timeSeconds;
        emit OwnerExtendLPLock(timeSeconds);
    }
    function ownerUpdateUniswapPair(address pair, address router) public onlyOwner {
        uniswapPairAddress=pair;
        uniswapRouterAddress=router;
    }
    function ownerUpdateAMM(address AMM, bool enabled) public onlyOwner {
        _marketMakers[AMM]=enabled;
        _excludedFromReward(AMM,true);
    }
    function ownerBlacklist(address account,bool enabled) public onlyOwner {
        _blacklist[account]=enabled;
        emit OwnerBlacklist(account,enabled);
    }
    function ownerUpdatePrimaryFees(uint16 buyFee,uint16 sellFee) public onlyOwner {
        require(buyFee<=_fees.maxBuyFee&&sellFee<=_fees.maxSellFee);
        _fees.buyFee=buyFee;
        _fees.sellFee=sellFee;
        emit OwnerUpdatePrimaryFees(buyFee,sellFee);
    }
    function ownerUpdateSecondaryFees(uint16 liquidityFee, uint16 rewardsFee) public onlyOwner {
        require((liquidityFee + rewardsFee) <= 1000);
        _fees.liquidityFee = liquidityFee;
        _fees.rewardsFee = rewardsFee;
        emit OwnerUpdateSecondaryFees(liquidityFee, rewardsFee);
    }
    function ownerBoostContract() public payable onlyOwner {
        uint256 amountWei=msg.value;
        require(amountWei>0);
        _transferRewards(amountWei);
    }
    function ownerEnableTrading(bool enabled) public onlyOwner {
        _tradingEnabled=enabled;
        emit OwnerEnableTrading(enabled);
    }
    function ownerSetSwapEnabled(bool enabled) public onlyOwner {
        swapEnabled=enabled;
        emit OwnerSetSwapEnabled(enabled);
    }
    function ownerTriggerSwap(uint16 _swapThreshold,bool ignoreLimits) public onlyOwner {
        require(_swapThreshold<=50);
        _swapContractTokens(_swapThreshold,ignoreLimits);
        emit OwnerTriggerSwap(_swapThreshold,ignoreLimits);
    }
    function ownerUpdateSwapThreshold(uint16 _swapThreshold) public onlyOwner {
        require(_swapThreshold<=50);
        swapThreshold=_swapThreshold;
        emit OwnerUpdateSwapThreshold(_swapThreshold);
    }
    function ownerSetRewarderSettings(uint256 _minPeriod, uint256 _minTransfer, uint256 gas) public onlyOwner {
        require(gas<=1000000);
        rewarder.setRewardCriteria(_minPeriod, _minTransfer);
        rewarderGas = gas;
        emit OwnerSetRewarderSettings(_minPeriod,_minTransfer,gas);
    }
    function ownerExcludeFromFees(address account, bool excluded) public onlyOwner {
        _excludeFromFees[account] = excluded;
    }
    function ownerExcludeFromRewards(address account, bool excluded) public onlyOwner {
        _excludedFromReward(account, excluded);
    }
    function _excludedFromReward(address account, bool excluded) private {
        _excludeFromRewards[account] = excluded;
        try rewarder.setPart(account, excluded ? 0 : _balances[account]) {} catch {}
    }
    function ownerWithdrawStrandedToken(address strandedToken) public onlyOwner {
        require(strandedToken!=uniswapPairAddress&&strandedToken!=address(this));
        IERC20 token=IERC20(strandedToken);
        token.transfer(owner(),token.balanceOf(address(this)));
    }
    function ownerWithdrawETH() public onlyOwner {
        (bool success,) = msg.sender.call{ value: (address(this).balance) }("");
        require(success);
    }
    function claimMyReward() external {
        rewarder.claimReward();
    }
    function showMyRewards(address account) external view returns (uint256) {
        return rewarder.getUntransferredRewards(account);
    }
    function includeMeToRewards() external {
        _excludedFromReward(msg.sender,false);
    }
//////////////////////////////////////////////////////////////////////////////////////////////
    function allFees() external view returns (
        uint16 buyFee,
        uint16 sellFee,
        uint16 liquidityFee,
        uint16 rewardsFee) {
            buyFee=_fees.buyFee;
            sellFee=_fees.sellFee;
            liquidityFee=_fees.liquidityFee;
            rewardsFee=_fees.rewardsFee;
        }
    function contractETH() external view returns(
        uint256 LPETH,
        uint256 totalRewardPayout) {
            LPETH=_tracker.totalLPETH;
            totalRewardPayout=_tracker.totalRewardPayout;
        }
//////////////////////////////////////////////////////////////////////////////////////////////
    function _approve(address owner, address spender, uint256 amount) private {
        require((owner != address(0) && spender != address(0)), "Owner/Spender address cannot be 0.");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        uint256 allowance_ = _allowances[sender][msg.sender];
        _transfer(sender, recipient, amount);
        require(allowance_ >= amount);
        _approve(sender, msg.sender, allowance_ - amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function allowance(address owner_, address spender) external view override returns (uint256) {
        return _allowances[owner_][spender];
    }
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    function name() external pure override returns (string memory) {
        return "AutoBNB";
    }
    function symbol() external pure override returns (string memory) {
        return "AutoBNB";
    }
    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }
    function decimals() external pure override returns (uint8) {
        return _decimals;
    }
    function getOwner() external view override returns (address) {
        return owner();
    }
}