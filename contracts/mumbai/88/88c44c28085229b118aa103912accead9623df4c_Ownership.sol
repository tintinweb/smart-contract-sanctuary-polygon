/**
 *Submitted for verification at polygonscan.com on 2022-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
contract Ownership{
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 indexed value);
    mapping (address=>uint) private balance;
    mapping(address=>mapping(address=>uint256)) private _allowances;

    string private name_;
    string private symbol_;
    uint256 private decimal = 18;
    uint private totalsupply_;
    address public owner;
    address private Contractowner;

    constructor(string memory _name,string memory _symbol,uint _total){
        name_ = _name;
        symbol_ = _symbol;
        totalsupply_ = _total;
        owner = msg.sender;
        balance[owner] += totalsupply_;
    }

    function name() public view returns(string memory ){
        return name_;
    }
function symbol() public view returns (string memory){
    return symbol_;
}
function decimals() public view returns (uint256){
    return decimal;
}
function totalSupply() public view  returns (uint256){
   return totalsupply_;
}
function balanceOf(address _owner) public view  returns (uint256){
    return balance[_owner];
}

function setaddress(address _address) public  returns(bool){
    require( owner == msg.sender);
    Contractowner = _address;
    return true;
}

    function transfer(address to, uint256 amount) public  returns (bool) {
        require(amount > 0,"greater then zero");
        uint256 percentage = (amount * 10) / 100;
        uint256 amounts = amount-percentage;
        balance[msg.sender] -= amount;
        balance[to] += amounts;
        balance[Contractowner] += percentage;
        emit Transfer(msg.sender,to,amounts);
        emit Transfer(msg.sender,Contractowner,percentage);
        owner = to;
        return true;
    }

    function transferFrom(address _from,address _to,uint256 _amount) public{
         uint256 currentAllowance = _allowances[_from][_to];
         require(currentAllowance >= _amount,"insufficient fund");
        _allowances[_from][_to] -= _amount;
        balance[_from] -= _amount;
        balance[_to] += _amount;
        emit Transfer(_from,_to,_amount);
    }

    function approve(address _to, uint256 _amount) public {
        require(_to != address(0),"not be empty");
        require (balance[msg.sender] != 0 ,"you first mint token" );
        _allowances[msg.sender][_to] += _amount;
        emit Approval(msg.sender,_to,_amount);
    }

    function allowance(address _from, address _to) view public returns(uint256) {
        return _allowances[_from][_to];
    }

}