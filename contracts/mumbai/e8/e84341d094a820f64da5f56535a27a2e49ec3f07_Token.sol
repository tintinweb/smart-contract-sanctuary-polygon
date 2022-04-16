/**
 *Submitted for verification at polygonscan.com on 2022-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.9;
contract Token {

    address public owner;
    address public NullAddress = 0x0000000000000000000000000000000000000000;

    string public name = "TurkeyPunk";
    string public symbol = "Enes";

    string public surprise = "ARDA YARRAMI YE DEDI";
    string public dgko = "'Dogum gunun kutlu olsun eness' -bati";

    uint256 public decimals = 5;
    uint256 public totalSupply = 100 * (10 **decimals);

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(){
        owner = msg.sender;
        balances[NullAddress] = totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_value < balances[msg.sender], "Insufficient balance!");

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    // Owner

    function transferFrom(address sender, address recipient, uint256 _value) public returns (bool success) {
        require(sender != recipient, "You cannot transfer yourself!");
        require(_value <= allowed[sender][recipient], "Insufficient allowance.");
        require(_value <= balances[sender], "Insufficient balance!");

        balances[sender] -= _value;
        allowed[sender][recipient] -= _value;
        
        balances[recipient] += _value;

        emit Transfer(sender, recipient, _value);

        return true;
    }

    function transferOwnership(address _to) public returns (bool success) {
        require(msg.sender == owner, "You are not owner.");

        owner = _to;
        
        return true;
    }

    function mint(address _to, uint256 _value) public returns (bool success) {
        require(msg.sender == owner, "You are not owner.");

        balances[NullAddress] -= _value;
        balances[_to] += _value;
        return true;
    }

    function userAddress() public view returns(address){
        return msg.sender;
    }
}