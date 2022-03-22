// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import './SafeMath.sol';

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20, SafeMath {
    address private contractOwner;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    uint256 private _totalSupply;
    uint8 public decimals;
    string public name;
    string public symbol;

    event Mint(address indexed minter, address indexed account, uint256 amount);
    event Burn(address indexed burner, address indexed account, uint256 amount);

//    constructor(string memory n, string memory s, uint256 ts, uint8 d) {
//        contractOwner = msg.sender;
//        name = n;
//        symbol = s;
//        _totalSupply = ts;
//        balances[msg.sender] = ts;
//        decimals = d;
//    }

    constructor() {
        contractOwner = msg.sender;
        name = 'Minh20';
        symbol = 'm20';
        _totalSupply = 100000000000000000000000;
        balances[msg.sender] = 100000000000000000000000;
        decimals = 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint amount) public virtual override returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], amount);
        balances[to] = safeAdd(balances[to], amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) public virtual override returns (bool success) {
        balances[from] = safeSub(balances[from], amount);
        allowances[from][msg.sender] = safeSub(allowances[from][msg.sender], amount);
        balances[to] = safeAdd(balances[to], amount);
        emit Transfer(from, to, amount);
        return true;
    }

    function mintTo(address to, uint amount) public {
        require(msg.sender == contractOwner, 'not owner');
        require(amount > 0, 'amount is not valid');

        _totalSupply = safeAdd(_totalSupply, amount);
        balances[to] = safeAdd(balances[to], amount);

        emit Mint(msg.sender, to, amount);
    }

    function burnFrom(address from, uint amount) public {
        require(msg.sender == contractOwner, 'not owner');
        require(balances[from] >= amount, 'insufficient balance');

        balances[from] = safeSub(balances[from], amount);
        _totalSupply = safeSub(_totalSupply, amount);

        emit Burn(msg.sender, from, amount);
    }
}

pragma solidity ^0.8.0;

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}