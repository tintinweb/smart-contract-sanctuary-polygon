/**
 *Submitted for verification at polygonscan.com on 2022-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Ownership{
    event Transfer(address indexed from, address indexed to, uint256 value);
    mapping (address=>uint) private balance;

    string private name_;
    string private symbol_;
    uint256 private decimal = 18;
    uint private totalsupply_;
    address public owner;

    address private Contractowner;

    modifier onlyOwner(){
       require( owner == msg.sender);
        _;
    }

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

function setaddress(address _address) public onlyOwner returns(bool){
    Contractowner = _address;
    return true;
}

    function transfer(address to, uint256 amount) public onlyOwner returns (bool) {
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
}