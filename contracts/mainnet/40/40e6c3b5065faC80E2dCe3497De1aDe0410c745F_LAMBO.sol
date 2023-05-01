/**
 *Submitted for verification at polygonscan.com on 2023-05-01
*/

// SPDX-License-Identifier: MIT

//twitter: @lambomemecoin


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

contract LAMBO is IERC20 {
    string public constant name = "LAMBO";
    string public constant symbol = "LAMBO";
    uint256 public decimals = 18;
    uint256 public totalSupply = 420 * 10**9 * 10**18;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    address public constant marketingWallet = 0x8d97D1820D540E0a2a4bd5F9372C4B76a924C980;
    uint256 public constant feePercentage = 42;

    constructor() {
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        uint256 fee = _value * feePercentage / 10000;
        uint256 transferAmount = _value - fee;

        balances[msg.sender] -= _value;
        balances[_to] += transferAmount;
        balances[marketingWallet] += fee;

        emit Transfer(msg.sender, _to, transferAmount);
        emit Transfer(msg.sender, marketingWallet, fee);

        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        uint256 fee = _value * feePercentage / 10000;
        uint256 transferAmount = _value - fee;

        balances[_from] -= _value;
        balances[_to] += transferAmount;
        balances[marketingWallet] += fee;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, transferAmount);
        emit Transfer(_from, marketingWallet, fee);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}


//LAMBO is a community-driven cryptocurrency that aims
// to create a decentralized ecosystem for users to participate in.
// Our mission is to create a digital asset that embodies the values of the crypto community,
// such as decentralization, transparency, and inclusivity.
// By doing so, we hope to provide a platform for users to achieve their financial goals
// and participate in a community that shares their values.

//pepe and doge drive lambo