/**
 *Submitted for verification at polygonscan.com on 2023-06-03
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

contract Pennies is IERC20 {
    string public constant name = "Pennies";
    string public constant symbol = "CENT";
    uint8 public constant decimals = 0;
    uint256 public constant override totalSupply = 10000000000; // override the totalSupply variable
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address private _owner;
    bool private _paused;

    constructor() {
        _owner = msg.sender;
        _balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function.");
        _;
    }

    modifier notPaused() {
        require(!_paused, "Contract is paused.");
        _;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override notPaused returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override notPaused returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override notPaused returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function pause() public onlyOwner {
        _paused = true;
    }

    function unpause() public onlyOwner {
        _paused = false;
    }

    function renounceOwnership() public onlyOwner {
        _owner = address(0);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "Transfer from the zero address.");
        require(recipient != address(0), "Transfer to the zero address.");
        require(_balances[sender] >= amount, "Insufficient balance.");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Approve from the zero address.");
        require(spender != address(0), "Approve to the zero address.");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}