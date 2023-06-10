/**
 *Submitted for verification at polygonscan.com on 2023-06-09
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

contract flexy is IERC20 {
    string public constant name = "eLASTIcOIN";
    string public constant symbol = "ELAS";
    uint8 public constant decimals = 18;
    uint256 private _totalSupply;
    uint256 private _maxSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address private _owner;

    constructor() {
        _maxSupply = 1000000 * 10 ** decimals; // Maximum supply of 1,000,000 tokens with decimals
        _totalSupply = 0;
        _balances[msg.sender] = _totalSupply;
        _owner = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the contract owner can call this function");
        _;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, 0);
        _approve(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function mint(address account, uint256 amount) public onlyOwner returns (bool) {
        require(account != address(0), "ERC20: mint to the zero address");
        require(_totalSupply + amount <= _maxSupply, "ERC20: total supply exceeds max supply");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        require(_balances[msg.sender] >= amount, "ERC20: insufficient balance");
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function distribute(address[] calldata recipients, uint256[] calldata amounts) public onlyOwner {
        require(recipients.length == amounts.length, "ERC20: recipients and amounts length mismatch");
        for (uint256 i = 0; i < recipients.length; i++) {
            require(amounts[i] <= _balances[msg.sender], "ERC20: insufficient balance");
            _balances[msg.sender] -= amounts[i];
            _balances[recipients[i]] += amounts[i];
            emit Transfer(msg.sender, recipients[i], amounts[i]);
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: insufficient balance");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}