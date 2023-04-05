/**
 *Submitted for verification at polygonscan.com on 2023-04-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DaoToken {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private constant _name = "TESTNET Token";
    string private constant _symbol = "TESTNET TOKEN";
    uint256 private constant _totalSupply = 1_000_000_000e18;
    uint8 private constant _decimals = 18;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor() payable {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function owner() external pure returns (address) {
        return address(0);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address a) external view returns (uint256) {
        return _balances[a];
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
        _approve(s, msg.sender, _allowances[s][msg.sender] - a);
        _transfer(s, r, a);
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