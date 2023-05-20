/**
 *Submitted for verification at polygonscan.com on 2023-05-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

contract Helios {
    using SafeMath for uint256;

    string public name = "Helios";
    string public symbol = "HLS";
    uint8 public decimals = 18;
    uint256 public totalSupply = 4_000_000_000 * (10 ** uint256(decimals));

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    address public developmentWallet;
    uint256 public sellTaxPercentage = 1;
    address private owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(address _developmentWallet) {
        balances[msg.sender] = totalSupply;
        developmentWallet = _developmentWallet;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view returns (uint256) {
        return allowances[_owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function setSellTaxPercentage(uint256 taxPercentage) external onlyOwner {
        require(taxPercentage <= 100, "Tax percentage cannot exceed 100");
        sellTaxPercentage = taxPercentage;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(

0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 transferAmount = amount.sub(amount.mul(sellTaxPercentage).div(100));
        uint256 taxAmount = amount.mul(sellTaxPercentage).div(100);
        uint256 developmentAmount = taxAmount.div(2);

        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(transferAmount);
        balances[developmentWallet] = balances[developmentWallet].add(developmentAmount);

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, developmentWallet, developmentAmount);
    }

    function _approve(address _owner, address spender, uint256 amount) internal {
        require(_owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function withdrawDevelopmentFunds() external onlyOwner {
        uint256 developmentBalance = balances[developmentWallet];
        require(developmentBalance > 0, "No funds available for withdrawal");

        balances[developmentWallet] = 0;
        balances[owner] = balances[owner].add(developmentBalance);

        emit Transfer(developmentWallet, owner, developmentBalance);
    }
}