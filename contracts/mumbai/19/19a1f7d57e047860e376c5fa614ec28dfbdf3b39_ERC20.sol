/**
 *Submitted for verification at polygonscan.com on 2022-07-17
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract ERC20 {

    string public name;
    string public symbol;

    uint constant public decimals = 18;
    uint public totalSupply;

    address public owner;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;

    event Transfer(address _sender, address _recipient, uint _amount);
    event Approve(address _sender, address _recipient, uint _amount);
    event Topics(address indexed sender, uint256 indexed n1, uint256 indexed n2,  uint256 n3, uint256 n4, uint256 n5);
    
    constructor(string memory _name, string memory _symbol, uint _amount) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        totalSupply = _amount;
        balances[owner] = _amount;
        emit Transfer(address(0), msg.sender, _amount);
    }

    function balanceOf(address _addr) view public returns (uint){
        return balances[_addr];
    }

    function transfer(address _recipient, uint _amount) public returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint _amount) public returns (bool) {
        require(allowed[_sender][_recipient] >= _amount, "NotInAllowed");
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function approve(address _recipient, uint _amount) public returns (bool){
        allowed[msg.sender][_recipient] = _amount;
        emit Approve(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner,  address _spender) public view returns (uint) {
        return allowed[_owner][_spender];
    }

    function _transfer(address _sender, address _recipient, uint _amount) private {
        balances[_sender] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_sender, _recipient, _amount);
    }
}