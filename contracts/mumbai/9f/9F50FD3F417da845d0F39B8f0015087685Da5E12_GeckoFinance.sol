/**
 *Submitted for verification at polygonscan.com on 2023-05-01
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

contract GeckoFinance {
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 public _totalFees;
    mapping(address => uint256) private _reflections;

    address public LpAccount;

    constructor(string memory name_, string memory symbol_, address _lpaccount) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        uint256 initialSupply = 10_000_000 * 10**decimals(); // 10 million tokens with 18 decimals
        LpAccount = _lpaccount;
        _mint(_msgSender(), initialSupply);
        _totalFees = 0;
        _reflections[_msgSender()] = initialSupply;
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
        if (_reflections[account] == 0) return 0;
        return _reflections[account].add(_reflections[account].mul(_totalFees).div(totalSupply()));
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance.sub(amount));

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance.sub(subtractedValue));

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 reflectionFee = amount.mul(10).div(100); // Calculate 10% reflection fee
        uint256 taxFee = amount.mul(5).div(100); // Calculate 5% tax fee
            // Distribute the reflection fee proportionally to all token holders
    _totalFees = _totalFees.add(reflectionFee);
    uint256 totalFees = reflectionFee.add(taxFee);

    uint256 netAmount = amount.sub(totalFees);

    // Update sender's reflection balance
    _reflections[sender] = _reflections[sender].sub(amount);

    _reflections[recipient] = _reflections[recipient].add(netAmount);
    _reflections[LpAccount] = _reflections[LpAccount].add(taxFee);

    _balances[sender] = _balances[sender].sub(amount);
    _balances[LpAccount] = _balances[LpAccount].add(taxFee);
    _balances[recipient] = _balances[recipient].add(netAmount);

    emit Transfer(sender, LpAccount, taxFee);
    emit Transfer(sender, recipient, netAmount);
}

function _mint(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    _reflections[account] = _reflections[account].add(amount);
    emit Transfer(address(0), account, amount);
}

function _burn(address account, uint256 amount) internal {
    require(_reflections[account] >= amount, "ERC20: burn amount exceeds balance");
    _reflections[account] = _reflections[account].sub(amount);
    _balances[account] = _balances[account].sub(amount);
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
}

function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
}

function _msgSender() internal view returns (address) {
    return msg.sender;
}

event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);

}