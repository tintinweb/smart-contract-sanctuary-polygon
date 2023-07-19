// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Token is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    uint256 private _reflectionBalance;
    mapping(address => uint256) private _reflectionBalanceOwned;
    mapping(address => bool) private _isExcludedFromReflection;
    
    uint256 private _totalReflections;
    uint256 private _totalFeeAmount;
    
    uint256 private _taxFeePercent = 5;
    uint256 private _marketingFeePercent = 5;
    
    address private _marketingWallet;
    
    constructor(string memory name_, string memory symbol_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_ * 10 ** uint256(_decimals);
        _balances[msg.sender] = _totalSupply;
        _reflectionBalanceOwned[msg.sender] = type(uint256).max;
        _isExcludedFromReflection[msg.sender] = true;
        _marketingWallet = msg.sender;
        
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReflection[account]) {
            return _balances[account];
        }
        return tokenFromReflection(_reflectionBalanceOwned[account]);
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }
    
    function totalReflections() public view returns (uint256) {
        return _totalReflections;
    }
    
    function totalFeeAmount() public view returns (uint256) {
        return _totalFeeAmount;
    }
    
    function excludeFromReflection(address account) public {
        require(!_isExcludedFromReflection[account], "Account is already excluded");
        if (_reflectionBalanceOwned[account] > 0) {
            uint256 reflectionAmount = _reflectionBalanceOwned[account];
            uint256 tokenAmount = tokenFromReflection(reflectionAmount);
            _reflectionBalance -= reflectionAmount;
            _totalSupply -= tokenAmount;
            _balances[account] = 0;
            emit Transfer(account, address(0), tokenAmount);
        }
        _isExcludedFromReflection[account] = true;
    }
    
    function includeInReflection(address account) public {
        require(_isExcludedFromReflection[account], "Account is not excluded");
        _isExcludedFromReflection[account] = false;
        uint256 tokenAmount = _balances[account];
        uint256 reflectionAmount = reflectionFromToken(tokenAmount);
        _totalSupply += tokenAmount;
        _reflectionBalance += reflectionAmount;
        _reflectionBalanceOwned[account] = reflectionAmount;
        emit Transfer(address(0), account, tokenAmount);
    }
    
    function setTaxFeePercent(uint256 taxFeePercent) external {
        require(msg.sender == _marketingWallet, "Only marketing wallet can set tax fee");
        _taxFeePercent = taxFeePercent;
    }
    
    function setMarketingFeePercent(uint256 marketingFeePercent) external {
        require(msg.sender == _marketingWallet, "Only marketing wallet can set marketing fee");
        _marketingFeePercent = marketingFeePercent;
    }
    
    function setMarketingWallet(address marketingWallet) external {
        require(msg.sender == _marketingWallet, "Only marketing wallet can set new marketing wallet");
        _marketingWallet = marketingWallet;
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_balances[sender] >= amount, "Insufficient balance");
        
        uint256 taxFee = amount * _taxFeePercent / 100;
        uint256 marketingFee = amount * _marketingFeePercent / 100;
        uint256 tokensToTransfer = amount - taxFee - marketingFee;
        
        _balances[sender] -= amount;
        _balances[recipient] += tokensToTransfer;
        
        // Update reflection balances
        if (!_isExcludedFromReflection[sender]) {
            uint256 reflectionAmount = reflectionFromToken(amount);
            _reflectionBalance -= reflectionAmount;
            _reflectionBalanceOwned[sender] -= reflectionAmount;
        }
        
        if (!_isExcludedFromReflection[recipient]) {
            uint256 reflectionAmount = reflectionFromToken(tokensToTransfer);
            _reflectionBalance += reflectionAmount;
            _reflectionBalanceOwned[recipient] += reflectionAmount;
        }
        
        // Take tax fee
        if (taxFee > 0) {
            _takeFee(taxFee);
        }
        
        // Take marketing fee
        if (marketingFee > 0) {
            _takeFee(marketingFee);
            emit Transfer(sender, _marketingWallet, marketingFee);
        }
        
        emit Transfer(sender, recipient, tokensToTransfer);
    }
    
    function _takeFee(uint256 feeAmount) private {
        _totalFeeAmount += feeAmount;
        _reflectionBalance += feeAmount;
        _totalReflections += feeAmount;
    }
    
    function reflectionFromToken(uint256 tokenAmount) private view returns (uint256) {
        require(_totalSupply > 0, "Total supply must be greater than zero");
        return tokenAmount * _reflectionBalance / _totalSupply;
    }
    
    function tokenFromReflection(uint256 reflectionAmount) private view returns (uint256) {
        require(_reflectionBalance > 0, "Reflection balance must be greater than zero");
        return reflectionAmount * _totalSupply / _reflectionBalance;
    }
}