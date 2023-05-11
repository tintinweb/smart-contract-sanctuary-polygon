/**
 *Submitted for verification at polygonscan.com on 2023-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Ownable {
    error NotOwner();

    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Token is Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _symbol;
    string private _name;
    uint256 private constant _decimals = 18;
    uint256 private _totalSupply = 5_000_000e18;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event SymbolChanged(string symbol);
    event NameChanged(string name);

    constructor(string memory newName, string memory newSymbol) payable {
        _name = newName;
        _symbol = newSymbol;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _totalSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function setTokenNameAndSymbol(
        string memory newName,
        string memory newSymbol
    ) external onlyOwner {
        _name = newName;
        _symbol = newSymbol;
        emit NameChanged(_name);
        emit SymbolChanged(_symbol);
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function decimals() external pure returns (uint256) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address r, uint256 a) external returns (bool) {
        _transfer(msg.sender, r, a);
        return true;
    }

    function allowance(address o, address s) external view returns (uint256) {
        return _allowances[o][s];
    }

    function approve(address s, uint256 a) external returns (bool) {
        _approve(msg.sender, s, a);
        return true;
    }

    function transferFrom(
        address s,
        address r,
        uint256 a
    ) external returns (bool) {
        _transfer(s, r, a);
        _approve(s, msg.sender, _allowances[s][msg.sender] - a);
        return true;
    }

    function increaseAllowance(address s, uint256 v) external returns (bool) {
        _approve(msg.sender, s, _allowances[msg.sender][s] + v);
        return true;
    }

    function decreaseAllowance(address s, uint256 v) external returns (bool) {
        _approve(msg.sender, s, _allowances[msg.sender][s] - v);
        return true;
    }

    function _transfer(address s, address r, uint256 a) private {
        _balances[s] -= a;
        _balances[r] += a;
        emit Transfer(s, r, a);
    }

    function _approve(address o, address s, uint256 a) private {
        _allowances[o][s] = a;
        emit Approval(o, s, a);
    }
}