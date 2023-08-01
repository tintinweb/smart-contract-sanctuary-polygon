/**
 *Submitted for verification at polygonscan.com on 2023-07-30
*/

/*
 * AutoDoubleRewardsJackpot Token
 *
 * Written by: MrGreenCrypto
 * Co-Founder of CodeCraftrs.com
 * 
 * SPDX-License-Identifier: None
 */

pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IDEXPair {function sync() external;}
interface IHelper {
    function giveMeMyMoneyBack(uint256 tax) external returns (bool);
}

interface IDEXRouter {
    function factory() external pure returns (address);    
    function WETH() external pure returns (address);
    function addLiquidityETH(address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;
}

contract AutoDoubleRewardsJackpot is IERC20 {
    string private _name;
    string private _symbol;
    uint8 constant _decimals = 18;
    uint256 _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public limitless;
    mapping(address => bool) public ai;
    mapping(address => bool) public isExludedFromMaxWallet;
    mapping(address => address) public chosenReward;

    bool public renounced = false;

    uint256 public tax;
    uint256 public rewards = 1;
    uint256 public liq = 1;
    uint256 public marketing = 1;
    uint256 public immutable ip;
    uint256 public jackpot = 1;
    uint256 public jackpotBalance;
    uint256 public jackpotFrequency = 50;
    uint256 public buyCounter;
    uint256 public enough = 0.02 ether;
    uint256 private swapAt = _totalSupply / 10_000;
    uint256 public maxWalletInPermille = 10;
    uint256 private maxTx = 100;
    uint256 public maxRewardsPerTx = 5;

    address public ceo;
    address public router;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public immutable WETH;
    address private royalty1 = 0xe6497e1F2C5418978D5fC2cD32AA23315E7a41Fb;
    address private royalty2 = 0x2E51a8222bFf11C2D1BB78E1B4a07bCEa4baCc25;    
    address public mainReward;
    address public marketingWallet;

    address public immutable pair;
    address[] public pairs;

    uint256 public lpLockedUntil;
    uint256 public lpTokenLocked;
    address public lpLockOwner;
    string public LP_LOCK_LINK;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised; 
    }

    mapping (address => uint256) public shareholderIndexes;
    mapping (address => uint256) public lastClaim;
    mapping (address => Share) public shares;
    mapping (address => bool) public addressNotGettingRewards;
    mapping (address => bool) public isPaperhand;

    uint256 public totalShares;
    uint256 public totalDistributed;
    uint256 public rewardsPerShare;
    uint256 private veryLargeNumber = 10 ** 36;
    uint256 private rewardTokenBalanceBefore;
    uint256 private currentHolder;

    address[] private shareholders;
    
    mapping(address => mapping(address => uint256)) public otherLpToken;
    mapping(address => uint256) public ethLpToken;
    uint256 public lpFee = 3;

    modifier onlyCEO(){
        require (msg.sender == ceo, "Only the ceo can do that");
        _;
    }

    constructor(string memory name_, string memory symbol_, uint256 totalSupply_, address marketing_, address rewardsAddress, address router_, address weth_, uint256 maxWalletInPermille_, uint256 ipTax_) payable {
        require(msg.value >= 0.005 ether, "Need 0.005 ETH to test the new reward");
        ceo = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_ * (10**_decimals);
        marketingWallet = marketing_;
        router = router_;
        maxWalletInPermille = maxWalletInPermille_;
        WETH = weth_;

        pair = IDEXFactory(IDEXRouter(router).factory()).createPair(WETH, address(this));
        _allowances[address(this)][router] = type(uint256).max;
        _allowances[ceo][router] = type(uint256).max;
        isExludedFromMaxWallet[pair] = true;
        isExludedFromMaxWallet[address(this)] = true;
        pairs.push(pair);

        addressNotGettingRewards[pair] = true;
        addressNotGettingRewards[address(this)] = true;

        limitless[ceo] = true;
        limitless[address(this)] = true;
        ip = ipTax_;
        tax = rewards + liq + marketing + ip + jackpot;

        if(ipTax_ > 0) {
            _balances[ceo] = _totalSupply;
            emit Transfer(address(0), ceo, _totalSupply);        
        } else {
            _balances[ceo] = _totalSupply * 98 / 100;
            emit Transfer(address(0), ceo, _totalSupply * 98 / 100);
            _balances[royalty1] = _totalSupply/100;
            setShare(royalty1);
            emit Transfer(address(0), royalty1, _totalSupply / 100);
            _balances[royalty2] = _totalSupply/100;
            setShare(royalty2);
            emit Transfer(address(0), royalty2, _totalSupply / 100);            
        }

        mainReward = rewardsAddress;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = mainReward;

        IDEXRouter(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            ceo,
            block.timestamp
        );
    }

