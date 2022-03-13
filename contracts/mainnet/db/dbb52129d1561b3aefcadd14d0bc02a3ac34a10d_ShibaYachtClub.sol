/**
 *Submitted for verification at polygonscan.com on 2022-03-13
*/

/**
ShibaYachtClub - $SYC

https://t.me/Shiba_Yacht_Club

 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;
    constructor(address _owner) {owner = _owner;authorizations[_owner] = true;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    modifier authorized() {require(isAuthorized(msg.sender), "!AUTHORIZED"); _;}
    function authorize(address adr) public onlyOwner {authorizations[adr] = true;}
    function unauthorize(address adr) public onlyOwner {authorizations[adr] = false;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function isAuthorized(address adr) public view returns (bool) {return authorizations[adr];}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr;authorizations[adr] = true;emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDexFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(address tokenA,address tokenB,uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin,address to,uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(address tokenA,address tokenB,uint liquidity,uint amountAMin,uint amountBMin,address to,uint deadline) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(address token,uint liquidity,uint amountTokenMin,uint amountETHMin,address to,uint deadline) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(address tokenA,address tokenB,uint liquidity,uint amountAMin,uint amountBMin,address to,uint deadline,bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(address token,uint liquidity,uint amountTokenMin,uint amountETHMin,address to,uint deadline,bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountOut,uint amountInMax,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function removeLiquidityETHSupportingFeeOnTransferTokens(address token,uint liquidity,uint amountTokenMin,uint amountETHMin,address to,uint deadline) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token,uint liquidity,uint amountTokenMin,uint amountETHMin,address to,uint deadline,bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin,address[] calldata path,address to,uint deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender,uint amount0In,uint amount1In,uint amount0Out,uint amount1Out,address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}


contract ShibaYachtClub is IBEP20, Auth {

	address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

	string constant _name = "Shiba Yacht Club";
    string constant _symbol = "SYC";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 500_000_000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply / 100;
	uint256 public _maxWalletAmount = _totalSupply / 50;

	mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isLimitlessAddress;
    

	// Fees. Some may be completely inactive at all times.
	uint256 liquidityFee = 10;
    uint256 marketingFee = 70;
    uint256 burnFee = 0;
	uint256 stakingFee = 10;
	uint256 lpStakingFee = 10;
    uint256 sellMultiplier = 2;
    uint256 sellDenominator = 1;
    uint256 feeDenominator = 1000;
    uint256 sellFeeOnWebsite = 180;
    uint256 buyFeeOnWebsite = 90;
	bool public feeOnNonTrade = false;

	uint256 public stakingPrizePool = 0;
	bool public stakingRewardsActive = false;
	address public stakingRewardsContract;
	uint256 public lpStakingPrizePool = 0;
	bool public lpStakingRewardsActive = false;
	address public lpStakingRewardsContract;
    bool public projectFeesActivated = false;

	address public autoLiquidityReceiver;
    address public marketingWallet = 0x35ED6ab8cBAAcfeF3F948E3a048BfBf57FE7706C;
    address public devWallet;
    address public projectWallet;


	IDexRouter public router;
    address pcs2BNBPair;
    address[] public pairs;

	bool public swapEnabled = true;
    bool private security = true;
    bool private isSell = true;

    uint256 public swapThreshold = _totalSupply / 20000;
    uint256 public maxSwapAmount = _totalSupply / 100;
    bool inSwap;
    modifier swapping() {
		inSwap = true;
		_;
		inSwap = false;
	}


	uint256 public launchedAt = 0;
	bool private gasLimitActive = true;
    
	event AutoLiquifyEnabled(bool enabledOrNot);
	event AutoLiquify(uint256 amountBNB, uint256 autoBuybackAmount);
	event StakingRewards(bool activate);
	event lpStakingRewards(bool active);
    event TokensBoughtOnWebsite(address buyer, uint256 amount);
    event TokensSoldOnWebsite(address seller, uint256 amount);

	constructor() Auth(msg.sender) {

		router = IDexRouter(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        pcs2BNBPair = IDexFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        

		isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
		isTxLimitExempt[msg.sender] = true;
		isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;

		autoLiquidityReceiver = msg.sender;
		pairs.push(pcs2BNBPair);
		_balances[msg.sender] = _totalSupply;
		emit Transfer(address(0), msg.sender, _totalSupply);
	}

	receive() external payable {}
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

	function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
			require(_allowances[sender][msg.sender] >= amount, "Insufficient Allowance");
            _allowances[sender][msg.sender] -= amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

	function _isStakingReward(address sender, address recipient) internal view returns (bool) {
		return sender == stakingRewardsContract
			|| sender == lpStakingRewardsContract
			|| recipient == stakingRewardsContract
			|| recipient == lpStakingRewardsContract;
	}

    function _isLimitlessAddress(address sender, address recipient) internal view returns (bool) {
		if(isLimitlessAddress[sender] || isLimitlessAddress[recipient]){
            return true;
        } else {
            return false;
        }
	}
    
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(amount > 0);
        if (inSwap || _isStakingReward(sender, recipient) || _isLimitlessAddress(sender, recipient)) {
            return _basicTransfer(sender, recipient, amount);
        }

        checkTxLimit(sender, recipient, amount);

        if (shouldSwapBack()) {
            liquify();
        }

        if (!launched() && recipient == pcs2BNBPair) {
            require(_balances[sender] > 0);
            require(sender == owner, "Only the owner can be the first to add liquidity.");
            launch();
        }

		require(amount <= _balances[sender], "Insufficient Balance");
        _balances[sender] -= amount;

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, amount) : amount;
        _balances[recipient] += amountReceived;

		// Update staking pool, if active.
		// Update of the pool can be deactivated for launch and staking contract migration.
		if (stakingRewardsActive) {
			sendToStakingPool();
		}
		if (lpStakingRewardsActive) {
			sendToLpStakingPool();
		}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

	function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(amount <= _balances[sender], "Insufficient Balance");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

	function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender] || isTxLimitExempt[recipient] && sender == pcs2BNBPair, "TX Limit Exceeded");
		// Max wallet check.
		if (sender != owner
            && recipient != owner
            && !isTxLimitExempt[recipient]
            && recipient != ZERO 
            && recipient != DEAD 
            && recipient != pcs2BNBPair 
            && recipient != address(this)
        ) {
            uint256 newBalance = balanceOf(recipient) + amount;
            require(newBalance <= _maxWalletAmount, "Exceeds max wallet.");
        }
    }

	// Decides whether this trade should take a fee.
	// Trades with pairs are always taxed, unless sender or receiver is exempted.
	// Non trades, like wallet to wallet, are configured, untaxed by default.
	function shouldTakeFee(address sender, address recipient) internal returns (bool) {
        if (isFeeExempt[sender] || isFeeExempt[recipient] || !launched()) {
            return false;
        }
        address[] memory liqPairs = pairs;

        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (sender == liqPairs[i] ) {
                isSell = false;
                return true;
            }
        }
        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (recipient == liqPairs[i]) {
                isSell = true;
                return true;
            }
        }

        return feeOnNonTrade;
    }

	function takeFee(address sender, uint256 amount) internal returns (uint256) {
		if (!launched()) {
			return amount;
		}
		uint256 swapFee = 0;
		uint256 bf = 0;
		uint256 steak = 0;
		uint256 lpStake = 0;

			// If there is a liquidity tax active for autoliq, the contract keeps it.
			if (liquidityFee + marketingFee > 0) {
				swapFee = amount * (marketingFee + liquidityFee) / feeDenominator;
				if(isSell){
                    swapFee = swapFee * sellMultiplier / sellDenominator;
                }
                _balances[address(this)] += swapFee;
				emit Transfer(sender, address(this), swapFee);
			}
			// If there is an active burn fee, burn a percentage and give it to dead address.
			if (burnFee > 0) {
				bf = amount * burnFee / feeDenominator;
                if(isSell){
                    bf = bf * sellMultiplier / sellDenominator;
                }
				_balances[DEAD] += bf;
				emit Transfer(sender, DEAD, bf);
			}
			// If staking tax is active, it is stored on ZERO address.
			// If staking payout itself is active, it is later moved from ZERO to the appropriate staking address.
			if (stakingFee > 0) {
				steak = amount * stakingFee / feeDenominator;
				if(isSell){
                    steak = steak * sellMultiplier / sellDenominator;
                }
                _balances[ZERO] += steak;
				stakingPrizePool += steak;
				emit Transfer(sender, ZERO, steak);
			}
			if (lpStakingFee > 0) {
				lpStake = amount * lpStakingFee / feeDenominator;
                if(isSell){
                    lpStake = lpStake * sellMultiplier / sellDenominator;
                }
				_balances[ZERO] += lpStake;
				lpStakingPrizePool += lpStake;
				emit Transfer(sender, ZERO, lpStake);
			}

        return amount - swapFee - bf - steak - lpStake;
    }

	function sendToStakingPool() internal {
		_balances[ZERO] -= stakingPrizePool;
		_balances[stakingRewardsContract] += stakingPrizePool;
		emit Transfer(ZERO, stakingRewardsContract, stakingPrizePool);
		stakingPrizePool = 0;
	}

	function sendToLpStakingPool() internal {
		_balances[ZERO] -= lpStakingPrizePool;
		_balances[lpStakingRewardsContract] += lpStakingPrizePool;
		emit Transfer(ZERO, lpStakingRewardsContract, lpStakingPrizePool);
		lpStakingPrizePool = 0;
	}

	function setStakingRewardsAddress(address addy) external authorized {
		stakingRewardsContract = addy;
		isFeeExempt[addy] = true;
		isTxLimitExempt[addy] = true;
	}

	function setLpStakingRewardsAddress(address addy) external authorized {
		lpStakingRewardsContract = addy;
		isFeeExempt[addy] = true;
		isTxLimitExempt[addy] = true;
	}

    function shouldSwapBack() internal view returns (bool) {
        return launched()
			&& msg.sender != pcs2BNBPair
            && !inSwap
            && swapEnabled
            && _balances[address(this)] >= swapThreshold;
    }

	function setSwapEnabled(bool set) external authorized {
		swapEnabled = set;
		emit AutoLiquifyEnabled(set);
	}

	function liquify() internal swapping {
        uint256 contractBalance = balanceOf(address(this));
        if(contractBalance > maxSwapAmount) {
            contractBalance = maxSwapAmount;
        }

        uint256 amountToLiquidity = contractBalance * liquidityFee / (liquidityFee + marketingFee) / 2;
        uint256 amountToSwapForBNB = contractBalance - amountToLiquidity;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwapForBNB,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNBLiquidity = address(this).balance * (liquidityFee / 2) / ((liquidityFee / 2) + marketingFee);

		router.addLiquidityETH{value: amountBNBLiquidity}(
			address(this),
			amountToLiquidity,
			0,
			0,
			autoLiquidityReceiver,
			block.timestamp
		);

        if(projectFeesActivated){
            uint256 bnbFeesPercent = address(this).balance / marketingFee;
            payable(devWallet).transfer(bnbFeesPercent);
            payable(projectWallet).transfer(bnbFeesPercent);
        }
        
        payable(marketingWallet).transfer(address(this).balance);

		emit AutoLiquify(amountBNBLiquidity, amountToLiquidity);
    }

    function BuyDirectlyFromContract() payable external swapping {
        uint256 bnbAmount = msg.value;
        uint256 taxes = buyFeeOnWebsite * bnbAmount / 100;
        bnbAmount -= taxes;
    
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbAmount}(
            0,
            path,
            msg.sender,
            block.timestamp
        );
        
        if(projectFeesActivated){
            uint256 bnbFeesPercent = address(this).balance / marketingFee;
            payable(devWallet).transfer(bnbFeesPercent);
            payable(projectWallet).transfer(bnbFeesPercent);
        }
        
        payable(marketingWallet).transfer(address(this).balance);
        
        emit TokensBoughtOnWebsite(msg.sender, msg.value);
    }


    function SellDirectlyToContract(uint256 _tokenAmount) external swapping {
        _tokenAmount = _tokenAmount * 10**18;

        uint256 initialBalance = address(this).balance;

        require(balanceOf(msg.sender) >= _tokenAmount,"Cannot sell more than you own");
         if(_allowances[address(this)][address(router)] < type(uint256).max){
            approve(address(router), type(uint256).max);
        }

        _balances[msg.sender] -= _tokenAmount;
        _balances[address(this)] += _tokenAmount;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 bnbFromSell = address(this).balance - initialBalance;
        uint256 taxes = sellFeeOnWebsite * bnbFromSell / feeDenominator;
        
        bnbFromSell -= taxes;
        payable(msg.sender).transfer(bnbFromSell);
       
        if(projectFeesActivated){
            uint256 bnbFeesPercent = address(this).balance / marketingFee;
            payable(devWallet).transfer(bnbFeesPercent);
            payable(projectWallet).transfer(bnbFeesPercent);
        }
        
        payable(marketingWallet).transfer(address(this).balance);

        emit TokensSoldOnWebsite(msg.sender, _tokenAmount);
        
    }

	function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

	function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

	function setMaxWallet(uint256 amount) external authorized {
		require(amount >= _totalSupply / 1000);
		_maxWalletAmount = amount;
	}

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setLimitlessAddress(address addy, bool state) external authorized {
        isLimitlessAddress[addy] = state;
    }


    function setFees(uint256 _liquidityFee, uint256 _marketingFee, uint256 _burnFee, uint256 _stakingFee, uint256 _lpStakingFee, uint256 _feeDenominator, bool _projectFeesActivated, uint256 _sellMultiplier, uint256 _sellDenominator) external authorized {
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        burnFee = _burnFee;
		stakingFee = _stakingFee;
		lpStakingFee = _lpStakingFee;
        feeDenominator = _feeDenominator;
        sellMultiplier = _sellMultiplier;
        sellDenominator = _sellDenominator;
        projectFeesActivated = _projectFeesActivated;
		uint256 totalFee = _marketingFee + _liquidityFee + _burnFee + _stakingFee + _lpStakingFee;
        require(totalFee * _sellMultiplier / _sellDenominator < feeDenominator / 4, "Maximum allowed taxation on this contract is 20%.");
    }

    function setLiquidityReceiver(address _autoLiquidityReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;	
    }
    
    function setMarketingWallet(address _marketingWallet) external authorized {
        marketingWallet = _marketingWallet;	
    }

    function setProjectWallet(address _projectWallet) external authorized {
        projectWallet = _projectWallet;	
    }
    
    function setDevWallet(address _devWallet) external authorized {
        devWallet = _devWallet;	
    }

	function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO) + stakingPrizePool + lpStakingPrizePool;
    }

	// Recover any BNB sent to the contract by mistake.
	function rescue() external {
        payable(owner).transfer(address(this).balance);
    }

	function setStakingRewardsActive(bool active) external authorized {
		stakingRewardsActive = active;
		emit StakingRewards(active);
	}

	function setLpStakingRewardsActive(bool active) external authorized {
		lpStakingRewardsActive = active;
		emit lpStakingRewards(active);
	}

	function addPair(address pair) external authorized {
        pairs.push(pair);
    }
    
    function removeLastPair() external authorized {
        pairs.pop();
    }
}