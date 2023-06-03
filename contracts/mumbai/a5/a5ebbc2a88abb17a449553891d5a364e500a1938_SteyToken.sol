/**
 *Submitted for verification at polygonscan.com on 2023-06-02
*/

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

contract SteyToken is IERC20 {
    string private constant _name = "Stey";
    string private constant _symbol = "STEY";
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 100000000 * 10**uint256(_decimals);
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    // Reflection and Rewards related variables
    mapping(address => uint256) private _reflectedBalances;
    mapping(address => uint256) private _totalReflectedTokens;
    uint256 private _totalTokens;
    
    uint256 private _reflectionFee = 2; // 2% reflection fee
    
    // Message Signature Hash
    mapping(address => bytes32) private _messageSignatureHashes;
    
    constructor() {
        _balances[msg.sender] = _totalSupply;
        _totalTokens = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function name() public pure returns (string memory) {
        return _name;
    }
    
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        if (_totalTokens == 0) {
            return 0;
        }
        if (_reflectedBalances[account] == 0) {
            return 0;
        }
        uint256 currentRate = _getRate();
        return _reflectedBalances[account] / currentRate;
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
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }
    
    function messageSignatureHash() public view returns (bytes32) {
        return _messageSignatureHashes[msg.sender];
    }
    
    function setMessageSignatureHash(bytes32 hash) public {
        require(_messageSignatureHashes[msg.sender] == bytes32(0), "Message signature hash already set");
        _messageSignatureHashes[msg.sender] = hash;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Insufficient balance");
        
        _updateReflection(sender);
        _updateReflection(recipient);
        
        uint256 currentRate = _getRate();
        uint256 reflectionAmount = amount * _reflectionFee / 100;
        uint256 reflectionTransferAmount = reflectionAmount * currentRate;
        uint256 transferAmount = amount - reflectionAmount;
        uint256 transferAmountRate = transferAmount * currentRate;
        
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += transferAmountRate;
        
        _reflectedBalances[sender] -= transferAmountRate + reflectionTransferAmount;
        _reflectedBalances[recipient] += reflectionTransferAmount;
        
        _totalTokens -= reflectionAmount;
        
        emit Transfer(sender, recipient, transferAmount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _updateReflection(address account) internal {
        if (_totalTokens == 0) {
            return;
        }
        uint256 currentRate = _getRate();
        uint256 reflectedAmount = _balances[account] * currentRate;
        _reflectedBalances[account] = reflectedAmount;
        _totalReflectedTokens[account] = _totalTokens;
    }
    
    function _getRate() internal view returns (uint256) {
        (uint256 reflectedSupply, uint256 tokenSupply) = _getCurrentSupply();
        if (reflectedSupply == 0 || tokenSupply == 0) {
            return 0;
        }
        return reflectedSupply / tokenSupply;
    }
    
    function _getCurrentSupply() internal view returns (uint256, uint256) {
        uint256 reflectedSupply = _totalTokens;
        uint256 tokenSupply = _totalTokens;
        
        return (reflectedSupply, tokenSupply);
    }
}