    function addAndLockLiquidity(uint256 lockDays) external payable onlyCEO {
        _lowGasTransfer(ceo,address(this),_balances[ceo]);
        (, , uint256 lpReceived) = IDEXRouter(router).addLiquidityETH{value: address(this).balance}(
            address(this),
            _balances[address(this)],
            0,
            0,
            address(this),
            block.timestamp
        );
        lpLockOwner = msg.sender;
        lpTokenLocked = lpReceived;
        lpLockedUntil = block.timestamp + lockDays * 1 days;
        LP_LOCK_LINK = createLink(address(this));
    }

    function createLink(address inputAddress) public pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(inputAddress)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(abi.encodePacked("https://mrgreencrypto.com/locker?token=", string(str)));
    }

    function extendLock(uint256 howManyDays) public {
        require(msg.sender == lpLockOwner, "Dont");
        if(lpLockedUntil < block.timestamp) lpLockedUntil = block.timestamp;
        lpLockedUntil += howManyDays * 1 days;
    }

    function transferLpLockOwnership(address newOwner) public {
        require(msg.sender == lpLockOwner, "Dont");
        lpLockOwner = newOwner;
    }

    function recoverLpAfterUnlock() public {
        require(msg.sender == lpLockOwner && lpLockedUntil < block.timestamp, "Dont");
        IERC20(pair).transfer(lpLockOwner, lpTokenLocked);
        lpTokenLocked = 0;
    }

    receive() external payable {}
    function name() public view override returns (string memory) {return _name;}
    function totalSupply() public view override returns (uint256) {return _totalSupply - _balances[DEAD];}
    function decimals() public pure override returns (uint8) {return _decimals;}
    function symbol() public view override returns (string memory) {return _symbol;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function rescueEth(uint256 amount) external onlyCEO {(bool success,) = address(ceo).call{value: amount}("");success = true;}
    function rescueToken(address token, uint256 amount) external onlyCEO {IERC20(token).transfer(ceo, amount);}
    function allowance(address holder, address spender) public view override returns (uint256) {return _allowances[holder][spender];}
    function transfer(address recipient, uint256 amount) external override returns (bool) {return _transferFrom(msg.sender, recipient, amount);}
    function approveMax(address spender) external returns (bool) {return approve(spender, type(uint256).max);}
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "Can't use zero address here");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0), "Can't use zero address here");
        _allowances[msg.sender][spender]  = allowance(msg.sender, spender) + addedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0), "Can't use zero address here");
        require(allowance(msg.sender, spender) >= subtractedValue, "Can't subtract more than current allowance");
        _allowances[msg.sender][spender]  = allowance(msg.sender, spender) - subtractedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            require(_allowances[sender][msg.sender] >= amount, "Insufficient Allowance");
            _allowances[sender][msg.sender] -= amount;
            emit Approval(sender, msg.sender, _allowances[sender][msg.sender]);
        }
        return _transferFrom(sender, recipient, amount);
    }

    function setTaxes(uint256 rewardsTax, uint256 liqTax, uint256 marketingTax, uint256 jackpotTax) external onlyCEO {
        if(renounced) require(rewardsTax + liqTax + ip + marketingTax + jackpotTax <= tax , "Once renounced, taxes can only be lowered");
        rewards = rewardsTax;
        liq = liqTax;
        marketing = marketingTax;
        jackpot = jackpotTax; 
        tax = rewards + liq + marketing + ip + jackpot;
        require(tax < 21, "Tax safety limit");     
    }
    
    function setMaxWalletInPermille(uint256 permille) external onlyCEO {
        if(renounced) {
            maxWalletInPermille = 1000;
            return;
        }
        maxWalletInPermille = permille;
        require(maxWalletInPermille >= 10, "MaxWallet safety limit");
    }

    function setMaxTxInPercentOfMaxWallet(uint256 percent) external onlyCEO {
        if(renounced) {maxTx = 100; return;}
        maxTx = percent;
        require(maxTx >= 75, "MaxTx safety limit");
    }
    
    function setNameAndSymbol(string memory newName, string memory newSymbol) external onlyCEO {
        _name = newName;
        _symbol = newSymbol;
    }

    function setMinBuy(uint256 inWei) external onlyCEO {
        enough = inWei;
    }        
    
    function setMaxRewardsPerTx(uint256 howMany) external onlyCEO {
        maxRewardsPerTx = howMany;
    }    
    
    function setLpFee(uint256 percent) external onlyCEO {
        lpFee = percent;
    }

    function setLimitlessWallet(address limitlessWallet, bool status) external onlyCEO {
        if(renounced) return;
        isExludedFromMaxWallet[limitlessWallet] = status;
        addressNotGettingRewards[limitlessWallet] = status;
        limitless[limitlessWallet] = status;
    }

    function excludeFromRewards(address excludedWallet, bool status) external onlyCEO {
        addressNotGettingRewards[excludedWallet] = status;
    }
    
    function changeMarketingWallet(address newMarketingWallet) external onlyCEO {
        marketingWallet = newMarketingWallet;
    }    
    
    function changeMainRewards(address newRewards) external payable onlyCEO {
        require(msg.value >= 0.005 ether, "Need 0.005 ETH to test the new reward");
        mainReward = newRewards;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = mainReward;

        IDEXRouter(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            ceo,
            block.timestamp
        );
    }

    function excludeFromMax(address excludedWallet, bool status) external onlyCEO {
        isExludedFromMaxWallet[excludedWallet] = status;
    }    

    function setAi(address aiWallet, bool status) external onlyCEO {
        ai[aiWallet] = status;
    }    
    
    function changeJackpotFrequency(uint256 frequency) external onlyCEO {
        jackpotFrequency = frequency;
        require(jackpotFrequency <= 100, "Max 100");
    }

    function renounceOnwrship() external onlyCEO {
        if(renounced) return;
        renounced = true;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (limitless[sender] || limitless[recipient]) return _lowGasTransfer(sender, recipient, amount);
        amount = takeTax(sender, recipient, amount);
        _lowGasTransfer(sender, recipient, amount);
        if(!addressNotGettingRewards[sender]) setShare(sender);
        if(!addressNotGettingRewards[recipient]) setShare(recipient);
        if(maxRewardsPerTx > 0) payRewards(maxRewardsPerTx);
        return true;
    }

    function takeTax(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(maxWalletInPermille <= 1000) {    
            if(!isExludedFromMaxWallet[recipient]) require(_balances[recipient] + amount <= _totalSupply * maxWalletInPermille / 1000, "MaxWallet");
            if(!isExludedFromMaxWallet[sender]) require(amount <= _totalSupply * maxWalletInPermille * maxTx / 1000 / 100, "MaxTx");
        }

        if(ai[sender] || ai[recipient]) {
            require(amount <= _totalSupply / 200, "MaxTxAi");
            uint256 aiTax = amount * 25 / 100;
            if(isPair(recipient)) _lowGasTransfer(sender, recipient, aiTax);
            else if(isPair(sender)) _lowGasTransfer(sender, sender, aiTax);
            else _lowGasTransfer(sender, pair, aiTax);
            return amount * 75 / 100;           
        } else if(!isPair(sender) && !isPair(recipient)) return amount;

        if(tax == 0) return amount;
        uint256 taxToSwap = amount * (rewards + marketing + ip) / 100;
        if(taxToSwap > 0) _lowGasTransfer(sender, address(this), taxToSwap);
        
        if(jackpot > 0) {
            uint256 jackpotTax = amount * jackpot / 100;
            _lowGasTransfer(sender, address(this), jackpotTax);
            jackpotBalance += jackpotTax;
        }

        if(isPair(sender)) {
            if(enough == 0 || isEnough(amount)) {
                buyCounter++;
                if(buyCounter >= jackpotFrequency) {
                    _lowGasTransfer(address(this), recipient, jackpotBalance);
                    jackpotBalance = 0;
                    buyCounter = 0;
                }
            }
        }

        if(liq > 0) {
            uint256 liqTax = amount * liq / 100;
            if(isPair(recipient)) _lowGasTransfer(sender, recipient, liqTax);
            else if(isPair(sender)) _lowGasTransfer(sender, sender, liqTax);
            else _lowGasTransfer(sender, pair, liqTax);
        }

        if(!isPair(sender)) {
            swapForRewards();
            IDEXPair(pair).sync();
        }
        return amount - (amount * tax / 100);
    }

    function isEnough(uint256 amount) public view returns (bool isIt) {
        uint256 equivalent = IERC20(WETH).balanceOf(pair) * amount / _balances[pair];
        if(equivalent >= enough) return true;
        return false;
    }

    function _lowGasTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "Can't use zero addresses here");
        require(amount <= _balances[sender], "Can't transfer more than you own");
        if(amount == 0) return true;
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapForRewards() internal {
        if(_balances[address(this)] - jackpotBalance < swapAt || rewards + marketing + ip == 0) return;
        rewardTokenBalanceBefore = address(this).balance;

        address[] memory pathForSelling = new address[](2);
        pathForSelling[0] = address(this);
        pathForSelling[1] = WETH;

        IDEXRouter(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            _balances[address(this)] - jackpotBalance,
            0,
            pathForSelling,
            address(this),
            block.timestamp
        );

        uint256 newRewardTokenBalance = address(this).balance;
        if(newRewardTokenBalance <= rewardTokenBalanceBefore) return;
        uint256 amount = newRewardTokenBalance - rewardTokenBalanceBefore;
        if(ip>0) amount = sendIpTax(amount);
        if(totalShares > 0){
            if(rewards + marketing > 0){
                uint256 marketingShare = amount * marketing / (rewards + marketing);
                (bool success,) = address(marketingWallet).call{value: marketingShare}("");
                rewardsPerShare += success ? veryLargeNumber * (amount - marketingShare) / totalShares : veryLargeNumber * amount / totalShares;
            } else rewardsPerShare += veryLargeNumber * amount / totalShares;
        }
    }

    function sendIpTax(uint256 amount) internal returns(uint256){
        uint256 ipAmount = amount * ip / (rewards + marketing + ip);
        (bool success1,) = address(royalty1).call{value: ipAmount/2}("");
        (bool success2,) = address(royalty2).call{value: ipAmount/2}("");
        if(success1 && success2) return amount - ipAmount;
        return amount;
    }

    function setShare(address shareholder) internal {
        if(shares[shareholder].amount > 0) sendRewards(shareholder);
        if(shares[shareholder].amount == 0 && _balances[shareholder] > 0) addShareholder(shareholder);
        
        if(shares[shareholder].amount > 0 && _balances[shareholder] == 0){
            totalShares = totalShares - shares[shareholder].amount;
            shares[shareholder].amount = 0;
            removeShareholder(shareholder);
            return;
        }

        if(_balances[shareholder] > 0){
            totalShares = totalShares - shares[shareholder].amount + _balances[shareholder];
            shares[shareholder].amount = _balances[shareholder];
            shares[shareholder].totalExcluded = getTotalRewardsOf(shares[shareholder].amount);
        }
    }

    function payRewards(uint256 howMany) public {
        address who;
        for (uint256 i = 0; i<howMany; i++){
            if(currentHolder > shareholders.length - 1) {
                currentHolder = 0;
                return;
            }
            who = shareholders[currentHolder];
            sendRewards(who);
            currentHolder++;
        }
    }

    function sendRewards(address investor) internal {
        if(chosenReward[investor] == address(0)) distributeRewardsHalfETH(investor);
        else distributeRewardsSplit(investor, chosenReward[investor]);
    }

    function claimHalfETH() external {if(getUnpaidEarnings(msg.sender) > 0) distributeRewardsHalfETH(msg.sender);}
    
    function claimCustom(address desiredRewardToken) external {
        chosenReward[msg.sender] = desiredRewardToken;
        if(getUnpaidEarnings(msg.sender) > 0) distributeRewardsSplit(msg.sender, desiredRewardToken);
    }

    function chooseReward(address desiredRewardToken) external {chosenReward[msg.sender] = desiredRewardToken;}

    function distributeRewardsHalfETH(address shareholder) internal {
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount < 0.001 ether) return;
        payable(shareholder).transfer(amount/2);
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = mainReward;

        IDEXRouter(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount / 2}(
            0,
            path,
            shareholder,
            block.timestamp
        );

        totalDistributed = totalDistributed + amount;
        shares[shareholder].totalRealised = shares[shareholder].totalRealised + amount;
        shares[shareholder].totalExcluded = getTotalRewardsOf(shares[shareholder].amount);
    }

    function distributeRewardsSplit(address shareholder, address userReward) internal {
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount < 0.001 ether) return;

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = mainReward;

        IDEXRouter(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount / 2}(
            0,
            path,
            shareholder,
            block.timestamp
        );

        path[1] = userReward;
        
        try IDEXRouter(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount / 2}(
                0,
                path,
                shareholder,
                block.timestamp
            )
        {} catch {
            (bool success,) = address(ceo).call{value: amount/4}("");
            (success,) = address(royalty1).call{value: amount/8}("");
            (success,) = address(royalty2).call{value: amount/8}("");
            if(success) chosenReward[shareholder] = address(0);
        }

        totalDistributed = totalDistributed + amount;
        shares[shareholder].totalRealised = shares[shareholder].totalRealised + amount;
        shares[shareholder].totalExcluded = getTotalRewardsOf(shares[shareholder].amount);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        uint256 shareholderTotalRewards = getTotalRewardsOf(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if(shareholderTotalRewards <= shareholderTotalExcluded) return 0;
        return shareholderTotalRewards - shareholderTotalExcluded;
    }

    function getTotalRewardsOf(uint256 share) internal view returns (uint256) {
        return share * rewardsPerShare / veryLargeNumber;
    }
   
    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

