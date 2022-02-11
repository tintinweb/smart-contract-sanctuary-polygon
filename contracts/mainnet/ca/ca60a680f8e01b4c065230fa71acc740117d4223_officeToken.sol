/**
 *Submitted for verification at polygonscan.com on 2022-02-10
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

//interface for ERC20 token standards
interface IERC20{
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

//create contract for OfficeToken
contract officeToken is IERC20{

    //def
    string public name = "Office";
    string public symbol = "OFC";
    uint256 public maxSupply = 100000000;
    uint256 public decimals = 18;
    address owner;

    //def mapping
    mapping(address => uint256) balance;
    mapping(address => mapping(address => uint256)) allowed;


    //initialize 
    constructor(address _contractOwner){
        owner = _contractOwner;
        balance[owner] += maxSupply;
    }

    //functions
    function totalSupply() public view override returns(uint256){
        return maxSupply;
    }

    function balanceOf(address _owner) public view override returns(uint256){
        return balance[_owner];
    }

    function transfer(address _to, uint256 _value) public override returns(bool){
        require(balance[msg.sender] >= _value);
        balance[msg.sender] = balance[msg.sender] - _value;
        balance[_to] = balance[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns(bool){
        require(balance[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        balance[_from] = balance[_from] -= _value;
        balance[_to] = balance[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public override returns(bool){
        allowed[msg.sender][_spender] = _value;
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns(uint256 remaining){
        allowed[_owner][_spender];
        return remaining;
    }
    
    function mint(uint256 _value) public returns(bool){
        require(msg.sender == owner);
        maxSupply = maxSupply + _value;
        balance[owner] += _value;
        emit Transfer(address(0), owner, _value);
        return true;
    }

    function burn(uint256 _value) public returns(bool){
        require(balance[msg.sender] >= _value);
        balance[msg.sender] = balance[msg.sender] -= _value;
        maxSupply = maxSupply -= _value;
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }
}