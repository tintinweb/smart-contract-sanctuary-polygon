/**
 *Submitted for verification at polygonscan.com on 2023-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8 .0;

interface IERC20 {
	function balanceOf(address account) external view returns(uint256);
	function transfer(address recipient, uint256 amount) external returns(bool);
	function allowance(address owner, address spender) external view returns(uint256);
	function approve(address spender, uint256 amount) external returns(bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router02 {
	function WETH() external pure returns(address);
	function swapExactTokensForETH(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns(uint[] memory amounts);
}

contract HushDoge is IERC20 {
	string public name = "HDI3";
	string public symbol = "HDI3";
	uint8 public decimals = 18;
	uint256 public totalSupply = 1_000_000_000 * 10 ** uint256(decimals);
	uint256 public maxTransactionAmount = totalSupply / 200; // 0.5% of total supply

	mapping(address => uint256) public balances;
	mapping(address => mapping(address => uint256)) private _allowances;
	mapping(address => uint256) public rewardsLedger;
	mapping(address => uint256) public lastClaimed;
    mapping(address => bool) private _feeExempt;

	uint256 public rewardsFee = 2;
	uint256 private _tTotalRewards;
	address private _owner;
	address private _dipBuyingFund;
	uint256 public dipBuyingFee = 2;
	IUniswapV2Router02 public uniswapRouter;
	uint256 public collectedFees;
	uint256 public swapThreshold = 10_000 * 10 ** uint256(decimals);
	bool public tradingEnabled = false;

	constructor(address uniswapRouterAddress) {
        balances[msg.sender] = totalSupply;
        _owner = msg.sender;
        _feeExempt[msg.sender] = true; // set contract deployer as fee exempt
        emit Transfer(address(0), msg.sender, totalSupply);

        _dipBuyingFund = msg.sender;
        uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);
    }

	modifier onlyOwner() {
		require(_owner == msg.sender, "Ownable: caller is not the owner");
		_;
	}

	modifier tradingAllowed() {
		require(tradingEnabled || msg.sender == _owner, "HushDoge: trading is currently disabled");
		_;
	}

	function enableTrading() external onlyOwner {
		require(!tradingEnabled, "HushDoge: trading is already enabled");
		tradingEnabled = true;
	}

    function setFeeExempt(address account, bool exempt) external onlyOwner {
        _feeExempt[account] = exempt;
    }

	function transfer(address recipient, uint256 amount) public override tradingAllowed returns(bool) {
		require(recipient != address(0), "HushDoge: transfer to the zero address");
		require(amount > 0, "HushDoge: transfer amount must be greater than zero");
		require(amount <= maxTransactionAmount, "HushDoge: transfer amount exceeds the max transaction amount");

		_updateRewards(msg.sender);
		_updateRewards(recipient);

		uint256 rewards = _calculateRewards(amount);
		uint256 dipBuyingAmount = _calculateDipBuyingAmount(amount);
		uint256 transferAmount = amount - rewards - dipBuyingAmount;

		balances[msg.sender] -= amount;
		balances[recipient] += transferAmount;
		_tTotalRewards += rewards;

		_collectFees(dipBuyingAmount);

		emit Transfer(msg.sender, recipient, transferAmount);
		return true;
	}

	function _updateRewards(address account) private {
		uint256 rewards = calculateUnclaimedRewards(account);
		rewardsLedger[account] += rewards;
		lastClaimed[account] = _tTotalRewards;
	}

	function _calculateRewards(uint256 _amount) private view returns(uint256) {
		return _amount * rewardsFee / 100;
	}

	function _calculateDipBuyingAmount(uint256 _amount) private view returns(uint256) {
		return _amount * dipBuyingFee / 100;
	}

	function _collectFees(uint256 dipBuyingAmount) private {
        if (_feeExempt[msg.sender]) {
            return;
        }

        collectedFees += dipBuyingAmount;

        if (collectedFees >= swapThreshold) {
            uint256 initialBalance = address(this).balance;
            uint256 amountToSwap = collectedFees;
            collectedFees = 0;

            _swapTokensForETH(amountToSwap);

            uint256 swappedBalance = address(this).balance - initialBalance;
            _transferETHToDipBuyingFund(swappedBalance);
        }
    }

	function _swapTokensForETH(uint256 tokenAmount) private {
		// Generate the uniswap pair path of token -> WETH
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = uniswapRouter.WETH();

		// Approve uniswapRouter to spend tokens
		_approve(address(this), address(uniswapRouter), tokenAmount);

		// Swap tokens for ETH
		uniswapRouter.swapExactTokensForETH(
			tokenAmount,
			0, // Accept any amount of ETH
			path,
			address(this),
			block.timestamp + 120
		);
	}

	function _transferETHToDipBuyingFund(uint256 amount) private {
		payable(_dipBuyingFund).transfer(amount);
	}

	function claimRewards() external {
		_updateRewards(msg.sender);
		uint256 rewards = rewardsLedger[msg.sender];
		require(rewards > 0, "HushDoge: no rewards to claim");
		balances[msg.sender] += rewards;
		rewardsLedger[msg.sender] = 0;
		emit Transfer(address(this), msg.sender, rewards);
	}

	function balanceOf(address account) public view override returns(uint256) {
		return balances[account];
	}

	function approve(address spender, uint256 amount) public override returns(bool) {
		_approve(msg.sender, spender, amount);
		return true;
	}

	function _approve(address owner, address spender, uint256 amount) private {
		require(owner != address(0), "HushDoge: approve from the zero address");
		require(spender != address(0), "HushDoge: approve to the zero address");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function transferFrom(address sender, address recipient, uint256 amount) public override returns(bool) {
        require(amount <= _allowances[sender][msg.sender], "HushDoge: transfer amount exceeds allowance");
        _updateRewards(sender);
        _updateRewards(recipient);
        uint256 rewards = _calculateRewards(amount);
        uint256 dipBuyingAmount = _calculateDipBuyingAmount(amount);
        uint256 transferAmount = amount - rewards - dipBuyingAmount;
        balances[sender] -= amount;
        balances[recipient] += transferAmount;
        _tTotalRewards += rewards;
        _collectFees(dipBuyingAmount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        emit Transfer(sender, recipient, transferAmount);
        return true;
    }

	function allowance(address owner, address spender) public view override returns(uint256) {
		return _allowances[owner][spender];
	}

	function increaseAllowance(address spender, uint256 addedValue) public returns(bool) {
		_approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool) {
		uint256 oldValue = _allowances[msg.sender][spender];
		require(oldValue >= subtractedValue, "HushDoge: decreased allowance below zero");
		_approve(msg.sender, spender, oldValue - subtractedValue);
		return true;
	}

	function setRewardsFee(uint256 fee) external onlyOwner {
		require(fee >= 0 && fee <= 10, "HushDoge: fee must be between 0 and 10");
		rewardsFee = fee;
	}

	function setMaxTransactionAmount(uint256 amount) external onlyOwner {
		require(amount > 0, "HushDoge: max transaction amount must be greater than zero");
		maxTransactionAmount = amount;
	}

	function totalRewards() external view returns(uint256) {
		return _tTotalRewards;
	}

	function rewardsOf(address account) external view returns(uint256) {
		return rewardsLedger[account];
	}

	function calculateUnclaimedRewards(address account) public view returns(uint256) {
		uint256 lastClaimedRewards = lastClaimed[account];
		uint256 newRewards = _tTotalRewards - lastClaimedRewards;
		uint256 accountBalance = balances[account];
		return accountBalance * newRewards / totalSupply;
	}

    function setDipBuyingFee(uint256 fee) external onlyOwner {
        require(fee >= 0 && fee <= 10, "HushDoge: fee must be between 0 and 10");
        dipBuyingFee = fee;
    }


	function totalRewardsTaxCollected() external view returns(uint256) {
		return _tTotalRewards;
	}
}