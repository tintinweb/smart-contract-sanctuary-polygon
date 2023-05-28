/**
 *Submitted for verification at polygonscan.com on 2023-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NewNairaToken {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _blacklisted;
    bool private _paused;
    address private _owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AddressBlacklisted(address indexed account, bool isBlacklisted);
    event Paused();
    event Unpaused();

    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Contract is not paused");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    constructor() {
        _name = "NEW Naira";
        _symbol = "NNGN";
        _decimals = 18;
        _totalSupply = 1000000000 * 10 ** _decimals;
        _balances[msg.sender] = _totalSupply;
        _paused = false;
        _owner = msg.sender;

        emit Transfer(address(0), msg.sender, _totalSupply);
        emit OwnershipTransferred(address(0), msg.sender);
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

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function isAddressBlacklisted(address account) public view returns (bool) {
        return _blacklisted[account];
    }

    function transfer(address recipient, uint256 amount) public whenNotPaused returns (bool) {
        require(recipient != address(0), "Transfer to zero address");
        require(amount <= _balances[msg.sender], "Insufficient balance");
        require(!_blacklisted[msg.sender], "Sender is blacklisted");
        require(!_blacklisted[recipient], "Recipient is blacklisted");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public whenNotPaused returns (bool) {
        require(spender != address(0), "Approve to zero address");

        _allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public whenNotPaused returns (bool) {
        require(recipient != address(0), "Transfer to zero address");
        require(amount <= _balances[sender], "Insufficient balance");
        require(!_blacklisted[sender], "Sender is blacklisted");
        require(!_blacklisted[recipient], "Recipient is blacklisted");
        require(amount <= _allowances[sender][msg.sender], "Insufficient allowance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(address account, uint256 amount) external onlyOwner whenNotPaused {
        require(account != address(0), "Mint to zero address");

        _totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) external whenNotPaused {
        require(amount <= _balances[msg.sender], "Insufficient balance");

        _balances[msg.sender] -= amount;
        _totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
    }

    function changeOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");

        _owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }

    function blacklistAddress(address account, bool isBlacklisted) external onlyOwner {
        _blacklisted[account] = isBlacklisted;

        emit AddressBlacklisted(account, isBlacklisted);
    }

    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused();
    }
}