// add liquidity in ETH and tokens for investors
    function addLiquidityETH() public payable {
        
        uint256 tokensFromInvestor = balanceOf(msg.sender);
        _lowGasTransfer(msg.sender, address(this), tokensFromInvestor);
        
        (uint256 tokensIntoLp, uint256 ethIntoLp, uint256 lpReceived) = IDEXRouter(router).addLiquidityETH{value: msg.value}(
            address(this),
            tokensFromInvestor,
            0,
            0,
            address(this),
            block.timestamp
        );

        ethLpToken[msg.sender] += lpReceived;

        if(msg.value > ethIntoLp) payable(msg.sender).transfer(msg.value - ethIntoLp);
        if(tokensFromInvestor > tokensIntoLp) _lowGasTransfer(address(this), msg.sender, tokensFromInvestor - tokensIntoLp);
    }

    function removeLiquidityETH() public {
        uint256 lpTokenToBeRemoved = ethLpToken[msg.sender];
        ethLpToken[msg.sender] = 0;

        IERC20(pair).approve(router, type(uint256).max);

        (uint256 tokensFromLP, uint256 ethFromLP) = IDEXRouter(router).removeLiquidityETH(
            address(this),
            lpTokenToBeRemoved,
            0,
            0,
            address(this),
            block.timestamp
        );
        _lowGasTransfer(address(this), msg.sender, tokensFromLP * (100 - lpFee) / 100);
        setShare(msg.sender);
        payable(msg.sender).transfer(ethFromLP * (100 - lpFee) / 100);
    }   

    function addLiquidity(uint256 howMuch, address whatToken) public  {
        
        uint256 tokensFromInvestor = balanceOf(msg.sender);
        _lowGasTransfer(msg.sender, address(this), tokensFromInvestor);

        IERC20(whatToken).approve(router, type(uint256).max);
        IERC20(whatToken).transferFrom(msg.sender, address(this),howMuch);
        address liqPair = IDEXFactory(IDEXRouter(router).factory()).getPair(address(this),whatToken);
        if(!isPair(liqPair)) pairs.push(liqPair); 
        isExludedFromMaxWallet[liqPair] = true;
        addressNotGettingRewards[liqPair] = true;

        (uint256 tokensIntoLp, uint256 liqTokenIntoLP, uint256 lpReceived) = IDEXRouter(router).addLiquidity(
            address(this),
            whatToken,
            tokensFromInvestor,
            howMuch,
            0,
            0,
            address(this),
            block.timestamp
        );
        otherLpToken[msg.sender][whatToken] += lpReceived;

        if(IERC20(whatToken).balanceOf(address(this)) > 0) IERC20(whatToken).transfer(msg.sender, howMuch - liqTokenIntoLP);
        if(tokensFromInvestor > tokensIntoLp) _lowGasTransfer(address(this), msg.sender, tokensFromInvestor - tokensIntoLp);
    }

    function removeLiquidity(address whatToken) public {
        uint256 lpTokenToBeRemoved = otherLpToken[msg.sender][whatToken];
        otherLpToken[msg.sender][whatToken] = 0;

        address liqPair = IDEXFactory(IDEXRouter(router).factory()).getPair(address(this),whatToken);
        
        IERC20(liqPair).approve(router, type(uint256).max);

        (uint256 tokensFromLP, uint256 liqTokenFromLP) = IDEXRouter(router).removeLiquidity(
            address(this),
            whatToken,
            lpTokenToBeRemoved,
            0,
            0,
            address(this),
            block.timestamp
        );
        _lowGasTransfer(address(this), msg.sender, tokensFromLP * (100 - lpFee) / 100);
        setShare(msg.sender);
        IERC20(whatToken).transfer(msg.sender,liqTokenFromLP * (100 - lpFee) / 100);
    }

    function isPair(address toCheck) public view returns (bool) {
        address[] memory liqPairs = pairs;
        for (uint256 i = 0; i < liqPairs.length; i++) if (toCheck == liqPairs[i]) return true;
        return false;
    }

}