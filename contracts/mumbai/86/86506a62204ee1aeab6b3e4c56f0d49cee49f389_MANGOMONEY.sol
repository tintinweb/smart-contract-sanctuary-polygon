/**
 *Submitted for verification at polygonscan.com on 2023-05-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MANGOMONEY {
    string public name = "MANGOMONEY";
    string public symbol = "MNGM";
    uint256 public totalSupply = 30000000 * 10 ** 18;
    uint8 public decimals = 18;
    address public owner;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => bool) locked;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokenLocked(address indexed account, bool locked);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(!locked[msg.sender], "Your account is locked");
        require(_value > 0, "Invalid amount");

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "Invalid spender address");

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(!locked[_from], "From account is locked");
        require(_value > 0, "Invalid amount");
        require(_value <= allowed[_from][msg.sender], "Insufficient allowance");

        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");

        address previousOwner = owner;
        owner = _newOwner;

        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function lockAccount(address _account, bool _locked) public onlyOwner {
        locked[_account] = _locked;

        emit TokenLocked(_account, _locked);
    }
}